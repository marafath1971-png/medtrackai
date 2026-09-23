const test = require('node:test');
const assert = require('node:assert/strict');

const {
    GRACE_MIN,
    doseTimeString,
    handledDoseKeys,
    isWithinAlertWindow,
    isDoseMissed,
    dedupMarkerId,
    profilesToScan,
} = require('../missed_dose_rules');

/**
 * `detectMissedDoses` is the server-side caregiver safety net. It used to read
 * `users/{uid}/medicines` and nothing else, so the dependent profiles the app
 * carefully scopes under `users/{uid}/dependents/{profileId}/...` were
 * invisible to it. For the "Dedicated Caregiver" persona — someone managing a
 * parent's or child's schedule, which is the whole reason the feature exists —
 * the passive watch silently covered nobody.
 *
 * These tests pin the rules that decide who gets scanned and which doses count
 * as missed. They fail closed by design: a false alert to a caregiver is worse
 * than no alert.
 */

const WED = 3; // 0=Sun..6=Sat, matching the client's weekday%7

test('the owner is always scanned, even with no dependents', () => {
    const scans = profilesToScan({ profile: { name: 'Ana' } });
    assert.equal(scans.length, 1);
    assert.equal(scans[0].profileId, null);
    assert.equal(scans[0].displayName, 'Ana');
});

test('each managed dependent is scanned alongside the owner', () => {
    const scans = profilesToScan({
        profile: {
            name: 'Ana',
            familyMembers: [
                { id: 'dep-1', name: 'Dad' },
                { id: 'dep-2', name: 'Mia' },
            ],
        },
    });

    assert.deepEqual(scans.map((s) => s.profileId), [null, 'dep-1', 'dep-2']);
});

test('an alert names the dependent, not the account holder', () => {
    // "Dad may have missed a dose" is the entire point — an alert that says
    // the account holder's name sends the caregiver to the wrong person.
    const scans = profilesToScan({
        profile: { name: 'Ana', familyMembers: [{ id: 'dep-1', name: 'Dad' }] },
    });

    assert.equal(scans[1].displayName, 'Dad');
});

test('the owner name comes from profile.name, where the client writes it', () => {
    // saveProfile nests the UserProfile under a `profile` key and nothing ever
    // sets a top-level `name`, so reading the top level alone meant every
    // alert said "Someone you care for".
    assert.equal(profilesToScan({ profile: { name: 'Ana' } })[0].displayName, 'Ana');

    // Older docs that kept a top-level name still resolve.
    assert.equal(profilesToScan({ name: 'Legacy' })[0].displayName, 'Legacy');

    // And a nameless account still produces a sendable alert.
    assert.equal(profilesToScan({})[0].displayName, 'Someone you care for');
});

test('a dependent with no id is skipped rather than scanned as the owner', () => {
    // A blank profileId would fall back to the owner's root collections and
    // re-alert on the owner's medicines under the dependent's name.
    const scans = profilesToScan({
        profile: { familyMembers: [{ name: 'Nameless' }, { id: '', name: 'Blank' }] },
    });

    assert.equal(scans.length, 1);
    assert.equal(scans[0].profileId, null);
});

test('a numeric dependent id is normalised to a string', () => {
    // Firestore document ids are strings; a raw number would build the wrong
    // collection path.
    const scans = profilesToScan({ profile: { familyMembers: [{ id: 7, name: 'Mia' }] } });
    assert.strictEqual(scans[1].profileId, '7');
});

test('the dedup marker separates the owner from a dependent', () => {
    // Medicine ids are assigned per profile, so an owner and a dependent can
    // genuinely both have id 1. A marker without the profile segment would let
    // whichever was scanned first suppress the other's alert all day.
    const base = { patientUid: 'u1', medId: 1, timeStr: '08:00', dayKey: '2026-09-22' };

    const ownerMarker = dedupMarkerId({ ...base, profileId: null });
    const depMarker = dedupMarkerId({ ...base, profileId: 'dep-1' });

    assert.notEqual(ownerMarker, depMarker);
    assert.match(ownerMarker, /_self_/);
});

test('a dose is missed only once it is past the grace window', () => {
    const schedule = { enabled: true, days: [WED], h: 8, m: 0 };
    const args = { schedule, localDow: WED, handled: new Set(), medId: 1 };

    // 08:00 scheduled, grace is 90min -> nothing before 09:30.
    assert.equal(isDoseMissed({ ...args, localMinutes: 8 * 60 }), false);
    assert.equal(isDoseMissed({ ...args, localMinutes: 8 * 60 + GRACE_MIN - 1 }), false);
    assert.equal(isDoseMissed({ ...args, localMinutes: 8 * 60 + GRACE_MIN }), true);
});

test('a taken or skipped dose never alerts', () => {
    const schedule = { enabled: true, days: [WED], h: 8, m: 0 };
    const args = { schedule, localDow: WED, localMinutes: 20 * 60, medId: 1 };

    assert.equal(isDoseMissed({ ...args, handled: new Set() }), true);
    assert.equal(isDoseMissed({ ...args, handled: handledDoseKeys([
        { medId: 1, time: '08:00', taken: true },
    ]) }), false);
    assert.equal(isDoseMissed({ ...args, handled: handledDoseKeys([
        { medId: 1, time: '08:00', skipped: true },
    ]) }), false);
});

test('a history entry that is neither taken nor skipped does not count as handled', () => {
    // A logged-but-unresolved entry must still be able to alert.
    const handled = handledDoseKeys([{ medId: 1, time: '08:00', taken: false, skipped: false }]);
    assert.equal(handled.size, 0);
});

test('a disabled or off-day schedule never alerts', () => {
    const args = { localDow: WED, localMinutes: 20 * 60, handled: new Set(), medId: 1 };

    assert.equal(isDoseMissed({
        ...args, schedule: { enabled: false, days: [WED], h: 8, m: 0 },
    }), false);
    assert.equal(isDoseMissed({
        ...args, schedule: { enabled: true, days: [WED + 1], h: 8, m: 0 },
    }), false);
});

test('malformed schedule data fails closed', () => {
    const args = { localDow: WED, localMinutes: 20 * 60, handled: new Set(), medId: 1 };

    assert.equal(isDoseMissed({ ...args, schedule: null }), false);
    assert.equal(isDoseMissed({ ...args, schedule: {} }), false);
    assert.equal(isDoseMissed({ ...args, schedule: { enabled: true, days: 'wed' } }), false);
});

test('dose times are zero-padded to match the client history keys', () => {
    // History keys are written client-side as "HH:MM"; "8:5" would never match.
    assert.equal(doseTimeString({ h: 8, m: 5 }), '08:05');
    assert.equal(doseTimeString({}), '00:00');
});

test('alerts are confined to local waking hours', () => {
    assert.equal(isWithinAlertWindow(6), false);  // too early
    assert.equal(isWithinAlertWindow(7), true);
    assert.equal(isWithinAlertWindow(22), true);
    assert.equal(isWithinAlertWindow(23), false); // too late
});
