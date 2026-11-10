import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/local_prefs_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/utils/repository_ext.dart';
import '../../core/utils/result.dart';
import '../../core/utils/logger.dart';
import '../../services/gemini_service.dart';

// ══════════════════════════════════════════════
// MEDICATION REPOSITORY — Offline-First
// Writes locally first (instant), then syncs to
// Firestore in the background when user is logged in.
// ══════════════════════════════════════════════

/// Background Firestore writes must never crash the offline-first flow, but
/// they must also never fail SILENTLY — for a medication app a lost sync is
/// a safety issue (blueprint §3.3). Local data stays authoritative and the
/// merge in [MedicationRepositoryImpl.getMedicines] re-pushes unsynced
/// records on the next load; this logs the failure so it is visible in
/// debug logs and Crashlytics breadcrumbs instead of vanishing.
void _logSyncError(Object e) => appLogger.w(
    '[Sync] Firestore write failed (local saved; will re-push on next merge): $e');

/// Reconciles the cloud and local taken-today maps.
///
/// Local wins on conflict because it is the only side that can hold an action
/// the other has not seen: a dose logged while offline exists nowhere else.
/// Taking the cloud map wholesale — as this used to — silently discarded that
/// dose, and the user watched a dose they had logged flip back to untaken.
///
/// Cloud-only keys are preserved so a dose taken on another device survives.
Map<String, bool> mergeTakenToday({
  required Map<String, bool> cloud,
  required Map<String, bool> local,
}) =>
    {...cloud, ...local};

/// True when [merged] holds anything the cloud is missing or disagrees with,
/// meaning the reconciliation still has to be written back. Without this the
/// local-only entries would be re-merged on every single load and never
/// actually persist.
bool takenTodayNeedsPush({
  required Map<String, bool> cloud,
  required Map<String, bool> merged,
}) =>
    merged.entries
        .any((e) => !cloud.containsKey(e.key) || cloud[e.key] != e.value);

/// Identity of a dose entry within a single day.
///
/// A scheduled dose is uniquely identified by which medicine it is, the slot
/// it belongs to and the clock time of that slot — the same `medId`/`time`
/// pairing the server-side missed-dose detector uses to decide what has been
/// handled. [label] is part of the key because a medicine can have two slots
/// at the same time (a morning and an evening label can collide once a user
/// edits a schedule), and because PRN entries carry their own label.
String doseEntryKey(DoseEntry e) => '${e.medId}|${e.time}|${e.label}';

/// True for an as-needed dose, which is appended by `logPrnDose` rather than
/// filled into a schedule slot.
///
/// These are the one genuinely repeatable kind of entry: taking two rescue
/// doses an hour apart produces two records that are both real. They are also
/// removable — `undoPrnDose` deletes one — so they cannot be reconciled by key
/// without either collapsing duplicates or resurrecting undone doses.
bool isPrnEntry(DoseEntry e) => e.label.startsWith('PRN-');

