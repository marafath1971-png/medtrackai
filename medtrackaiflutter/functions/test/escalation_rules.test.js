const test = require('node:test');
const assert = require('node:assert/strict');

const {
    DEFAULT_ALERT_DELAY_MIN,
    MAX_ALERT_DELAY_MIN,
    alertDelayOf,
    resolveCaregivers,
    minutesOverdue,
    isDoseOpen,
    caregiversDue,
} = require('../missed_dose_rules');

/**
 * The caregiver escalation chain. Two things these pin that were broken:
 *
 * 1. The roster is keyed by a numeric cgId. The server used to read the doc id
 *    as the caregiver's uid, looked up `users/"12345"`, found no push token,
 *    and alerted nobody — for every caregiver who joined through the app.
 * 2. Each caregiver's chosen delay ("Notified after 15 min…", shown in the
 *    app) was ignored in favour of a fixed 90 minutes.
 */

const WED = 3;
const grants = (...uids) => new Set(uids);

test('an app-joined caregiver resolves through joinedCaregiverUid, not the numeric doc id', () => {
    const cgs = resolveCaregivers(
        [{ id: '123456', data: { status: 'active', joinedCaregiverUid: 'uid-mom', alertDelay: 15 } }],
        grants('uid-mom'),
    );
    assert.deepEqual(cgs.map((c) => c.uid), ['uid-mom']);
});

test('a numeric doc id with no joined uid is never treated as a uid', () => {
    const cgs = resolveCaregivers(
        [{ id: '123456', data: { status: 'active' } }],
        grants('123456'),
    );
    assert.equal(cgs.length, 0);
});

test('a uid-keyed roster slot (verifyInvite path) still resolves', () => {
    const cgs = resolveCaregivers(
        [{ id: 'uid-dad', data: { status: 'active' } }],
        grants('uid-dad'),
    );
    assert.deepEqual(cgs.map((c) => c.uid), ['uid-dad']);
});

test('a caregiver without a live access grant is never alerted', () => {
    // Revoked access must end the alerts too — otherwise a removed caregiver
    // keeps learning about someone's medication.
    const cgs = resolveCaregivers(
        [{ id: '1', data: { status: 'active', joinedCaregiverUid: 'uid-ex' } }],
        grants(),
    );
    assert.equal(cgs.length, 0);
});

test('pending caregivers are skipped', () => {
    const cgs = resolveCaregivers(
        [{ id: '1', data: { status: 'pending', joinedCaregiverUid: 'uid-a' } }],
        grants('uid-a'),
    );
    assert.equal(cgs.length, 0);
});

test('the chain is ordered quickest-first, and duplicates keep the quicker delay', () => {
    const cgs = resolveCaregivers(
        [
            { id: '1', data: { status: 'active', joinedCaregiverUid: 'b', alertDelay: 60 } },
            { id: '2', data: { status: 'active', joinedCaregiverUid: 'a', alertDelay: 15 } },
            { id: '3', data: { status: 'active', joinedCaregiverUid: 'b', alertDelay: 30 } },
        ],
        grants('a', 'b'),
    );
    assert.deepEqual(cgs.map((c) => [c.uid, c.delayMin]), [['a', 15], ['b', 30]]);
});

test('alert delays default and clamp', () => {
    assert.equal(alertDelayOf({}), DEFAULT_ALERT_DELAY_MIN);
    assert.equal(alertDelayOf({ alertDelay: 'soon' }), DEFAULT_ALERT_DELAY_MIN);
    assert.equal(alertDelayOf({ alertDelay: -5 }), 0);
    assert.equal(alertDelayOf({ alertDelay: 10000 }), MAX_ALERT_DELAY_MIN);
    assert.equal(alertDelayOf({ alertDelay: 0 }), 0); // "Now" is a real choice
});

const chain = [
    { uid: 'mom', delayMin: 15 },
    { uid: 'bro', delayMin: 60 },
];

test('only caregivers whose delay has elapsed are due', () => {
    assert.deepEqual(
        caregiversDue({ caregivers: chain, overdueMin: 20, alreadyAlerted: new Set(), acknowledged: false })
            .map((c) => c.uid),
        ['mom'],
    );
});

test('the backup is reached later, and the first caregiver is not re-alerted', () => {
    assert.deepEqual(
        caregiversDue({ caregivers: chain, overdueMin: 75, alreadyAlerted: new Set(['mom']), acknowledged: false })
            .map((c) => c.uid),
        ['bro'],
    );
});

test('an acknowledgment stops the chain', () => {
    assert.deepEqual(
        caregiversDue({ caregivers: chain, overdueMin: 75, alreadyAlerted: new Set(['mom']), acknowledged: true }),
        [],
    );
});

test('a dose that is not yet due alerts nobody', () => {
    assert.deepEqual(
        caregiversDue({ caregivers: chain, overdueMin: -10, alreadyAlerted: new Set(), acknowledged: false }),
        [],
    );
});

test('minutesOverdue measures from the scheduled local time', () => {
    assert.equal(minutesOverdue({ h: 8, m: 30 }, 9 * 60), 30);
    assert.equal(minutesOverdue({ h: 8, m: 30 }, 8 * 60), -30);
});

test('a dose is open only if scheduled today and not taken or skipped', () => {
    const s = { enabled: true, days: [WED], h: 8, m: 0 };
    assert.equal(isDoseOpen({ schedule: s, localDow: WED, handled: new Set(), medId: 7 }), true);
    assert.equal(isDoseOpen({ schedule: s, localDow: WED, handled: new Set(['7-08:00']), medId: 7 }), false);
    assert.equal(isDoseOpen({ schedule: s, localDow: 4, handled: new Set(), medId: 7 }), false);
    assert.equal(isDoseOpen({ schedule: { ...s, enabled: false }, localDow: WED, handled: new Set(), medId: 7 }), false);
});
