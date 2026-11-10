import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/step_math.dart';
import '../../data/datasources/steps_cloud.dart';
import '../../domain/entities/step_day.dart';
import '../../services/native_widget_service.dart';
import '../../services/steps_service.dart';

/// Daily steps, the goal, the history behind the charts, and the walking
/// partner.
///
/// Deliberately not relayed through AppState's listeners: a step refresh
/// would otherwise rebuild every screen in the app. Widgets that show steps
/// listen to this controller directly.
class StepsController extends ChangeNotifier {
  static const _kEnabled = 'steps_enabled';
  static const _kGoal = 'steps_goal';
  static const _kDays = 'steps_days_v1';

  /// Days of history kept on the device and read from the partner.
  static const historyDays = 30;

  /// Recent days are re-read on every refresh because a watch can deliver
  /// yesterday's steps late; older days are read once and kept.
  static const _volatileDays = 2;

  static const _refreshThrottle = Duration(seconds: 30);
  static const cheerCooldown = Duration(seconds: 20);

  final SharedPreferences _prefs;
  final StepSource _source;
  final StepsCloud _cloud;
  final DateTime Function() _now;

  /// Called when the partner sends encouragement; AppState turns it into a
  /// toast.
  void Function(StepCheerKind kind, String partnerName)? onCheer;

  StepsController({
    required SharedPreferences prefs,
    StepSource? source,
    StepsCloud? cloud,
    DateTime Function()? now,
  })  : _prefs = prefs,
        _source = source ?? HealthStepSource(),
        _cloud = cloud ?? FirestoreStepsCloud(),
        _now = now ?? DateTime.now {
    _enabled = _prefs.getBool(_kEnabled) ?? false;
    _goal = StepMath.clampGoal(_prefs.getInt(_kGoal) ?? StepMath.defaultGoal);
    _loadCache();
  }

  bool _enabled = false;
  StepAccess _access = StepAccess.unknown;
  int _goal = StepMath.defaultGoal;
  bool _refreshing = false;
  bool _disposed = false;
  DateTime? _lastRefresh;
  final Map<String, StepDay> _days = {};

  String _name = '';
  String _avatar = '';
  double? _heightCm;
  double? _weightKg;

  StepPartner? _partner;
  Map<String, StepDay> _partnerDays = {};
  StreamSubscription<List<StepPartner>>? _partnersSub;
  StreamSubscription<Map<String, StepDay>>? _partnerDaysSub;
  StreamSubscription<List<StepCheer>>? _cheersSub;
  final Set<String> _seenCheers = {};
  DateTime? _lastCheerSent;
  String? _lastSaved;

  // ── Read side ──────────────────────────────────────────────────────────

  /// The user has turned step counting on. Says nothing about whether the
  /// phone is still granting access — see [access].
  bool get enabled => _enabled;
  StepAccess get access => _access;
  bool get refreshing => _refreshing;
  int get goal => _goal;
  bool get signedIn => _cloud.uid != null;

  DateTime get _today => StepMath.startOfDay(_now());
  String get todayKey => StepMath.dateKey(_today);

  StepDay get today =>
      _days[todayKey] ??
      StepDay(dateKey: todayKey, steps: 0, goal: _goal, name: _name);

  Map<String, StepDay> get days => Map.unmodifiable(_days);

  /// The last seven days, oldest first, with empty days filled in so a chart
  /// always has seven bars.
  List<StepDay> get week => _fill(_days, 7);

  List<StepDay> _fill(Map<String, StepDay> source, int count) => [
        for (final d in StepMath.lastDays(_today, count))
          source[StepMath.dateKey(d)] ??
              StepDay(dateKey: StepMath.dateKey(d), steps: 0, goal: _goal),
      ];

