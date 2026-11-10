import '../../domain/entities/entities.dart';

/// Numbered facts about the user's own medication record, for Ask Med AI.
///
/// The arithmetic happens here, on the device, not in the model: adherence
/// rates, which dose slips most, how late doses run, when stock runs out.
/// The model is then asked only to put these facts into words and cite them.
/// That split is what makes the assistant different from a general chatbot
/// (it knows *your* record) and what keeps it honest (a number it quotes was
/// computed, never guessed — and each answer shows the facts it used).
class HealthFact {
  /// Stable-within-a-conversation id, "F1", "F2"… — what answers cite.
  final String id;

  /// Chip label, a few words.
  final String label;

  /// The fact as one plain sentence.
  final String text;

  const HealthFact(this.id, this.label, this.text);

  @override
  String toString() => '[$id] $text';
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _clock(int h, int m) {
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

const _weekdays = [
  'Sundays',
  'Mondays',
  'Tuesdays',
  'Wednesdays',
  'Thursdays',
  'Fridays',
  'Saturdays',
];

int _pct(int n, int d) => d == 0 ? 0 : (n * 100 / d).round();

/// Whether [med] was meant to be taken on [day] per its course dates.
bool _inCourse(Medicine med, DateTime day) {
  final start = DateTime.tryParse(med.courseStartDate);
  if (start != null &&
      day.isBefore(DateTime(start.year, start.month, start.day))) {
    return false;
  }
  final len = med.courseDurationDays;
  if (start != null && len != null && len > 0) {
    final end = DateTime(start.year, start.month, start.day + len);
    if (!day.isBefore(end)) return false;
  }
  return true;
}

class _Slot {
  final Medicine med;
  final ScheduleEntry sched;
  final DateTime day;
  final DoseEntry? entry;
  _Slot(this.med, this.sched, this.day, this.entry);
  bool get taken => entry?.taken == true;
  bool get skipped => entry?.skipped == true;
}

/// Every scheduled dose on [day], paired with what was logged for it.
List<_Slot> _slotsOn(
    DateTime day, List<Medicine> meds, Map<String, List<DoseEntry>> history) {
  final entries = history[_dayKey(day)] ?? const <DoseEntry>[];
  final dow = day.weekday % 7;
  final out = <_Slot>[];
  for (final med in meds) {
    if (!_inCourse(med, day)) continue;
    for (final s in med.schedule) {
      if (!s.enabled || !s.days.contains(dow)) continue;
      final e = entries
          .where((x) => x.medId == med.id && x.label == s.label)
          .firstOrNull;
      out.add(_Slot(med, s, day, e));
    }
  }
  return out;
}

String _medLabel(Medicine m) =>
    m.dose.trim().isEmpty ? m.name : '${m.name} ${m.dose.trim()}';

/// Builds the fact sheet. Pure: everything comes in as arguments.
///
/// Adherence counts completed days only (yesterday and earlier), from the
/// later of [windowDays] ago and the first day anything was logged, so a new
/// user is not scored against weeks before they installed the app.
List<HealthFact> buildHealthFacts({
  required List<Medicine> meds,
  required Map<String, List<DoseEntry>> history,
  required List<Symptom> symptoms,
  required int streak,
  required DateTime now,
  int windowDays = 30,
}) {
  final facts = <HealthFact>[];
  void add(String label, String text) =>
      facts.add(HealthFact('F${facts.length + 1}', label, text));

  final today = DateTime(now.year, now.month, now.day);

  if (meds.isEmpty) {
    add('No medicines', 'No medicines are being tracked yet.');
    return facts;
  }

  // ── Current regimen ────────────────────────────────────────────────
  final regimen = meds.map((m) {
    final times = m.schedule
        .where((s) => s.enabled)
        .map((s) => _clock(s.h, s.m))
        .join(', ');
    return times.isEmpty ? _medLabel(m) : '${_medLabel(m)} ($times)';
  }).join('; ');
  add('Your medicines', 'Current medicines: $regimen.');

  // ── Adherence over completed days ──────────────────────────────────
  final loggedDays = history.keys
      .map(DateTime.tryParse)
      .whereType<DateTime>()
      .toList()
    ..sort();
  var from = today.subtract(Duration(days: windowDays));
  if (loggedDays.isNotEmpty && loggedDays.first.isAfter(from)) {
    from = DateTime(
        loggedDays.first.year, loggedDays.first.month, loggedDays.first.day);
  }

  final past = <_Slot>[];
  for (var d = from; d.isBefore(today); d = d.add(const Duration(days: 1))) {
    past.addAll(_slotsOn(d, meds, history));
  }

  if (past.isEmpty) {
    add('Getting started',
        'There are no completed days of dose history yet to measure.');
  } else {
    final days = today.difference(from).inDays;
    final taken = past.where((s) => s.taken).length;
    final weekFrom = today.subtract(const Duration(days: 7));
    final week = past.where((s) => !s.day.isBefore(weekFrom)).toList();
    final weekTaken = week.where((s) => s.taken).length;
    add(
      'Overall adherence',
      'Over the last $days days, $taken of ${past.length} scheduled doses '
          'were logged as taken (${_pct(taken, past.length)}%)'
          '${week.isEmpty ? '' : '; over the last 7 days, ${_pct(weekTaken, week.length)}%'}.',
    );

    // Per medicine, with the slot that slips most.
    for (final med in meds) {
      final mine = past.where((s) => s.med.id == med.id).toList();
      if (mine.isEmpty) continue;
      final t = mine.where((s) => s.taken).length;
      final missesBySlot = <String, int>{};
      for (final s in mine.where((s) => !s.taken)) {
        missesBySlot[s.sched.label] = (missesBySlot[s.sched.label] ?? 0) + 1;
      }
      final worst = missesBySlot.entries.isEmpty
          ? null
          : (missesBySlot.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;
      final skipped = mine.where((s) => s.skipped).length;
      // "Missed most" only means something when there is more than one
      // daily slot to compare.
      final slots = mine.map((s) => s.sched.label).toSet().length;
      final worstText = worst != null && slots > 1
          ? '; the ${worst.key} dose is missed most (${worst.value} times)'
          : '';
      add(
        med.name,
        '${_medLabel(med)}: $t of ${mine.length} doses taken '
        '(${_pct(t, mine.length)}%)$worstText'
        '${skipped > 0 ? '; $skipped marked as skipped on purpose' : ''}.',
      );
    }

    // Weekday pattern — only with enough misses to mean something.
    final misses = past.where((s) => !s.taken && !s.skipped).toList();
    if (misses.length >= 3) {
      final byDow = List<int>.filled(7, 0);
      for (final s in misses) {
        byDow[s.day.weekday % 7]++;
      }
      var worstDow = 0;
      for (var i = 1; i < 7; i++) {
        if (byDow[i] > byDow[worstDow]) worstDow = i;
      }
      // A "pattern" needs the worst day to stand out from an even spread.
      if (byDow[worstDow] >= 2 && byDow[worstDow] * 7 >= misses.length * 2) {
        add('Tricky day',
            'Most missed doses fall on ${_weekdays[worstDow]} (${byDow[worstDow]} of ${misses.length}).');
      }
    }

    // Lateness, from takenAt against the scheduled time.
    for (final med in meds) {
      final late = <String, List<int>>{};
      for (final s in past.where((s) => s.med.id == med.id && s.taken)) {
        final at = DateTime.tryParse(s.entry?.takenAt ?? '');
        if (at == null) continue;
        final sched =
            DateTime(s.day.year, s.day.month, s.day.day, s.sched.h, s.sched.m);
        final mins = at.difference(sched).inMinutes;
        if (mins < -180 || mins > 720) continue; // logged after the fact
        late.putIfAbsent(s.sched.label, () => []).add(mins);
      }
      for (final e in late.entries) {
        if (e.value.length < 5) continue;
        final sorted = [...e.value]..sort();
        final median = sorted[sorted.length ~/ 2];
        if (median >= 30) {
          add('${med.name} timing',
              'The ${e.key} ${med.name} dose is usually logged about $median minutes after its scheduled time.');
        }
      }
    }
  }

  // ── Today ──────────────────────────────────────────────────────────
  final todaySlots = _slotsOn(today, meds, history);
  if (todaySlots.isNotEmpty) {
    final done = todaySlots.where((s) => s.taken).length;
    final nowMin = now.hour * 60 + now.minute;
    final open = todaySlots.where((s) => !s.taken && !s.skipped).toList()
      ..sort((a, b) =>
          (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));
    final overdue = open.where((s) => s.sched.h * 60 + s.sched.m < nowMin);
    final next = open.where((s) => s.sched.h * 60 + s.sched.m >= nowMin);
    add(
      'Today',
      'Today: $done of ${todaySlots.length} doses logged'
          '${overdue.isEmpty ? '' : '; not yet logged and past due: ${overdue.map((s) => '${s.med.name} (${_clock(s.sched.h, s.sched.m)})').join(', ')}'}'
          '${next.isEmpty ? '' : '; next up: ${next.first.med.name} at ${_clock(next.first.sched.h, next.first.sched.m)}'}.',
    );
  }

  add('Streak', 'Current streak: $streak day${streak == 1 ? '' : 's'}.');

  // ── Stock ──────────────────────────────────────────────────────────
  for (final med in meds) {
    if (med.totalCount <= 0) continue;
    final perWeek = med.schedule
        .where((s) => s.enabled)
        .fold<int>(0, (n, s) => n + s.days.length);
    if (perWeek == 0) continue;
    final perDay = perWeek / 7;
    final daysLeft = (med.count / perDay).floor();
    final runOut = today.add(Duration(days: daysLeft));
    add(
      '${med.name} stock',
      '${med.name}: ${med.count} left, about $daysLeft days at the current '
          'schedule (runs out around ${_dayKey(runOut)})'
          '${med.count <= med.refillAt ? ' — already at or below the refill alert of ${med.refillAt}' : ''}.',
    );
  }

  // ── Symptoms (descriptive only — no causal claims) ─────────────────
  final since = today.subtract(Duration(days: windowDays));
  final recent = symptoms.where((s) => s.timestamp.isAfter(since)).toList();
  if (recent.isNotEmpty) {
    final byName = <String, List<int>>{};
    for (final s in recent) {
      byName.putIfAbsent(s.name.toLowerCase(), () => []).add(s.severity);
    }
    final top = byName.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final desc = top.take(3).map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return '${e.key} ×${e.value.length} (average severity ${avg.toStringAsFixed(1)}/10)';
    }).join(', ');
    add('Symptoms', 'Symptoms logged in the last $windowDays days: $desc.');
  }

  return facts;
}
