import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/color_utils.dart';
import '../common/refined_sheet_wrapper.dart';
import '../shared/shared_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/premium_empty_state.dart';

class DailyLogSheet extends StatefulWidget {
  final DateTime date;
  const DailyLogSheet({super.key, required this.date});

  static void show(BuildContext context, {DateTime? date}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyLogSheet(date: date ?? DateTime.now()),
    );
  }

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  /// Safe parse for PRN / AI log times (`"08:30"`, `"8:30 AM"`, `"Just now"`).
  static int _parseHour(String raw) {
    final t = raw.trim();
    final hm = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(t);
    if (hm != null) {
      var h = int.tryParse(hm.group(1)!) ?? 8;
      final lower = t.toLowerCase();
      if (lower.contains('pm') && h < 12) h += 12;
      if (lower.contains('am') && h == 12) h = 0;
      return h.clamp(0, 23);
    }
    return DateTime.now().hour;
  }

  static int _parseMinute(String raw) {
    final hm = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw.trim());
    if (hm != null) {
      return (int.tryParse(hm.group(2)!) ?? 0).clamp(0, 59);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final S = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();

    final isToday = _isSameDay(_selectedDate, DateTime.now());

    // Adjust doses based on selected date's day of week
    final weekday = (_selectedDate.weekday % 7);
    final dayKey =
        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final historicalDoseEntries = state.history[dayKey] ?? [];

    // Get scheduled doses for the current view
    final doses = state.meds
        .expand((m) => m.schedule
            .where((s) => s.enabled && s.days.contains(weekday))
            .map((s) => DoseItem(med: m, sched: s, key: '${m.id}-${s.label}')))
        .toList();

    // Combine scheduled doses with PRN doses from history
    final prnDoses = historicalDoseEntries
        .where((e) => e.label.startsWith('PRN-'))
        .map((e) {
          final med = state.meds.firstWhere((m) => m.id == e.medId,
              orElse: () => Medicine(
                  id: -1,
                  name: 'Unknown',
                  count: 0,
                  totalCount: 0,
                  courseStartDate: ''));
          return DoseItem(
            med: med,
            sched: ScheduleEntry(
                id: 'prn_${e.medId}_${e.time}',
                h: _parseHour(e.time),
                m: _parseMinute(e.time),
                label: 'PRN',
                days: const []),
            key: 'PRN-${e.medId}-${e.time}',
          );
        })
        .where((d) => d.med.id != -1) // Filter out placeholders
        .toList();

    final allDosesToShow = [...doses, ...prnDoses];

    final todaySymptoms = state.symptoms.where((s) {
      return s.timestamp.year == _selectedDate.year &&
          s.timestamp.month == _selectedDate.month &&
          s.timestamp.day == _selectedDate.day;
    }).toList();

    final takenCount = isToday
        ? allDosesToShow
            .where((d) =>
                d.key.startsWith('PRN-') || (state.takenToday[d.key] == true))
            .length
        : historicalDoseEntries.where((e) => e.taken).length;

    final completion =
        allDosesToShow.isNotEmpty ? takenCount / allDosesToShow.length : 0.0;

    return RefinedSheetWrapper(
      title: S.dailyLogTitle,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: L.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.history_rounded, color: L.secondary, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Navigator
          MedAiDepthCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            radius: AppRadius.l,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  button: true,
                  label: 'Previous day',
                  child: AnimatedPressable(
                    onTap: () {
                      HapticEngine.light();
                      setState(() => _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1)));
                    },
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_left_rounded,
                          color: L.sub, size: 28),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      isToday
                          ? 'TODAY'
                          : '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: L.text,
                          letterSpacing: 1.0),
                    ),
                    Text(_getWeekdayName(_selectedDate.weekday).toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                Semantics(
                  button: true,
                  label: 'Next day',
                  enabled: !_selectedDate.isAfter(
                      DateTime.now().subtract(const Duration(hours: 1))),
                  child: AnimatedPressable(
                    onTap: _selectedDate.isAfter(
                            DateTime.now().subtract(const Duration(hours: 1)))
                        ? null
                        : () {
                            HapticEngine.light();
                            setState(() => _selectedDate =
                                _selectedDate.add(const Duration(days: 1)));
                          },
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      alignment: Alignment.center,
                      child: Icon(Icons.chevron_right_rounded,
                          size: 28,
                          color: _selectedDate.isAfter(DateTime.now()
                                  .subtract(const Duration(hours: 1)))
                              ? L.border
                              : L.sub),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Completion Header
          MedAiDepthCard(
            padding: const EdgeInsets.all(20),
            radius: AppRadius.squircle,
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner track
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 2,
                          color: L.border.withValues(alpha: 0.15),
                        ),
                      ),
                      // Progress track
                      CircularProgressIndicator(
                        value: completion,
                        strokeWidth: 10,
                        backgroundColor: L.fill.withValues(alpha: 0.1),
                        color: completion == 1.0 ? L.success : L.text,
                        strokeCap: StrokeCap.round,
                      ),
                      if (completion == 1.0)
                        reduceMotion
                            ? Icon(Icons.star_rounded,
                                color: L.success, size: 24)
                            : Icon(Icons.star_rounded,
                                    color: L.success, size: 24)
                                .animate(onPlay: (c) => c.repeat())
                                .shimmer(duration: 2.seconds)
                      else
                        Text(
                          '${(completion * 100).round()}%',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.5,
                            color: L.text,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completion == 1.0
                            ? 'Perfect Day! 🌟'
                            : 'Daily Completion',
                        style: AppTypography.labelSmall.copyWith(
                          color: completion == 1.0 ? L.success : L.sub,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$takenCount of ${allDosesToShow.length} doses logged',
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- MEDICATIONS SECTION ---
          _SectionHeader(
              title: 'MEDICATIONS', count: allDosesToShow.length, L: L),
          if (allDosesToShow.isEmpty)
            PremiumEmptyState(
              title: 'No doses scheduled',
              subtitle: 'Check back later or add a PRN dose to see logs here.',
              mascotFeature: 'missed',
              icon: Icons.event_available_rounded,
              compact: true,
            )
          else
            ...allDosesToShow.asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              final isPrn = d.key.startsWith('PRN-');
              final taken = isToday
                  ? (isPrn || (state.takenToday[d.key] ?? false))
                  : historicalDoseEntries.any((e) =>
                      e.medId == d.med.id &&
                      e.taken &&
                      e.label == d.sched.label);
              return _entrance(
                reduceMotion,
                _DoseLogRow(
                  dose: d,
                  taken: taken,
                  isPrn: isPrn,
                  L: L,
                  reduceMotion: reduceMotion,
                  onTap: isPrn
                      ? null
                      : () async {
                          HapticEngine.selection();
                          await state.toggleDose(d, date: _selectedDate);
                        },
                  onUndo: isPrn
                      ? () {
                          HapticEngine.light();
                          state.undoPrnDose(d.med.id, d.key.split('-').last);
                        }
                      : null,
                ),
                delay: Duration(milliseconds: idx * 50),
              );
            }),

          const SizedBox(height: 32),

          // --- SYMPTOMS SECTION ---
          _SectionHeader(
              title: 'SYMPTOMS & LOGS', count: todaySymptoms.length, L: L),
          if (todaySymptoms.isEmpty)
            _EmptyState(message: 'No symptoms logged for this day.', L: L)
          else
            ...todaySymptoms.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              return _entrance(
                reduceMotion,
                _SymptomLogRow(
                  symptom: s,
                  L: L,
                  onDelete: () => state.deleteSymptom(s.id),
                ),
                delay: Duration(milliseconds: idx * 50),
              );
            }),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  static Widget _entrance(bool reduceMotion, Widget child, {Duration? delay}) {
    if (reduceMotion) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.1, end: 0, curve: AppCurves.smooth);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final AppThemeColors L;
  const _SectionHeader(
      {required this.title, required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: L.sub,
                letterSpacing: 1.2,
              )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10, fontWeight: FontWeight.w900, color: L.sub)),
          ),
        ],
      ),
    );
  }
}