  int get streak => StepMath.goalStreak(_days, _today);
  int get weekAverage => StepMath.averageSteps(week);
  StepDay? get bestDay => StepMath.bestDay(_days.values);
  double get distanceKm =>
      StepMath.distanceKm(today.steps, heightCm: _heightCm);
  int get kcal => StepMath.kcal(today.steps, weightKg: _weightKg);
  int get activeHours => StepMath.activeHours(today.hourly);
  int? get peakHour => StepMath.peakHour(today.hourly);

  Set<StepBadge> get badges =>
      StepMath.badges(mine: _days, partner: _partnerDays, today: _today);

  // ── Partner ────────────────────────────────────────────────────────────

  StepPartner? get partner {
    final p = _partner;
    if (p == null) return null;
    // The grant written at pairing only carries a name in one direction; the
    // partner's own day documents carry it in both.
    final latest = _latestPartnerDay;
    return p.withFallback(
        name: latest?.name ?? '', avatar: latest?.avatar ?? '');
  }

  StepDay? get _latestPartnerDay {
    if (_partnerDays.isEmpty) return null;
    final keys = _partnerDays.keys.toList()..sort();
    return _partnerDays[keys.last];
  }

  /// The partner's steps for today, or null if they have not synced today.
  StepDay? get partnerToday => _partnerDays[todayKey];
  List<StepDay> get partnerWeek => _fill(_partnerDays, 7);

  int get togetherSteps => today.steps + (partnerToday?.steps ?? 0);

  /// Both goals added up. Uses the partner's most recent goal when they have
  /// not synced today, so the shared target does not halve overnight.
  int get togetherGoal =>
      today.goal + (partnerToday?.goal ?? _latestPartnerDay?.goal ?? 0);

  int get duoStreak => StepMath.duoStreak(_days, _partnerDays, _today);

  ({int mine, int partner}) get weekWins =>
      StepMath.weekWins(_days, _partnerDays, _today);

