/**
 * Pure scheduling rules for the passive missed-dose detector.
 *
 * These are split out of index.js so they can be exercised without Firestore
 * credentials: index.js calls admin.initializeApp() at import time, so simply
 * requiring it in a test needs a live service account. Everything here is a
 * plain function over plain data — no admin SDK, no network.
 *
 * Safety-first: a false "missed dose" push to a caregiver is worse than none,
 * so every predicate fails closed on malformed input.
 */

const GRACE_MIN = 90;         // minutes past scheduled time before we alert
const DAY_START_HOUR = 7;     // don't alert before local 07:00
const DAY_END_HOUR = 23;      // don't alert after local 23:00

/** Two-digit "HH:MM" for a schedule entry, matching the client's history keys. */
function doseTimeString(s) {
    return `${String((s && s.h) || 0).padStart(2, '0')}:${String((s && s.m) || 0).padStart(2, '0')}`;
}

/** The set of "medId-HH:MM" doses the patient already took or skipped today. */
function handledDoseKeys(entries) {
    return new Set(
        (entries || [])
            .filter((e) => e && (e.taken === true || e.skipped === true))
            .map((e) => `${e.medId}-${e.time}`)
    );
}

/** Whether local time sits inside the waking window we're willing to push in. */
function isWithinAlertWindow(localHour) {
    return localHour >= DAY_START_HOUR && localHour < DAY_END_HOUR;
}

/**
 * Whether one schedule entry is an overdue, unhandled dose right now.
 *
 * `localDow` is 0=Sun..6=Sat, matching the client's weekday%7 convention.
 */
function isDoseMissed({ schedule, localDow, localMinutes, handled, medId }) {
    if (!schedule || schedule.enabled !== true) return false;
    if (!Array.isArray(schedule.days) || !schedule.days.includes(localDow)) return false;

    const schedMinutes = (schedule.h || 0) * 60 + (schedule.m || 0);
    if (localMinutes < schedMinutes + GRACE_MIN) return false; // not overdue yet

    return !handled.has(`${medId}-${doseTimeString(schedule)}`);
}

/**
 * Dedup marker id for one patient/profile/med/dose/day.
 *
 * The profile segment is load-bearing: medicine ids are assigned per profile,
 * so an owner and a dependent can genuinely share id 1. Without the segment
 * the first one scanned would write a marker that suppressed the other's
 * alert for the rest of the day.
 */
function dedupMarkerId({ patientUid, profileId, medId, timeStr, dayKey }) {
    return `${patientUid}_${profileId || 'self'}_${medId}_${timeStr}_${dayKey}`;
}

// ── Escalation ────────────────────────────────────────────────────────
//
// Each caregiver picks how long after a missed dose they want to hear about
// it ("Now", 15 min, 30 min, 1 hr in the add-caregiver flow). That choice is
// the escalation chain: the quickest caregiver hears first, and each slower
// one is only reached if the dose is still unhandled and nobody has said
// they're on it by the time their own delay elapses.

const DEFAULT_ALERT_DELAY_MIN = 30;
const MAX_ALERT_DELAY_MIN = 240;

/** A caregiver's chosen delay, clamped to a sane range. */
function alertDelayOf(entry) {
    const raw = entry ? entry.alertDelay : undefined;
    if (typeof raw !== 'number' || !Number.isFinite(raw)) return DEFAULT_ALERT_DELAY_MIN;
    return Math.min(MAX_ALERT_DELAY_MIN, Math.max(0, Math.round(raw)));
}

/**
 * The caregivers who may be alerted for an account, soonest first.
 *
 * `roster` is `users/{patient}/caregivers`, as `[{ id, data }]`. The app keys
 * that roster by a numeric cgId and records the caregiver's account in
 * `joinedCaregiverUid`; only the server-side verifyInvite path keyed it by uid.
 * Treating every doc id as a uid — which this code used to do — looked up
 * `users/"12345"`, found no push token, and silently alerted nobody.
 *
 * `accessUids` is the set of uids holding an active `caregiverAccess` grant.
 * A roster slot without a grant is a revoked or never-completed caregiver,
 * and telling them about someone's medication would be a privacy leak, so
 * the grant is required — failing closed.
 */