class _DoseLogRow extends StatelessWidget {
  final DoseItem dose;
  final bool taken;
  final bool isPrn;
  final AppThemeColors L;
  final bool reduceMotion;
  final VoidCallback? onUndo;
  final VoidCallback? onTap;

  const _DoseLogRow({
    required this.dose,
    required this.taken,
    required this.L,
    this.isPrn = false,
    this.reduceMotion = false,
    this.onUndo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrnBadge = isPrn;
    final medColor = hexToColor(dose.med.color);

    // 2026 Premium Pure Black Styling
    final Color bgColor = taken ? Colors.black : L.card.withValues(alpha: 0.8);
    final Color textColor = taken ? Colors.white : L.text;
    final Color subTextColor = taken ? Colors.white60 : L.sub.withValues(alpha: 0.65);
    final Color borderColor = taken ? Colors.white12 : L.border.withValues(alpha: 0.1);

    final Widget checkboxChild = taken
        ? KeyedSubtree(
            key: const ValueKey('checked'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [medColor, Color.lerp(medColor, Colors.white, 0.2)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: medColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, size: 22, color: Colors.white),
              ),
            ),
          )
        : KeyedSubtree(
            key: const ValueKey('unchecked'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: medColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: medColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: MedImage(
                  imageUrl: dose.med.imageUrl,
                  borderRadius: 100,
                  placeholder: Icon(
                    Icons.medication_rounded,
                    size: 20,
                    color: medColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          );

    return Semantics(
      button: onTap != null,
      label: '${dose.med.name}, ${taken ? 'taken' : 'not taken'}',
      child: AnimatedPressable(
        onTap: onTap,
        disabled: onTap == null,
        scaleFactor: 0.98,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : MedAiA11y.motion(context, AppDurations.fast),
          curve: AppCurves.smooth,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: borderColor, width: taken ? 1.5 : 1.0),
            boxShadow: taken
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : AppShadows.premium,
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) {
                final scale = Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: AppCurves.emilOut),
                );
                final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOut),
                );
                return FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: checkboxChild,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dose.med.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: textColor,
                            letterSpacing: -0.3,
                            decoration: taken ? TextDecoration.lineThrough : null,
                            decorationColor: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      if (isPrnBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: taken ? Colors.white12 : L.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: taken ? Colors.white24 : L.accent.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'PRN',
                            style: AppTypography.labelSmall.copyWith(
                              color: taken ? Colors.white : L.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dose.med.dose} · ${isPrnBadge ? AppLocalizations.of(context)!.prnLabel : dose.sched.label}',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 13,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isPrnBadge && onUndo != null) ...[
              Semantics(
                button: true,
                label: 'Remove PRN dose',
                child: AnimatedPressable(
                  onTap: onUndo,
                  child: Container(
                    width: MedAiA11y.minTapTarget,
                    height: MedAiA11y.minTapTarget,
                    decoration: BoxDecoration(
                      color: taken
                          ? Colors.white12
                          : L.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 18,
                        color: taken ? Colors.white : L.error),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: taken ? Colors.white10 : L.fill.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                fmtTime(dose.sched.h, dose.sched.m, context),
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SymptomLogRow extends StatelessWidget {
  final Symptom symptom;
  final AppThemeColors L;
  final VoidCallback onDelete;

  const _SymptomLogRow(
      {required this.symptom, required this.L, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: L.border.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sick_rounded, size: 16, color: L.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symptom.name,
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: L.text)),
                Row(
                  children: [
                    Text('Severity: ${symptom.severity}/10',
                        style: AppTypography.bodySmall
                            .copyWith(fontSize: 12, color: L.sub)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticEngine.selection();
              onDelete();
            },
            tooltip: 'Delete symptom',
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: L.sub),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final AppThemeColors L;
  const _EmptyState({required this.message, required this.L});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      title: 'Nothing here yet',
      subtitle: message,
      mascotFeature: 'home',
      icon: Icons.inbox_outlined,
      compact: true,
    );
  }
}
