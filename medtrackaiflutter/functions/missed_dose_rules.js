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
    DAY_START_HOUR,
    DAY_END_HOUR,
    doseTimeString,
    handledDoseKeys,
    isWithinAlertWindow,
    isDoseMissed,
    dedupMarkerId,
    profilesToScan,
};