function resolveCaregivers(roster, accessUids) {
    const byUid = new Map();
    for (const doc of roster || []) {
        const data = (doc && doc.data) || {};
        if (data.status !== 'active') continue;
        const joined = typeof data.joinedCaregiverUid === 'string' ? data.joinedCaregiverUid : '';
        const idIsUid = typeof doc.id === 'string' && doc.id !== '' && !/^\d+$/.test(doc.id);
        const uid = joined || (idIsUid ? doc.id : '');
        if (!uid) continue;
        if (!accessUids || !accessUids.has(uid)) continue;

        const delayMin = alertDelayOf(data);
        const prev = byUid.get(uid);
        // Two slots for one person keep the quicker delay.
        if (!prev || delayMin < prev.delayMin) {
            byUid.set(uid, { uid, delayMin, name: data.name || 'A caregiver' });
        }
    }
    return [...byUid.values()].sort((a, b) => a.delayMin - b.delayMin);
}

/** Minutes a scheduled dose is overdue right now; negative if not yet due. */
function minutesOverdue(schedule, localMinutes) {
    const schedMinutes = ((schedule && schedule.h) || 0) * 60 + ((schedule && schedule.m) || 0);
    return localMinutes - schedMinutes;
}

/**
 * Whether one schedule entry is due today and still unhandled, regardless of
 * how late it is. The per-caregiver delay decides who hears about it.
 */
function isDoseOpen({ schedule, localDow, handled, medId }) {
    if (!schedule || schedule.enabled !== true) return false;
    if (!Array.isArray(schedule.days) || !schedule.days.includes(localDow)) return false;
    return !handled.has(`${medId}-${doseTimeString(schedule)}`);
}

/**
 * Which caregivers should be alerted now for one open dose.
 *
 * Nobody once a caregiver has acknowledged it — the chain exists to find
 * someone, and it has. Otherwise every caregiver whose delay has elapsed and
 * who has not already been alerted for this dose.
 */
function caregiversDue({ caregivers, overdueMin, alreadyAlerted, acknowledged }) {
    if (acknowledged) return [];
    if (typeof overdueMin !== 'number' || overdueMin < 0) return [];
    const done = alreadyAlerted || new Set();
    return (caregivers || []).filter((cg) => cg.delayMin <= overdueMin && !done.has(cg.uid));
}

/**
 * Every profile on an account that should be scanned: the owner, then each
 * managed dependent.
 *
 * The dependent roster is `profile.familyMembers`, NOT a listing of the
 * `dependents` subcollection — those child docs are created lazily by
 * saveTakenToday, so a dependent whose doses have never been logged has
 * medicines but no parent doc. Listing the collection would silently skip
 * exactly the person most likely to be missing doses.
 */
function profilesToScan(patientData) {
    const data = patientData || {};
    const profileData = data.profile || {};
    const ownerName = profileData.name || data.name || 'Someone you care for';

    const scans = [{ profileId: null, displayName: ownerName }];

    for (const m of profileData.familyMembers || []) {
        if (!m || !m.id) continue;
        scans.push({
            profileId: String(m.id),
            // Name the dependent, not the account holder — "Dad may have
            // missed a dose" is the whole point of the alert.
            displayName: m.name || ownerName,
        });
    }

    return scans;
}

module.exports = {
    GRACE_MIN,
    DEFAULT_ALERT_DELAY_MIN,
    MAX_ALERT_DELAY_MIN,
    alertDelayOf,
    resolveCaregivers,
    minutesOverdue,
    isDoseOpen,
    caregiversDue,
    DAY_START_HOUR,
    DAY_END_HOUR,
    doseTimeString,
    handledDoseKeys,
    isWithinAlertWindow,
    isDoseMissed,
    dedupMarkerId,
    profilesToScan,
};