/// Reconciles one day's dose log from two devices.
///
/// The merge this replaces worked a whole day at a time: for any day the cloud
/// lacked, and unconditionally for *today*, the local day replaced the cloud
/// day wholesale. Both devices hold only a partial day, so that silently
/// destroyed doses — phone A logs the 08:00 dose, phone B logs the 20:00 one,
/// and whichever syncs last erases the other's, locally and in Firestore.
///
/// That is worse than it looks. This log is what adherence scores, streaks and
/// the stats screens are computed from, and `detectMissedDoses` reads the same
/// entries to decide which doses were handled — so a dose erased here reads as
/// never taken, and a caregiver gets alerted about a dose the patient
/// actually took.
///
/// Scheduled entries reconcile by [doseEntryKey]. On a conflict the *handled*
/// entry wins: marking a dose taken or skipped is a deliberate act, while an
/// untouched entry only records that nothing has happened yet. That direction
/// fails safe — wrongly keeping a dose costs a missed alert, wrongly dropping
/// one sends a caregiver a false alarm about medication.
///
/// PRN entries cannot be keyed (see [isPrnEntry]), so the side with more of
/// them for that medicine is taken as the more complete record.
List<DoseEntry> mergeDayEntries({
  required List<DoseEntry> cloud,
  required List<DoseEntry> local,
}) {
  final merged = <String, DoseEntry>{};

  for (final e in [...cloud, ...local].where((e) => !isPrnEntry(e))) {
    final key = doseEntryKey(e);
    final existing = merged[key];
    if (existing == null || (!_isHandled(existing) && _isHandled(e))) {
      merged[key] = e;
    }
  }

  // PRN doses are positional rather than keyed: take whichever side recorded
  // more for a given medicine, so an undo on one device is not undone by the
  // other's stale copy and two genuine rescue doses both survive.
  final byMed = <int, List<DoseEntry>>{};
  for (final side in [cloud, local]) {
    final prn = side.where(isPrnEntry);
    for (final group in _groupByMed(prn).entries) {
      final existing = byMed[group.key];
      if (existing == null || group.value.length > existing.length) {
        byMed[group.key] = group.value;
      }
    }
  }

  return [...merged.values, ...byMed.values.expand((e) => e)];
}

bool _isHandled(DoseEntry e) => e.taken || e.skipped;

/// Whether two days hold the same doses in the same handled state, so a
/// reconciliation that changed nothing does not trigger a pointless write.
/// Order-insensitive: the merge rebuilds the list and does not preserve it.
bool _sameEntries(List<DoseEntry> a, List<DoseEntry> b) {
  if (a.length != b.length) return false;
  String sig(DoseEntry e) => '${doseEntryKey(e)}|${e.taken}|${e.skipped}';
  final as = a.map(sig).toList()..sort();
  final bs = b.map(sig).toList()..sort();
  for (var i = 0; i < as.length; i++) {
    if (as[i] != bs[i]) return false;
  }
  return true;
}

Map<int, List<DoseEntry>> _groupByMed(Iterable<DoseEntry> entries) {
  final out = <int, List<DoseEntry>>{};
  for (final e in entries) {
    (out[e.medId] ??= []).add(e);
  }
  return out;
}

/// How long a deletion is remembered before the tombstone is dropped.
///
/// A tombstone has to outlive the longest realistic gap between a device
/// deleting a medicine and every other device coming online to learn about it.
/// 90 days covers a phone left in a drawer for a season; past that the record
/// is almost certainly gone from every device anyway, and keeping tombstones
/// forever would grow the key without bound.
const Duration kTombstoneRetention = Duration(days: 90);

/// The outcome of reconciling one profile's local and cloud medicine lists.
class MedicineMergeResult {
  /// What both sides should end up holding.
  final List<Medicine> merged;

  /// Local-only or locally-newer records the cloud has not got yet.
  final List<Medicine> toPush;

  /// Ids the cloud still carries that this device knows were deleted.
  final List<int> toDelete;

  const MedicineMergeResult({
    required this.merged,
    required this.toPush,
    required this.toDelete,
  });
}

