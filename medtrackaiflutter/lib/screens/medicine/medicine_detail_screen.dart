import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import 'widgets/body_impact_card.dart';
import 'widgets/inline_ai_coach.dart';
import 'widgets/medicine_safety_card.dart';
// ══════════════════════════════════════════════════════════════════════
// MEDICINE DETAIL SCREEN (Cal AI Industrial Hub Refined)
// ══════════════════════════════════════════════════════════════════════

class MedicineDetailScreen extends StatefulWidget {
  final int medId;
  final VoidCallback onBack;
  final bool initialEditMode;

  const MedicineDetailScreen({
    super.key,
    required this.medId,
    required this.onBack,
    this.initialEditMode = false,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late bool _editMode;
  late Map<String, dynamic> _editFields;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _editMode = widget.initialEditMode;
    _resetEdit();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _resetEdit() {
    final state = Provider.of<AppState>(context, listen: false);
    final med = state.meds.firstWhere((m) => m.id == widget.medId,
        orElse: () => state.meds.first);
    _editFields = {
      'name': med.name,
      'brand': med.brand,
      'dose': med.dose,
      'form': med.form,
      'category': med.category,
      'notes': med.notes,
      'count': med.count.toString(),
      'totalCount': med.totalCount.toString(),
      'refillAt': med.refillAt.toString(),
      'intakeInstructions': med.intakeInstructions,
      'pharmacyName': med.refillInfo?.pharmacyName ?? '',
      'pharmacyPhone': med.refillInfo?.pharmacyPhone ?? '',
      'rxNumber': med.refillInfo?.rxNumber ?? '',
      'price': med.price?.toString() ?? '',
      'currency': med.currency ?? '',
      'color': med.color,
    };
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final med = context.select<AppState, Medicine>((state) => state.meds
        .firstWhere((m) => m.id == widget.medId,
            orElse: () =>
                state.meds.isNotEmpty ? state.meds.first : Medicine.empty()));

    if (med.id == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBack());
      return const Scaffold(body: Center(child: AppShimmer(width: 64, height: 64, shape: BoxShape.circle)));
    }

    final adherence = context
        .select<AppState, int>((s) => s.getAdherenceForMed(widget.medId));
    final historyCount = context.select<AppState, ({int taken, int total})>(
        (s) => s.getHistoryCountForMed(widget.medId));
    final medColor = hexToColor(med.color);

    return AppScaffold(
      showAurora: context.isDark,
      backgroundColor: L.bg,
      body: Stack(
        children: [
          _editMode
              ? _buildEditMode(med, L)
              : _buildViewMode(med, adherence, historyCount, medColor, L),
        ],
      ),
    );
  }

  Widget _buildViewMode(Medicine med, int adherence,
      ({int taken, int total}) historyCount, Color medColor, AppThemeColors L) {
    return RawScrollbar(
      controller: _scrollController,
      thumbColor: L.text.withValues(alpha: 0.1),
      radius: const Radius.circular(10),
      thickness: 4,
      child: CustomScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: PremiumPageHeader(
              title: med.name,
              subtitle: med.brand.isNotEmpty ? med.brand : 'Generic',
              onBack: widget.onBack,
              trailing: _headerIconButton(
                L: L,
                icon: Icons.edit_rounded,
                label: 'Edit medicine',
                onTap: () {
                  HapticEngine.selection();
                  setState(() {
                    _resetEdit();
                    _editMode = true;
                  });
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeroSection(med, medColor, L)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (med.intakeInstructions.isNotEmpty &&
                      med.intakeInstructions != 'None') ...[
                    _buildIntakeChip(med.intakeInstructions, L),
                    const SizedBox(height: AppSpacing.p24),
                  ],
                  _buildBentoMetrics(med, adherence, L),
                  const SizedBox(height: AppSpacing.p16),
                  _buildQuickActions(med, context.read<AppState>(), L),
                  const SizedBox(height: AppSpacing.p24),

                  if (med.productAnalysis != null) ...[
                    _buildAnalysisButton(med, L),
                    const SizedBox(height: AppSpacing.p24),
                  ],

                  if (med.aiSafetyProfile != null && (med.aiSafetyProfile!.mechanismOfAction.isNotEmpty && med.aiSafetyProfile!.mechanismOfAction != 'Details about how this medication works in your body will appear here.')) ...[
                    Builder(builder: (context) {
                      final impact = BodyImpactSummary(
                        mechanismOfAction: med.aiSafetyProfile!.mechanismOfAction,
                        onsetMinutes: med.aiSafetyProfile!.onsetMinutes,
                        peakHours: med.aiSafetyProfile!.peakHours,
                        durationHours: med.aiSafetyProfile!.durationHours,
                        bodySystems: med.aiSafetyProfile!.bodySystems,
                        timelineEffects: med.aiSafetyProfile!.timelineEffects,
                        ahaFacts: med.aiSafetyProfile!.ahaFacts,
                      );
                      return BodyImpactCard(
                        impact: impact,
                        medName: med.name,
                        onAskAIPressed: () => InlineAiCoach.show(context, med, impact: impact),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                    }),
                    const SizedBox(height: AppSpacing.p24),
                  ],

                  _buildSafetyPanel(med, L),
                  const SizedBox(height: AppSpacing.p16),
                  MedicineSafetyCard(med: med),
                  const SizedBox(height: AppSpacing.p24),
                  _buildHistorySection(med, adherence, historyCount.taken,
                      historyCount.total, L),
                  const SizedBox(height: AppSpacing.p24),
                  _buildScheduleSection(med, context.read<AppState>(), L),
                  const SizedBox(height: AppSpacing.p24),
                  _buildSpecificationsSection(med, L),
                  const SizedBox(height: AppSpacing.p24),
                  _buildSettingsSection(med, context.read<AppState>(), L),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(Medicine med, AppThemeColors L) {
    return Column(
      children: [
        PremiumPageHeader(
          title: med.name,
          subtitle: 'Edit details',
          trailing: _headerIconButton(
            L: L,
            icon: Icons.close_rounded,
            label: 'Cancel editing',
            onTap: () {
              HapticEngine.selection();
              setState(() {
                _resetEdit();
                _editMode = false;
              });
            },
          ),
        ),

        Expanded(
          child: RawScrollbar(
            controller: _scrollController,
            thumbColor: L.text.withValues(alpha: 0.1),
            radius: const Radius.circular(10),
            thickness: 4,
            child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.p20, AppSpacing.gutter, 120),
              child: Column(
                children: [
                  _buildEditForm(med, context.read<AppState>(), L),
                ],
              ),
            ),
          ),
        ),

        // ── SAVE ACTION BAR ──
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.p24, AppSpacing.p16, AppSpacing.p24, AppSpacing.p32),
          decoration: BoxDecoration(
            color: L.bg,
            border: Border(
                top: BorderSide(
                    color: L.border.withValues(alpha: 0.35), width: 0.7)),
          ),
          child: MedAiCTA(
            label: 'Save changes',
            icon: Icons.check_rounded,
            onTap: () {
              HapticEngine.success();
              _save(med, context.read<AppState>());
            },
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('antibiotic')) return Icons.biotech_rounded;
    if (lower.contains('vitamin') || lower.contains('supplement')) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('pain')) return Icons.healing_rounded;
    if (lower.contains('sleep')) return Icons.bedtime_rounded;
    if (lower.contains('liquid') ||
        lower.contains('syrup') ||
        lower.contains('drops')) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('cream') || lower.contains('ointment')) {
      return Icons.opacity_rounded;
    }
    if (lower.contains('inhaler')) return Icons.air_rounded;
    if (lower.contains('injection')) return Icons.vaccines_rounded;
    return Icons.medication_rounded;
  }

  Widget _headerIconButton({
    required AppThemeColors L,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: L.fill,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: L.text, size: 18),
        ),
      ),
    );
  }

  Widget _buildHeroSection(Medicine med, Color medColor, AppThemeColors L) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final hasImage =
        (med.imageUrl?.isNotEmpty ?? false) && med.imageUrl != ' ';

    Widget hero = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.pastelSky,
              child: hasImage
                  ? Image.network(
                      med.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          _categoryIcon(med.category),
                          size: 64,
                          color: L.sub.withValues(alpha: 0.45),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        _categoryIcon(med.category),
                        size: 64,
                        color: L.sub.withValues(alpha: 0.45),
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.p12,
              bottom: AppSpacing.p12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.p12,
                  vertical: AppSpacing.p8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadius.max),
                ),
                child: Text(
                  '${med.dose.isNotEmpty ? med.dose : '—'} · ${med.form.isNotEmpty ? med.form : 'tablet'}',
                  style: AppTypography.labelMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (med.category.isNotEmpty)
              PositionedDirectional(
                end: AppSpacing.p12,
                top: AppSpacing.p12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.p12,
                    vertical: AppSpacing.p8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pastelMint.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon(med.category), size: 14, color: L.text),
                      const SizedBox(width: AppSpacing.p4),
                      Text(
                        med.category,
                        style: AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!reduceMotion) {
      hero = hero
          .animate()
          .fadeIn(duration: 350.ms, curve: AppCurves.smooth)
          .slideY(begin: 0.04, end: 0, curve: AppCurves.smooth);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        AppSpacing.p8,
      ),
      child: Hero(tag: 'med_${med.id}', child: hero),
    );
  }

  Widget _buildSafetyPanel(Medicine med, AppThemeColors L) {
    final isAntibiotic = med.category.toLowerCase().contains('antibiotic');
    if (!isAntibiotic) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p20),
      decoration: BoxDecoration(
        color: AppColors.pastelSun,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: const Icon(Icons.shield_rounded,
                    size: 18, color: AppColors.amber),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: Text(
                  'Complete the full course',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: L.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p12),
          Text(
            'This antibiotic must be finished entirely. Do not stop early, even if symptoms improve — unfinished courses can drive resistance.',
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetrics(Medicine med, int adherence, AppThemeColors L) {
    final pct =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final nextDose = _getNextDoseTime(med.schedule);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DiagnosticCard(
                  label: 'Adherence',
                  value: adherence == -1 ? '••' : '$adherence%',
                  icon: Icons.trending_up_rounded,
                  tint: AppColors.pastelMint,
                  L: L,
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: _DiagnosticCard(
                  label: 'Next dose',
                  value: nextDose,
                  icon: Icons.schedule_rounded,
                  tint: AppColors.pastelSun,
                  L: L,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p8),
        _DiagnosticCard(
          label: 'Inventory',
          value: '${med.count} units',
          icon: Icons.inventory_2_outlined,
          tint: AppColors.pastelSky,
          L: L,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock level',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p8),
              _ModernStockBar(
                pct: pct,
                isLow: med.count <= med.refillAt,
                L: L,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Medicine med, AppState state, AppThemeColors L) {
    final isLow = med.count <= med.refillAt;
    return Row(
      children: [
        // ── RESTOCK ──
        Expanded(
          child: Semantics(
            button: true,
            label: 'Restock ${med.name}',
            child: AnimatedPressable(
              onTap: () => _showRestockSheet(med, state, L),
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
                decoration: BoxDecoration(
                  color: isLow ? AppColors.pastelSun : AppColors.pastelSky,
                  borderRadius: BorderRadius.circular(AppRadius.max),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.refresh_rounded,
                      size: 18,
                      color: L.text,
                    ),
                    const SizedBox(width: AppSpacing.p8),
                    Text(
                      'Restock',
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.p12),
        // ── LOG FLEXIBLE DOSE ──
        Expanded(
          child: _AnimatedLogDoseButton(med: med),
        ),
      ],
    );
  }

  Widget _buildAnalysisButton(Medicine med, AppThemeColors L) {
    return MedAiCTA(
      label: 'View Full AI Analysis',
      icon: Icons.auto_awesome_rounded,
      secondary: true,
      semanticsLabel: 'View full AI analysis for ${med.name}',
      onTap: () {
        HapticEngine.selection();
        context.push(
          AppRoutes.analysisProduct,
          extra: ProductAnalysisRouteArgs(product: med.productAnalysis!),
        );
      },
    );
  }

  void _showRestockSheet(Medicine med, AppState state, AppThemeColors L) {
    HapticEngine.selection();
    int addAmount = 30;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => RefinedSheetWrapper(
          title: 'Restock inventory',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add units to ${med.name}',
                  style: AppTypography.bodySmall
                      .copyWith(color: L.sub, fontWeight: FontWeight.w500)),
              const SizedBox(height: AppSpacing.p32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RestockBtn(
                      label: '− 10',
                      onTap: () =>
                          setSheetState(() => addAmount = (addAmount - 10).clamp(10, 365)),
                      L: L,
                    ),
                    const SizedBox(width: AppSpacing.p20),
                    Column(
                      children: [
                        Text('$addAmount',
                            style: AppTypography.displayLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: L.text,
                                fontSize: 52,
                                letterSpacing: -2.0)),
                        Text('Units',
                            style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.p20),
                    _RestockBtn(
                      label: '+ 10',
                      onTap: () =>
                          setSheetState(() => addAmount = (addAmount + 10).clamp(10, 365)),
                      L: L,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p32),
                MedAiCTA(
                  label: 'Confirm restock',
                  onTap: () {
                    HapticEngine.success();
                    final newCount = med.count + addAmount;
                    state.updateMedicine(med.copyWith(count: newCount));
                    state.showToast('+$addAmount units added ✓');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }

  String _getNextDoseTime(List<ScheduleEntry> schedule) {
    if (schedule.isEmpty) return '--:--';
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;

    final sorted = List<ScheduleEntry>.from(schedule)
      ..sort((a, b) => (a.h * 60 + a.m).compareTo(b.h * 60 + b.m));

    for (var s in sorted) {
      if (s.h * 60 + s.m > nowMins) {
        return fmtTime(s.h, s.m, context);
      }
    }
    return fmtTime(sorted.first.h, sorted.first.m, context);
  }

  Widget _buildIntakeChip(String intake, AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.pastelLilac,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: Icon(Icons.restaurant_rounded, size: 18, color: L.text),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to take',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  intake,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            label: 'Schedule',
            icon: Icons.calendar_month_rounded,
            L: L,
            trailing: _HeaderAction(
                icon: Icons.add_rounded,
                label: 'Add slot',
                onTap: () async {
                  HapticEngine.selection();
                  final result = await ModernTimePicker.show(context,
                      initialTime: TimeOfDay.now(), title: "Add Reminder");
                  if (result != null) {
                    final newEntry = ScheduleEntry(
                        id: 'manual_${result.hour}_${result.minute}',
                        h: result.hour,
                        m: result.minute,
                        label: _getAutoLabel(result.hour),
                        days: const [1, 2, 3, 4, 5, 6, 0]);
                    _showRitualPicker(med.id, -1, newEntry, isNew: true);
                  }
                },
                L: L)),
        const SizedBox(height: AppSpacing.p12),
        if (med.schedule.isEmpty)
          _buildEmptyCard('No active reminders', Icons.notifications_off_rounded, L)
        else
          Container(
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.7),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Column(
                  children: med.schedule
                      .asMap()
                      .entries
                      .map((e) => _buildScheduleCard(med, e.value, e.key, L,
                          e.key == med.schedule.length - 1))
                      .toList()),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleCard(
      Medicine med, ScheduleEntry s, int idx, AppThemeColors L, bool isLast) {
    final medColor = hexToColor(med.color);
    return Container(
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.glassBorder.withValues(alpha: 0.08), width: 0.5))),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p12),
        onTap: () async {
          HapticEngine.selection();
          final result = await ModernTimePicker.show(context,
              initialTime: TimeOfDay(hour: s.h, minute: s.m),
              title: "Edit Reminder");
          if (result != null) {
            final updatedEntry = s.copyWith(
                h: result.hour,
                m: result.minute,
                label: _getAutoLabel(result.hour));
            _showRitualPicker(med.id, idx, updatedEntry, isNew: false);
          }
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.enabled ? medColor.withValues(alpha: 0.12) : L.fill.withValues(alpha: 0.3),
            border: Border.all(
              color: s.enabled ? medColor.withValues(alpha: 0.3) : L.border.withValues(alpha: 0.1),
              width: 1.0,
            ),
            boxShadow: s.enabled
                ? [
                    BoxShadow(
                      color: medColor.withValues(alpha: 0.1),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              s.h < 12 ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 18,
              color: s.enabled ? medColor : L.sub.withValues(alpha: 0.4),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
                fmtTime(s.h, s.m, context),
                style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: s.enabled ? L.text : L.sub)),
            const SizedBox(width: AppSpacing.p12),
            Text(
                (s.ritual != Ritual.none ? s.ritual.displayName : s.label),
                style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: L.sub)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.p4),
          child: Text(
              ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .asMap()
                  .entries
                  .map((day) => s.days.contains(day.key) ? day.value : '•')
                  .join('  '),
              style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: s.enabled
                      ? L.text.withValues(alpha: 0.6)
                      : L.sub.withValues(alpha: 0.3),
                  letterSpacing: 2)),
        ),
        trailing: AppToggle(
          value: s.enabled,
          onChanged: (v) {
            HapticEngine.selection();
            context.read<AppState>().toggleSchedule(med.id, idx);
          },
        ),
      ),
    );
  }

  Widget _buildHistorySection(
      Medicine med, int adh, int taken, int total, AppThemeColors L) {
    final medColor = hexToColor(med.color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'History', icon: Icons.history_rounded, L: L),
        const SizedBox(height: AppSpacing.p12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.p20),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.7),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(label: 'Taken', value: '$taken', color: L.text, L: L),
                  _Metric(
                      label: 'Missed',
                      value: '${total - taken}',
                      color: L.error,
                      L: L),
                  _Metric(label: 'Score', value: '$adh%', color: L.text, L: L),
                ],
              ),
              const SizedBox(height: AppSpacing.p20),
              Divider(color: L.border.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: AppSpacing.p20),
              _HistoryMatrix(medId: med.id, medColor: medColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecificationsSection(Medicine med, AppThemeColors L) {
    final tiles = [
      (label: 'Form', value: med.form, icon: Icons.medication_rounded, tint: AppColors.pastelSky),
      (label: 'Category', value: med.category, icon: Icons.label_rounded, tint: AppColors.pastelLilac),
      (label: 'Unit', value: med.unit, icon: Icons.scale_rounded, tint: AppColors.pastelMint),
      (label: 'Start', value: med.courseStartDate, icon: Icons.calendar_today_rounded, tint: AppColors.pastelSun),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            label: 'Specifications', icon: Icons.tune_rounded, L: L),
        const SizedBox(height: AppSpacing.p12),
        Wrap(
          spacing: AppSpacing.p8,
          runSpacing: AppSpacing.p8,
          children: [
            for (final t in tiles)
              SizedBox(
                width: (MediaQuery.sizeOf(context).width -
                        AppSpacing.gutter * 2 -
                        AppSpacing.p8) /
                    2,
                child: _SpecTile(
                  label: t.label,
                  value: t.value,
                  icon: t.icon,
                  L: L,
                  tint: t.tint,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: 'Settings', icon: Icons.settings_rounded, L: L),
        const SizedBox(height: AppSpacing.p12),
        Container(
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: L.border.withValues(alpha: 0.35), width: 0.7),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                _ManagementTile(
                    icon: Icons.add_rounded,
                    title: 'Quick refill (+10)',
                    iconColor: L.text,
                    iconBg: AppColors.pastelMint,
                    color: L.text,
                    onTap: () {
                      HapticEngine.success();
                      state.updateMed(med.id, count: med.count + 10);
                    },
                    L: L),
                _ManagementTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Remove medicine',
                    iconColor: AppColors.red,
                    iconBg: AppColors.pastelPink,
                    color: AppColors.red,
                    onTap: () {
                      HapticEngine.alertWarning();
                      state.deleteMed(med.id);
                      if (mounted) {
                        widget.onBack();
                      }
                    },
                    L: L,
                    isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Medicine med, AppState state, AppThemeColors L) {
    return Column(
      children: [
        _FormSection(label: 'Visuals', icon: Icons.palette_rounded, L: L, children: [
          _ColorPicker(
              selectedColor: _editFields['color'] ?? med.color,
              onColorSelected: (c) => setState(() => _editFields['color'] = c),
              L: L),
          Divider(color: L.border.withValues(alpha: 0.05), height: 1),
          _CategoryPicker(
              selectedCategory: _editFields['category'] ?? med.category,
              onCategorySelected: (c) => setState(() => _editFields['category'] = c),
              L: L),
        ]),
        const SizedBox(height: AppSpacing.p20),
        _FormSection(label: 'Identity', icon: Icons.person_rounded, L: L, children: [
          _ModernTextField(label: 'Medicine Name', value: _editFields['name'] ?? '', onChanged: (v) => _editFields['name'] = v, L: L),
          _ModernTextField(label: 'Brand Name', value: _editFields['brand'] ?? '', onChanged: (v) => _editFields['brand'] = v, L: L, isLast: true),
        ]),
        const SizedBox(height: AppSpacing.p20),
        _FormSection(label: 'Configuration', icon: Icons.settings_rounded, L: L, children: [
          _ModernTextField(label: 'Dosage', value: _editFields['dose'] ?? '', onChanged: (v) => _editFields['dose'] = v, L: L),
          _ModernTextField(label: 'Form', value: _editFields['form'] ?? '', onChanged: (v) => _editFields['form'] = v, L: L),
          _ModernTextField(label: 'Intake Instructions', value: _editFields['intakeInstructions'] ?? '', onChanged: (v) => _editFields['intakeInstructions'] = v, L: L, isLast: true),
        ]),
        const SizedBox(height: AppSpacing.p20),
        _FormSection(label: 'Inventory & refills', icon: Icons.inventory_2_rounded, L: L, children: [
          _ModernTextField(label: 'Current Count', value: _editFields['count'] ?? '', onChanged: (v) => _editFields['count'] = v, L: L, keyboard: TextInputType.number),
          _ModernTextField(label: 'Total Box Count', value: _editFields['totalCount'] ?? '', onChanged: (v) => _editFields['totalCount'] = v, L: L, keyboard: TextInputType.number),
          _ModernTextField(label: 'Refill Alert At', value: _editFields['refillAt'] ?? '', onChanged: (v) => _editFields['refillAt'] = v, L: L, keyboard: TextInputType.number, isLast: true),
        ]),
        const SizedBox(height: AppSpacing.p20),
        _FormSection(label: 'Pharmacy details', icon: Icons.local_pharmacy_rounded, L: L, children: [
          _ModernTextField(label: 'Pharmacy Name', value: _editFields['pharmacyName'] ?? '', onChanged: (v) => _editFields['pharmacyName'] = v, L: L),
          _ModernTextField(label: 'Pharmacy Phone', value: _editFields['pharmacyPhone'] ?? '', onChanged: (v) => _editFields['pharmacyPhone'] = v, L: L, keyboard: TextInputType.phone),
          _ModernTextField(label: 'Rx Number', value: _editFields['rxNumber'] ?? '', onChanged: (v) => _editFields['rxNumber'] = v, L: L),
          _ModernTextField(label: 'Price', value: _editFields['price'] ?? '', onChanged: (v) => _editFields['price'] = v, L: L, keyboard: const TextInputType.numberWithOptions(decimal: true), isLast: true),
        ]),
      ],
    );
  }

  void _save(Medicine med, AppState state) {
    // Build refill info even when the medicine had none yet — otherwise
    // `med.refillInfo?.copyWith(...)` short-circuits to null and pharmacy edits
    // are silently dropped (the "edit not working" bug for new meds).
    final refillInfo = (med.refillInfo ?? RefillInfo()).copyWith(
      pharmacyName: _editFields['pharmacyName'],
      pharmacyPhone: _editFields['pharmacyPhone'],
      rxNumber: _editFields['rxNumber'],
    );
    final priceText = (_editFields['price'] as String?)?.trim() ?? '';
    final updated = med.copyWith(
      name: _editFields['name'],
      brand: _editFields['brand'],
      dose: _editFields['dose'],
      form: _editFields['form'],
      category: _editFields['category'],
      notes: _editFields['notes'],
      intakeInstructions: _editFields['intakeInstructions'],
      count: int.tryParse(_editFields['count']) ?? med.count,
      totalCount: int.tryParse(_editFields['totalCount']) ?? med.totalCount,
      refillAt: int.tryParse(_editFields['refillAt']) ?? med.refillAt,
      refillInfo: refillInfo,
      // Empty price field keeps the existing value; a valid number updates it.
      price: priceText.isEmpty ? med.price : double.tryParse(priceText),
      currency: _editFields['currency'],
      color: _editFields['color'],
    );
    state.updateMedDirect(updated);
    setState(() => _editMode = false);
  }

  String _getAutoLabel(int hour) {
    if (hour >= 5 && hour < 11) return 'Morning';
    if (hour >= 11 && hour < 16) return 'Afternoon';
    if (hour >= 16 && hour < 21) return 'Evening';
    return 'Night';
  }



  void _showRitualPicker(int medId, int scheduleIdx, ScheduleEntry s,
      {bool isNew = false}) {
    List<int> selectedDays = List.from(s.days);
    Ritual selectedRitual = s.ritual;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final L = ctx.L;
          return RefinedSheetWrapper(
            title: 'Edit Reminder',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                // Active Days
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text("ACTIVE DAYS",
                      style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          fontSize: 10)),
                ),
                const SizedBox(height: AppSpacing.p12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .asMap()
                      .entries
                      .map((e) {
                    final isSelected = selectedDays.contains(e.key);
                    return AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        setState(() {
                          if (isSelected && selectedDays.length > 1) {
                            selectedDays.remove(e.key);
                          } else if (!isSelected) {
                            selectedDays.add(e.key);
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? L.primary : L.fill.withValues(alpha: 0.3),
                          border: Border.all(
                            color: isSelected ? L.primary : L.border.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(e.value,
                            style: AppTypography.titleMedium.copyWith(
                                color: isSelected ? Colors.white : L.text,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: AppSpacing.p32),
                
                // Meal Ritual
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text("MEAL RITUAL",
                      style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          fontSize: 10)),
                ),
                const SizedBox(height: AppSpacing.p12),
                Flexible(
                  child: ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: Ritual.values.map((r) {
                      final isSelected = selectedRitual == r;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onTap: () {
                          HapticEngine.selection();
                          setState(() => selectedRitual = r);
                        },
                        title: Text(r.displayName,
                            style: AppTypography.bodyLarge.copyWith(
                                color: isSelected ? L.primary : L.text,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: L.primary)
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.p24),
                MedAiCTA(
                  label: 'Save reminder',
                  onTap: () {
                    HapticEngine.success();
                    final updated = s.copyWith(
                        ritual: selectedRitual, days: selectedDays..sort());
                    if (isNew) {
                      context.read<AppState>().addSchedule(medId, updated);
                    } else {
                      context
                          .read<AppState>()
                          .updateSchedule(medId, scheduleIdx, updated);
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCard(String text, IconData icon, AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.p32,
        horizontal: AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: AppColors.pastelSky,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: L.sub.withValues(alpha: 0.55)),
          const SizedBox(height: AppSpacing.p12),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── MODERN UI COMPONENTS ──────────────────────────────────────────

class _DiagnosticCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color tint;
  final AppThemeColors L;
  final Widget? child;

  const _DiagnosticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.L,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: L.text.withValues(alpha: 0.7)),
                const SizedBox(width: AppSpacing.p8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                fontSize: 18,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: AppSpacing.p12),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ModernStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _ModernStockBar(
      {required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            width: double.infinity,
            color: L.fill.withValues(alpha: 0.3),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: 1000.ms,
                  curve: Curves.easeOutQuart,
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * pct,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLow ? L.error : L.text,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final AppThemeColors L;
  const _SectionHeader(
      {required this.label,
      required this.icon,
      this.trailing,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: L.sub),
        const SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _HeaderAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTargetCompact),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: L.border.withValues(alpha: 0.12), width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: L.text),
            const SizedBox(width: AppSpacing.p4),
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 10)),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppThemeColors L;
  const _Metric(
      {required this.label,
      required this.value,
      required this.color,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: AppTypography.displayLarge.copyWith(
              fontSize: 32,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.0)),
      Text(label,
          style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              color: L.sub,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0)),
    ]);
  }
}

class _HistoryMatrix extends StatelessWidget {
  final int medId;
  final Color medColor;
  const _HistoryMatrix({required this.medId, required this.medColor});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final history = context.select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);
    
    // Generate 28 days backwards from today
    final now = DateTime.now();
    List<bool> daysTaken = [];
    for (int i = 27; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final entries = history[dateStr] ?? [];
      final taken = entries.any((e) => e.medId == medId && e.taken);
      daysTaken.add(taken);
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 4.0;
            const columns = 7;
            const rows = 4;
            final itemSize = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

            return SizedBox(
              height: (itemSize * rows) + (spacing * (rows - 1)),
              child: GridView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: 1.0,
                ),
                itemCount: 28,
                itemBuilder: (context, index) {
                  final isTaken = daysTaken[index];
                  return AnimatedContainer(
                    duration: 300.ms,
                    decoration: BoxDecoration(
                      color: isTaken ? medColor : L.fill.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: isTaken
                          ? null
                          : Border.all(
                              color: L.border.withValues(alpha: 0.05),
                              width: 0.5),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.p16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('28 DAY ACTIVITY LOG',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0)),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: L.fill.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: AppSpacing.p4),
                Text('Missed', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub, fontWeight: FontWeight.w500)),
                const SizedBox(width: AppSpacing.p12),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: medColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: AppSpacing.p4),
                Text('Taken', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.text, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final AppThemeColors L;
  final Color tint;

  const _SpecTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.L,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.p12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: L.text.withValues(alpha: 0.7)),
              const SizedBox(width: AppSpacing.p8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p8),
          Text(
            value.isEmpty ? 'Not set' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final AppThemeColors L;
  final bool isLast;
  const _ManagementTile(
      {required this.icon,
      required this.title,
      required this.color,
      required this.iconBg,
      required this.iconColor,
      required this.onTap,
      required this.L,
      this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                          color: L.glassBorder.withValues(alpha: 0.08),
                          width: 0.5))),
          child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p8),
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.p8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              title: Text(title,
                  style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 15,
                      letterSpacing: -0.5)),
              trailing: Icon(Icons.chevron_right_rounded,
                  color: L.sub.withValues(alpha: 0.3), size: 24)),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;
  final AppThemeColors L;
  const _FormSection(
      {required this.label,
      required this.icon,
      required this.children,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.pastelMint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.p8),
            Icon(icon, size: 16, color: L.sub),
            const SizedBox(width: AppSpacing.p8),
            Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.p12),
        Container(
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(
              color: L.border.withValues(alpha: 0.35),
              width: 0.7,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  final AppThemeColors L;
  final TextInputType keyboard;
  final bool isLast;
  const _ModernTextField(
      {required this.label,
      required this.value,
      required this.onChanged,
      required this.L,
      this.keyboard = TextInputType.text,
      this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: L.border.withValues(alpha: 0.05), width: 0.5))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: Text(label,
                  style: AppTypography.labelSmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 13)),
            ),
            const SizedBox(width: AppSpacing.p16),
            Flexible(
              flex: 3,
              child: TextFormField(
                initialValue: value,
                onChanged: onChanged,
                keyboardType: keyboard,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: AppTypography.titleMedium
                    .copyWith(color: L.sub, fontWeight: FontWeight.w500, fontSize: 15),
                decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'None',
                    hintStyle: AppTypography.titleMedium.copyWith(color: L.sub.withValues(alpha: 0.3), fontSize: 15),
                    fillColor: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;
  final AppThemeColors L;

  const _ColorPicker({required this.selectedColor, required this.onColorSelected, required this.L});

  @override
  Widget build(BuildContext context) {
    const colors = ['#FF3B30', '#FF9F0A', '#FFD60A', '#34C759', '#00C7BE', '#32ADE6', '#007AFF', '#5856D6', '#AF52DE', '#FF2D55'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text("ACCENT COLOR", style: AppTypography.labelSmall.copyWith(color: L.sub, fontWeight: FontWeight.w600, letterSpacing: 1.0, fontSize: 10)),
          ),
          const SizedBox(height: AppSpacing.p12),
          SizedBox(
            height: 44,
            child: ListView.separated(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p12),
              itemBuilder: (context, index) {
                final hex = colors[index];
                final isSelected = selectedColor.toUpperCase() == hex.toUpperCase();
                return AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onColorSelected(hex);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hexToColor(hex),
                      border: isSelected ? Border.all(color: L.text, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: hexToColor(hex).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))] : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final AppThemeColors L;

  const _CategoryPicker({required this.selectedCategory, required this.onCategorySelected, required this.L});

  IconData _iconFor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('antibiotic')) return Icons.biotech_rounded;
    if (lower.contains('vitamin')) return Icons.bolt_rounded;
    if (lower.contains('pain')) return Icons.healing_rounded;
    if (lower.contains('sleep')) return Icons.bedtime_rounded;
    if (lower.contains('liquid')) return Icons.water_drop_rounded;
    if (lower.contains('cream')) return Icons.opacity_rounded;
    if (lower.contains('inhaler')) return Icons.air_rounded;
    if (lower.contains('injection')) return Icons.vaccines_rounded;
    return Icons.medication_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const categories = ['Tablet', 'Antibiotic', 'Vitamin', 'Painkiller', 'Sleep', 'Liquid', 'Cream', 'Inhaler', 'Injection'];
    const tints = [
      AppColors.pastelSky,
      AppColors.pastelSun,
      AppColors.pastelMint,
      AppColors.pastelPink,
      AppColors.pastelLilac,
      AppColors.pastelSky,
      AppColors.pastelMint,
      AppColors.pastelLilac,
      AppColors.pastelSun,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text(
              'CATEGORY',
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.p12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.p8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected =
                    selectedCategory.toLowerCase() == cat.toLowerCase();
                return AnimatedPressable(
                  onTap: () {
                    HapticEngine.selection();
                    onCategorySelected(cat);
                  },
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: isSelected ? L.text : tints[index],
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconFor(cat),
                          size: 22,
                          color: isSelected ? L.bg : L.text,
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        Text(
                          cat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? L.bg : L.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Restock Stepper Button ───────────────────────────────────────────
class _RestockBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _RestockBtn(
      {required this.label, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          width: MedAiA11y.minTapTarget,
          height: MedAiA11y.minTapTarget,
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// 2026 PREMIUM ANIMATED LOG DOSE BUTTON
// ══════════════════════════════════════════════════════════════════════
class _AnimatedLogDoseButton extends StatefulWidget {
  final Medicine med;
  const _AnimatedLogDoseButton({required this.med});

  @override
  State<_AnimatedLogDoseButton> createState() => _AnimatedLogDoseButtonState();
}

class _AnimatedLogDoseButtonState extends State<_AnimatedLogDoseButton>
    with SingleTickerProviderStateMixin {
  int _state = 0; // 0: idle, 1: loading, 2: success

  void _handleTap() async {
    if (_state != 0) return;
    HapticEngine.selection();
    setState(() => _state = 1);

    // Premium processing delay to make it feel robust and real
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    HapticEngine.doseTaken();
    final state = context.read<AppState>();
    state.logPrnDose(
      widget.med.id,
      'Flexible Dose',
      TimeOfDay.now().format(context),
    );
    state.showToast('Flexible dose logged ✓');

    setState(() => _state = 2);

    // Reset back to idle after a few seconds
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) setState(() => _state = 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final L = context.L;
    return Semantics(
      button: true,
      enabled: _state == 0,
      label: _state == 0
          ? 'Log flexible dose for ${widget.med.name}'
          : _state == 1
              ? 'Logging dose'
              : 'Dose logged',
      child: AnimatedPressable(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 400),
          curve: Curves.easeOutExpo,
          constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.p16, horizontal: AppSpacing.p12),
          decoration: BoxDecoration(
            color: _state == 2 ? L.success : Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              if (_state == 0)
                BoxShadow(
                  color: L.success.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              if (_state == 2)
                BoxShadow(
                  color: L.success.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              if (_state == 0)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
            border: Border.all(
              color: _state == 2
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInBack,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _state == 0
                ? Row(
                    key: const ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.p4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.black, size: 16),
                      ),
                      const SizedBox(width: AppSpacing.p8),
                      Text(
                        'Log Dose',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : _state == 1
                    ? Row(
                        key: const ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: AppSpacing.p20,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.black87),
                          ),
                          const SizedBox(width: AppSpacing.p12),
                          Text(
                            'Logging...',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('success'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: AppSpacing.p8),
                          Text(
                            'Logged!',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