  bool get canCheer {
    final last = _lastCheerSent;
    return last == null || _now().difference(last) >= cheerCooldown;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────

  /// Binds the signed-in user's identity and starts the partner streams.
  /// Safe to call again whenever the profile changes.
  void attachAccount({
    required String name,
    required String avatar,
    String height = '',
    String weight = '',
  }) {
    _name = name;
    _avatar = avatar;
    _heightCm = StepMath.parseHeightCm(height);
    _weightKg = StepMath.parseWeightKg(weight);
    _listenToPartners();
    _listenToCheers();
    if (_enabled) refresh(force: true);
  }

  /// Sign-out: drops everything that belongs to the account. The step cache
  /// goes too — it is the previous user's health data.
  Future<void> detachAccount() async {
    await _partnersSub?.cancel();
    await _partnerDaysSub?.cancel();
    await _cheersSub?.cancel();
    _partnersSub = _partnerDaysSub = null;
    _cheersSub = null;
    _partner = null;
    _partnerDays = {};
    _seenCheers.clear();
    _days.clear();
    _lastSaved = null;
    _lastRefresh = null;
    _name = _avatar = '';
    await _prefs.remove(_kDays);
    _syncWidget();
    _notify();
  }

  /// Asks the phone for step access and turns the feature on if it agrees.
  Future<StepAccess> enable() async {
    final result = await _source.request();
    _access = result;
    if (result == StepAccess.granted) {
      _enabled = true;
      await _prefs.setBool(_kEnabled, true);
      _notify();
      await refresh(force: true);
    } else {
      _notify();
    }
    return result;
  }

  Future<void> disable() async {
    _enabled = false;
    await _prefs.setBool(_kEnabled, false);
    _notify();
  }

  Future<void> openInstall() => _source.openInstall();

  Future<void> setGoal(int goal) async {
    final next = StepMath.clampGoal(goal);
    if (next == _goal) return;
    _goal = next;
    await _prefs.setInt(_kGoal, next);
    final t = _days[todayKey];
    if (t != null) _days[todayKey] = t.copyWith(goal: next);
    _saveCache();
    _notify();
    _syncWidget();
    await _pushToday();
  }

  /// Re-reads steps from the phone. Cheap to call often: it is throttled
  /// unless [force] is set.
  Future<void> refresh({bool force = false}) {
    if (!_enabled) return Future.value();
    // A caller that arrives mid-read waits for that read rather than getting
    // an instant return and stale numbers.
    final running = _inFlight;
    if (running != null) return running;
    final last = _lastRefresh;
    if (!force && last != null && _now().difference(last) < _refreshThrottle) {
      return Future.value();
    }
    return _inFlight = _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void>? _inFlight;

  Future<void> _refresh() async {
    final now = _now();
    _refreshing = true;
    _notify();
    try {
      final status = await _source.status();
      // `unknown` is what iOS always reports for read access, so only a
      // definite "no" stops the read.
      if (status == StepAccess.unavailable ||
          status == StepAccess.needsInstall) {
        _access = status;
        return;
      }
      _access = StepAccess.granted;

      final today = StepMath.startOfDay(now);
      final total = await _source.stepsBetween(today, now);
      if (total == null) return;

      final hourly = await _readHourly(today, now);
      _days[StepMath.dateKey(today)] = StepDay(
        dateKey: StepMath.dateKey(today),
        steps: total,
        goal: _goal,
        hourly: hourly,
        name: _name,
        avatar: _avatar,
      );

      await _readHistory(today);
      _lastRefresh = now;
      _prune(today);
      _saveCache();
      _syncWidget();
      await _pushToday();
    } catch (e) {
      appLogger.w('[Steps] refresh failed: $e');
    } finally {
      _refreshing = false;
      _notify();
    }
  }

  Future<List<int>> _readHourly(DateTime dayStart, DateTime now) async {
    final reads = <Future<int?>>[];
    for (var h = 0; h <= now.hour; h++) {
      final start = dayStart.add(Duration(hours: h));
      final end = h == now.hour ? now : dayStart.add(Duration(hours: h + 1));
      reads.add(_source.stepsBetween(start, end));
    }
    final values = await Future.wait(reads);
    return [
      for (var h = 0; h < 24; h++) h < values.length ? (values[h] ?? 0) : 0,
    ];
  }

  Future<void> _readHistory(DateTime today) async {
    final past = StepMath.lastDays(today, historyDays)..removeLast();
    final wanted = <DateTime>[];
    for (var i = 0; i < past.length; i++) {
      final age = past.length - i; // 1 = yesterday
      final cached = _days.containsKey(StepMath.dateKey(past[i]));
      if (!cached || age <= _volatileDays) wanted.add(past[i]);
    }
    final totals = await Future.wait([
      for (final d in wanted)
        _source.stepsBetween(d, DateTime(d.year, d.month, d.day + 1)),
    ]);
    for (var i = 0; i < wanted.length; i++) {
      final steps = totals[i];
      if (steps == null) continue;
      final key = StepMath.dateKey(wanted[i]);
      // A day keeps the goal it was first recorded with.
      _days[key] = StepDay(
        dateKey: key,
        steps: steps,
        goal: _days[key]?.goal ?? _goal,
      );
    }
  }

  void _prune(DateTime today) {
    final oldest = StepMath.dateKey(
        DateTime(today.year, today.month, today.day - historyDays * 2));
    _days.removeWhere((key, _) => key.compareTo(oldest) < 0);
  }

  // ── Cloud ──────────────────────────────────────────────────────────────

  Future<void> _pushToday() async {
    if (_cloud.uid == null || !_enabled) return;
    final t = today;
    final signature = '${t.dateKey}:${t.steps}:${t.goal}:$_name:$_avatar';
    if (signature == _lastSaved) return;
    try {
      await _cloud.saveDay(StepDay(
        dateKey: t.dateKey,
        steps: t.steps,
        goal: t.goal,
        name: _name,
        avatar: _avatar,
      ));
      _lastSaved = signature;
    } catch (e) {
      appLogger.w('[Steps] cloud save failed: $e');
    }
  }

  void _listenToPartners() {
    _partnersSub?.cancel();
    if (_cloud.uid == null) return;
    _partnersSub = _cloud.watchPartners().listen((list) {
      final next = list.isEmpty ? null : list.first;
      if (next?.uid != _partner?.uid) {
        _partnerDaysSub?.cancel();
        _partnerDaysSub = null;
        _partnerDays = {};
        if (next != null) {
          _partnerDaysSub =
              _cloud.watchDays(next.uid, limit: historyDays).listen((days) {
            _partnerDays = days;
            _syncWidget();
            _notify();
          }, onError: (Object e) {
            // The partner unpaired: their grant is gone and the read is
            // refused. The partners stream removes them on its own.
            appLogger.w('[Steps] partner days stream closed: $e');
          });
        }
      }
      _partner = next;
      _syncWidget();
      _notify();
    }, onError: (Object e) {
      appLogger.w('[Steps] partners stream error: $e');
    });
  }

  void _listenToCheers() {
    _cheersSub?.cancel();
    if (_cloud.uid == null) return;
    _cheersSub = _cloud.watchCheers().listen((cheers) {
      for (final c in cheers) {
        if (!_seenCheers.add(c.id)) continue;
        // Only the current partner's cheers are shown; anything else in the
        // box is left over from a previous pairing.
        if (c.fromUid == _partner?.uid) {
          onCheer?.call(c.kind, partner?.name ?? '');
        }
        _cloud.consumeCheer(c.id).catchError((Object e) {
          appLogger.w('[Steps] could not clear cheer: $e');
        });
      }
    }, onError: (Object e) {
      appLogger.w('[Steps] cheers stream error: $e');
    });
  }

  /// Creates a pairing code. Today's steps are pushed first so the person who
  /// redeems it sees a name and a number straight away.
  Future<String?> createInvite() async {
    await _pushToday();
    return _cloud.createInvite();
  }

  Future<StepJoinResult> join(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.length != 6) return StepJoinResult.notFound;
    await _pushToday();
    return _cloud.redeemInvite(clean, myName: _name, myAvatar: _avatar);
  }

  Future<bool> unpair() async {
    final p = _partner;
    if (p == null) return true;
    try {
      await _cloud.unpair(p.uid);
      return true;
    } catch (e) {
      appLogger.w('[Steps] unpair failed: $e');
      return false;
    }
  }

  /// Returns false when rate-limited or the send failed.
  Future<bool> sendCheer(StepCheerKind kind) async {
    final p = _partner;
    if (p == null || !canCheer) return false;
    _lastCheerSent = _now();
    _notify();
    try {
      await _cloud.sendCheer(p.uid, kind);
      return true;
    } catch (e) {
      appLogger.w('[Steps] cheer failed: $e');
      _lastCheerSent = null;
      _notify();
      return false;
    }
  }

  // ── Storage and widget ─────────────────────────────────────────────────

  void _loadCache() {
    final raw = _prefs.getString(_kDays);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach((key, value) {
        _days[key] = StepDay.fromJson(key, value as Map<String, dynamic>);
      });
    } catch (e) {
      appLogger.w('[Steps] discarded an unreadable step cache: $e');
    }
  }

  void _saveCache() {
    _prefs.setString(
      _kDays,
      jsonEncode({
        for (final e in _days.entries)
          e.key: {
            'steps': e.value.steps,
            'goal': e.value.goal,
            if (e.value.hourly.isNotEmpty) 'hourly': e.value.hourly,
          },
      }),
    );
  }

  void _syncWidget() {
    final p = partner;
    NativeWidgetService.syncSteps(
      enabled: _enabled,
      steps: today.steps,
      goal: today.goal,
      streak: streak,
      partnerName: p?.name ?? '',
      partnerSteps: p == null ? -1 : (partnerToday?.steps ?? 0),
      partnerGoal: partnerToday?.goal ?? _latestPartnerDay?.goal ?? 0,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _partnersSub?.cancel();
    _partnerDaysSub?.cancel();
    _cheersSub?.cancel();
    super.dispose();
  }
}