/// Reconciles the cloud and local medicine lists.
///
/// The old merge was a union by id: cloud records, plus any local id the cloud
/// did not have. That is wrong in both directions, and for a medication app
/// both are safety issues rather than annoyances.
///
///  * **Deletions came back.** Deleting a medicine on phone A removed it from
///    the cloud, but phone B still had it locally, saw an id the cloud lacked,
///    and helpfully re-uploaded it — so it reappeared on phone A. A dose the
///    user deliberately stopped taking reappearing on their schedule is the
///    worst version of this bug.
///  * **Edits were silently reverted.** On an id collision the cloud copy won
///    unconditionally, so a dose edited offline on phone A was overwritten by
///    phone B's stale copy the next time A loaded.
///
/// The fix needs two things the model did not carry: [Medicine.updatedAt], so
/// the newer of two versions can be identified, and [tombstones], so "deleted"
/// is distinguishable from "not yet uploaded".
///
/// Conflicts resolve by last-write-wins on [Medicine.updatedAt]. A record with
/// no timestamp — written by a build before this existed — is treated as older
/// than any stamped record, so a fresh edit always beats a legacy copy. When
/// neither side has one the cloud wins, matching the old behaviour.
MedicineMergeResult mergeMedicines({
  required List<Medicine> cloud,
  required List<Medicine> local,
  required Map<int, DateTime> tombstones,
}) {
  final cloudById = {for (final m in cloud) m.id: m};
  final localById = {for (final m in local) m.id: m};

  final merged = <Medicine>[];
  final toPush = <Medicine>[];
  final toDelete = <int>[];

  for (final id in {...cloudById.keys, ...localById.keys}) {
    // A tombstone outranks both copies: this device watched the user delete
    // it, which is information neither list carries.
    if (tombstones.containsKey(id)) {
      if (cloudById.containsKey(id)) toDelete.add(id);
      continue;
    }

    final c = cloudById[id];
    final l = localById[id];

    if (c == null) {
      // Local-only and not deleted — genuinely not uploaded yet.
      merged.add(l!);
      toPush.add(l);
    } else if (l == null) {
      // Cloud-only — added on another device.
      merged.add(c);
    } else if (_isNewer(l.updatedAt, c.updatedAt)) {
      merged.add(l);
      toPush.add(l);
    } else {
      merged.add(c);
    }
  }

  return MedicineMergeResult(
      merged: merged, toPush: toPush, toDelete: toDelete);
}

/// Whether [local] is strictly newer than [remote], with a null timestamp
/// sorting older than any real one (and two nulls favouring the remote).
bool _isNewer(DateTime? local, DateTime? remote) {
  if (local == null) return false;
  if (remote == null) return true;
  return local.isAfter(remote);
}

/// Drops tombstones past [kTombstoneRetention] so the record cannot grow
/// without bound. [now] is injectable for tests.
Map<int, DateTime> pruneTombstones(Map<int, DateTime> tombstones,
    {DateTime? now}) {
  final cutoff = (now ?? DateTime.now()).subtract(kTombstoneRetention);
  return {
    for (final e in tombstones.entries)
      if (e.value.isAfter(cutoff)) e.key: e.value
  };
}

class MedicationRepositoryImpl implements IMedicationRepository {
  final LocalDataSource localDataSource;
  final FirestoreDataSource firestoreDataSource;
  final StorageService storageService;

  MedicationRepositoryImpl(
      this.localDataSource, this.firestoreDataSource, this.storageService);

  String? get _uid => AuthService.uid;
  bool get _hasAuth => _uid != null;

  String _key(String base, String? profileId) {
    if (profileId == null) return base;
    return 'p_${profileId}_$base';
  }

  // ── Deletion tombstones ────────────────────────────────────────────
  //
  // A deleted medicine leaves a record of the deletion behind, because
  // "absent locally" and "deleted" are otherwise indistinguishable: the merge
  // reads an id the cloud has and this device does not, and cannot tell
  // whether another device just added it or this device deleted it. Without
  // the tombstone it guessed "added" and re-downloaded a medicine the user
  // had deliberately removed.
  //
  // Stored unencrypted: an id and a timestamp are not health information, and
  // keeping them readable means a decryption failure cannot resurrect
  // medicines.

  Map<int, DateTime> _loadTombstones(String? profileId) {
    final raw = localDataSource.getJson(_key('medTombstones', profileId));
    if (raw is! Map) return {};
    final out = <int, DateTime>{};
    raw.forEach((k, v) {
      final id = int.tryParse('$k');
      final at = DateTime.tryParse('$v');
      if (id != null && at != null) out[id] = at.toUtc();
    });
    return out;
  }

  Future<void> _saveTombstones(
      Map<int, DateTime> tombstones, String? profileId) async {
    final pruned = pruneTombstones(tombstones);
    await localDataSource.setJson(
      _key('medTombstones', profileId),
      pruned.map((k, v) => MapEntry('$k', v.toUtc().toIso8601String())),
    );
  }

  // ── Medicines ──────────────────────────────────────────────────────
  @override
  Future<List<Medicine>> getMedicines({String? profileId}) async {
    final key = _key('meds', profileId);
    // 1. Load local meds
    final j = localDataSource.getJson(key, decrypt: true);
    final List<Medicine> localMeds =
        j == null ? [] : (j as List).map((m) => Medicine.fromJson(m)).toList();

    // 2. If authenticated, fetch cloud and merge
    if (_hasAuth) {
      try {
        final cloudMeds = await firestoreDataSource
            .getMedicines(_uid!, profileId: profileId)
            .withHardenedTimeout(taskName: 'getMedicines');

        // Reconcile by id, resolving conflicts on updatedAt and honouring any
        // deletion this device has recorded. See [mergeMedicines].
        final tombstones = _loadTombstones(profileId);
        final result = mergeMedicines(
          cloud: cloudMeds,
          local: localMeds,
          tombstones: tombstones,
        );

        for (final m in result.toPush) {
          firestoreDataSource
              .saveMedicine(_uid!, m, profileId: profileId)
              .withHardenedTimeout(taskName: 'saveMedicine')
              .catchError(_logSyncError);
        }

        // Apply deletions the cloud has not caught up with — either this
        // device deleted while offline, or another device has not pushed yet.
        for (final id in result.toDelete) {
          firestoreDataSource
              .deleteMedicine(_uid!, id, profileId: profileId)
              .catchError(_logSyncError);
        }

        // Unconditional: an empty merged list is a real state (the user
        // deleted their last medicine), and skipping the write when it is
        // empty — as this used to — left the deleted record sitting in local
        // storage to be resurrected on the next load.
        await localDataSource.setJson(
            key, result.merged.map((m) => m.toJson()).toList(),
            encrypt: true);

        // Prune expired tombstones opportunistically, on the one path that
        // already touches them.
        await _saveTombstones(tombstones, profileId);

        return result.merged;
      } catch (e) {
        // Falling back to local is correct — the user keeps working offline.
        // Logging it is not optional though: a sync that keeps failing while
        // the device reports itself online (expired token, tightened Firestore
        // rules, quota) is indistinguishable from working normally, and the
        // user's medicines quietly stop reaching the cloud.
        appLogger.w('[MedRepo] Cloud medicine fetch failed, using local: $e');
      }
    }

    return localMeds;
  }

  @override
  Future<void> addMedicine(Medicine medicine, {String? profileId}) async {
    final meds = await getMedicines(profileId: profileId);
    final key = _key('meds', profileId);

    // Stamp on the way in. The constructors leave updatedAt null (a scan or a
    // manual add has no reason to know about sync), but an unstamped record
    // loses every conflict, so a medicine added here and edited on another
    // device would silently revert to whatever that device holds.
    final med = medicine.updatedAt == null
        ? medicine.copyWith(updatedAt: DateTime.now().toUtc())
        : medicine;

    meds.add(med);
    await localDataSource.setJson(key, meds.map((m) => m.toJson()).toList(),
        encrypt: true);

    // Adding an id back clears any tombstone for it. Ids are epoch-millis so a
    // genuine collision is implausible, but a restored backup or an undo can
    // reintroduce one — and a surviving tombstone would have the next merge
    // delete the medicine again the moment it synced.
    final tombstones = _loadTombstones(profileId);
    if (tombstones.remove(med.id) != null) {
      await _saveTombstones(tombstones, profileId);
    }

    if (_hasAuth) {
      firestoreDataSource
          .saveMedicine(_uid!, med, profileId: profileId)
          .withHardenedTimeout(taskName: 'saveMedicine')
          .catchError(_logSyncError);
    }
  }

  @override
  Future<void> updateMedicine(Medicine medicine, {String? profileId}) async {
    final meds = await getMedicines(profileId: profileId);
    final key = _key('meds', profileId);
    final idx = meds.indexWhere((m) => m.id == medicine.id);
    if (idx != -1) {
      // An update is by definition a write, so it always advances the clock —
      // this is what lets last-write-wins pick it over a stale cloud copy.
      // Most callers already went through copyWith (which stamps), but not
      // all, and a re-stamp here is harmless.
      final med = medicine.copyWith(updatedAt: DateTime.now().toUtc());

      meds[idx] = med;
      await localDataSource.setJson(key, meds.map((m) => m.toJson()).toList(),
          encrypt: true);
      if (_hasAuth) {
        firestoreDataSource
            .saveMedicine(_uid!, med, profileId: profileId)
            .withHardenedTimeout(taskName: 'updateMedicine')
            .catchError(_logSyncError);
      }
    }
  }

  @override
  Future<void> deleteMedicine(int id, {String? profileId}) async {
    final key = _key('meds', profileId);

    // Read local directly rather than via getMedicines(): that would round
    // trip to the cloud and re-push local-only records on the way to deleting
    // one of them, and it would fail outright while offline — precisely when
    // the tombstone matters most.
    final meds = _loadLocalMeds(profileId)..removeWhere((m) => m.id == id);
    await localDataSource.setJson(key, meds.map((m) => m.toJson()).toList(),
        encrypt: true);

    // Record the deletion BEFORE attempting the remote one. If the Firestore
    // call fails — offline, or the app is killed mid-write — the tombstone is
    // what makes the next successful merge finish the job. Writing it only on
    // success would lose exactly the deletions that need replaying.
    final tombstones = _loadTombstones(profileId)
      ..[id] = DateTime.now().toUtc();
    await _saveTombstones(tombstones, profileId);

    if (_hasAuth) {
      firestoreDataSource
          .deleteMedicine(_uid!, id, profileId: profileId)
          .catchError(_logSyncError);
    }
  }

  // ── History ────────────────────────────────────────────────────────
  @override
  Future<Map<String, List<DoseEntry>>> getHistory({String? profileId}) async {
    final Map<String, List<DoseEntry>> local = _loadLocalHistory(profileId);

    if (_hasAuth) {
      try {
        final cloudHistory = await firestoreDataSource
            .getRecentHistory(_uid!, days: 30, profileId: profileId)
            .withHardenedTimeout(taskName: 'getHistory');
        final merged = <String, List<DoseEntry>>{...cloudHistory};

        // Reconcile per dose rather than per day. Replacing a whole day — as
        // this used to, for every day the cloud lacked and unconditionally for
        // today — discarded the doses the other device had logged, because
        // each side only ever holds part of the day. See [mergeDayEntries].
        for (final entry in local.entries) {
          final cloudDay = cloudHistory[entry.key] ?? const <DoseEntry>[];
          final day = mergeDayEntries(cloud: cloudDay, local: entry.value);
          merged[entry.key] = day;

          // Only push when the reconciliation actually adds something the
          // cloud has not got; otherwise every load rewrites every day.
          if (day.length != cloudDay.length || !_sameEntries(day, cloudDay)) {
            firestoreDataSource
                .saveDayHistory(_uid!, entry.key, day, profileId: profileId)
                .catchError(_logSyncError);
          }
        }

        await localDataSource.setJson(
          _key('history', profileId),
          merged.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
          encrypt: true,
        );
        return merged;
      } catch (e) {
        appLogger.w('[MedRepo] Cloud history fetch failed, using local: $e');
      }
    }
    return local;
  }

  Map<String, List<DoseEntry>> _loadLocalHistory(String? profileId) {
    final j =
        localDataSource.getJson(_key('history', profileId), decrypt: true);
    if (j == null) return {};
    return (j as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => DoseEntry.fromJson(e)).toList()),
    );
  }

  @override
  Future<void> saveHistory(Map<String, List<DoseEntry>> history,
      {String? onlyDateKey, String? profileId}) async {
    await localDataSource.setJson(
      _key('history', profileId),
      history.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      encrypt: true,
    );
    if (_hasAuth) {
      if (onlyDateKey != null) {
        final dayEntries = history[onlyDateKey] ?? [];
        firestoreDataSource
            .saveDayHistory(_uid!, onlyDateKey, dayEntries,
                profileId: profileId)
            .catchError(_logSyncError);
      } else {
        for (final entry in history.entries) {
          firestoreDataSource
              .saveDayHistory(_uid!, entry.key, entry.value,
                  profileId: profileId)
              .catchError(_logSyncError);
        }
      }
    }
  }

  // ── Taken Today ────────────────────────────────────────────────────
  @override
  Future<Map<String, bool>> getTakenToday({String? profileId}) async {
    final key = _key('takenToday', profileId);
    final localJson = localDataSource.getJson(key, decrypt: true);
    final Map<String, bool> local =
        localJson == null ? {} : Map<String, bool>.from(localJson);

    if (_hasAuth) {
      try {
        final cloud = await firestoreDataSource
            .getTakenToday(_uid!, profileId: profileId)
            .withHardenedTimeout(taskName: 'getTakenToday');
        if (cloud.isNotEmpty) {
          final merged = mergeTakenToday(cloud: cloud, local: local);
          if (takenTodayNeedsPush(cloud: cloud, merged: merged)) {
            firestoreDataSource
                .saveTakenToday(_uid!, merged, profileId: profileId)
                .catchError(_logSyncError);
          }

          await localDataSource.setJson(key, merged, encrypt: true);
          return merged;
        }

        // Cloud is empty but local is not: this is a fresh cloud record, so
        // seed it instead of leaving the local state unsynced forever.
        if (local.isNotEmpty) {
          firestoreDataSource
              .saveTakenToday(_uid!, local, profileId: profileId)
              .catchError(_logSyncError);
        }
      } catch (e) {
        // Fallback to local on terminal timeout/error
        appLogger.w('[MedRepo] takenToday fetch failed: $e');
      }
    }
    return local;
  }

  @override
  Future<void> saveTakenToday(Map<String, bool> takenToday,
      {String? profileId}) async {
    final key = _key('takenToday', profileId);
    await localDataSource.setJson(key, takenToday, encrypt: true);
    if (_hasAuth) {
      firestoreDataSource
          .saveTakenToday(_uid!, takenToday, profileId: profileId)
          .catchError(_logSyncError);
    }
  }

  // ── Offline-to-Cloud Sync ──────────────────────────────────────────
  /// Upload all local data to Firestore. Called once after first sign-in
  /// when Firestore has no data yet.
  Future<void> syncToCloud() async {
    if (!_hasAuth) return;
    try {
      // Medicines
      final localMeds = _loadLocalMeds();
      for (final med in localMeds) {
        firestoreDataSource.saveMedicine(_uid!, med).catchError(_logSyncError);
      }
      // History
      final localHistory = _loadLocalHistory(null);
      for (final entry in localHistory.entries) {
        firestoreDataSource
            .saveDayHistory(_uid!, entry.key, entry.value)
            .catchError(_logSyncError);
      }
      // TakenToday
      final tt = localDataSource.getJson('takenToday');
      if (tt != null) {
        firestoreDataSource
            .saveTakenToday(_uid!, Map<String, bool>.from(tt))
            .catchError(_logSyncError);
      }
    } catch (e) {
      appLogger.w('[MedRepo] Local→cloud migration failed: $e');
    }
  }

  /// Reads this profile's medicines from local storage only.
  ///
  /// `decrypt: true` matters: [getMedicines] writes this key encrypted, so
  /// reading it without decrypting yields null and silently reports an empty
  /// library.
  List<Medicine> _loadLocalMeds([String? profileId]) {
    final j = localDataSource.getJson(_key('meds', profileId), decrypt: true);
    if (j == null) return [];
    return (j as List).map((m) => Medicine.fromJson(m)).toList();
  }

  @override
  Future<String?> uploadMedicineImage(File imageFile) async {
    if (!_hasAuth) {
      return await storageService.saveLocalImage(imageFile);
    }
    return await storageService.uploadMedicineImage(_uid!, imageFile);
  }

  @override
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) async {
    return await GeminiService.analyzeMedicineSafety(m);
  }

  @override
  Future<SharedPreferences> getPrefs() async {
    return localDataSource.prefs;
  }
}
