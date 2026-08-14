import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/scan_safety_mapper.dart';
import '../../models/product_analysis.dart';
import '../../providers/app_state.dart';
import '../../providers/controllers/medication_controller.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/modals/scan_success_sheet.dart';
import '../paywall/premium_paywall_overlay.dart';
import '../scan/widgets/premium_scan_result_chrome.dart';

/// Premium scan result — 100% redesigned to match reference wellness UI.
class ProductAnalysisScreen extends StatefulWidget {
  final ProductAnalysis product;
  final File? imageFile;

  const ProductAnalysisScreen({
    super.key,
    required this.product,
    this.imageFile,
  });

  @override
  State<ProductAnalysisScreen> createState() => _ProductAnalysisScreenState();
}

class _ProductAnalysisScreenState extends State<ProductAnalysisScreen> {
  int _expertIdx = 0;
  bool _added = false;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _enter(Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
        .slideY(begin: 0.05, end: 0, curve: AppCurves.emilOut);
  }

  int _safetyScore(ProductAnalysis p) {
    var score = 80;
    for (final se in p.sideEffects) {
      if (se.severity == 'High') {
        score -= 10;
      } else if (se.severity == 'Medium') {
        score -= 4;
      } else {
        score -= 1;
      }
    }
    score -= (p.medicineInteractions.length * 3).clamp(0, 20);
    if (p.allergyRiskLevel == 'High') {
      score -= 20;
    } else if (p.allergyRiskLevel == 'Medium') {
      score -= 10;
    }
    final ev = p.scientificEvidence.toLowerCase();
    if (ev.contains('strong') || ev.contains('well-established')) score += 10;
    if (ev.contains('limited') || ev.contains('insufficient')) score -= 10;
    if (ev.contains('high-risk') || ev.contains('dangerous')) score -= 20;
    return score.clamp(10, 98);
  }

  Color get _safetyColor {
    final score = _safetyScore(widget.product);
    if (score >= 75) return AppColors.sageGreen;
    if (score >= 50) return AppColors.amber;
    return const Color(0xFFC45C5C);
  }

  int get _confidencePct {
    switch (widget.product.confidence.toLowerCase()) {
      case 'high':
        return 92;
      case 'medium':
        return 74;
      default:
        return widget.product.identified ? 58 : 38;
    }
  }

  Future<void> _trackMedicine() async {
    if (_added) return;
    HapticEngine.selection();
    final appState = context.read<AppState>();
    if (!appState.canAddMedicine) {
      await PremiumPaywallOverlay.show(context,
          triggerSource: 'unlimited_meds');
      if (!mounted) return;
      return;
    }

    final newMed = Medicine(
      id: DateTime.now().millisecondsSinceEpoch,
      name: widget.product.name,
      category: widget.product.category.isNotEmpty
          ? widget.product.category
          : 'General',
      courseStartDate: DateTime.now().toIso8601String().substring(0, 10),
      intakeInstructions: widget.product.timing,
      notes: widget.product.howItWorks,
      schedule: [
        ScheduleEntry(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          h: 8,
          m: 0,
          label: 'Morning Dose',
          days: const [0, 1, 2, 3, 4, 5, 6],
          enabled: true,
          ritual: Ritual.withBreakfast,
        )
      ],
      imageUrl: widget.imageFile?.path,
      productAnalysis: widget.product,
      aiSafetyProfile: safetyProfileFromProductAnalysis(widget.product),
    );

    await context.read<MedicationController>().addMedicine(newMed);
    if (!mounted) return;
    setState(() => _added = true);
    appState.showToast("You're set — ${newMed.name} is tracking",
        type: 'success');

    final next = await ScanSuccessSheet.show(context, med: newMed);
    if (!mounted) return;
    if (next == 'detail') {
      appState.setPendingDetailMedId(newMed.id);
    } else {
      appState.clearPendingDetailMedId();
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final botPad = MediaQuery.paddingOf(context).bottom;
    final p = widget.product;
    final score = _safetyScore(p);
    final category = p.category.isNotEmpty ? p.category : 'Medicine';

    return AppScaffold(
      showAurora: false,
      backgroundColor: L.bg,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _TopBar(onBack: () => Navigator.pop(context))),

              SliverPadding(
                padding: ScanResultChrome.pagePad,
                sliver: SliverToBoxAdapter(
                  child: _enter(
                    _PhotoBlock(
                      imageFile: widget.imageFile,
                      category: category,
                    ),
                    delay: 40.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p20,
                  AppSpacing.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _enter(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Know your medicine',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accentDeep,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        Text(
                          p.name,
                          style: AppTypography.displaySmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            letterSpacing: -0.8,
                            height: 1.08,
                          ),
                        ),
                        if (p.whyTakeIt.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.p8),
                          Text(
                            p.whyTakeIt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              color: L.sub,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                    delay: 60.ms,
                  ),
                ),
              ),

              if (!p.identified || p.confidence.toLowerCase() == 'low')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p16,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      ScanSoftSection(
                        title: p.identified
                            ? "We're not fully sure"
                            : "Couldn't confirm this scan",
                        subtitle: p.identified
                            ? 'Double-check packaging before relying on details.'
                            : 'Retake a clearer photo or search by name.',
                        tint: AppColors.pastelSun,
                        icon: Icons.info_outline_rounded,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AnimatedPressable(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.max),
                              ),
                              child: Text(
                                'Scan again',
                                style: AppTypography.labelMedium.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      delay: 80.ms,
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p16,
                  AppSpacing.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _enter(
                    ScanConfidenceHero(
                      percent: score,
                      accent: _safetyColor,
                      title: 'Safety score',
                      caption:
                          'Based on interactions, side effects & evidence — ${p.scientificEvidence.isNotEmpty ? p.scientificEvidence : 'AI safety estimate'}.',
                    ),
                    delay: 100.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p12,
                  AppSpacing.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _enter(
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.p16),
                      decoration: ScanResultChrome.whiteCard(L),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI match',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: L.sub,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_confidencePct% confidence',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: L.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.pastelMint,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.max),
                            ),
                            child: Text(
                              category,
                              style: AppTypography.labelSmall.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    delay: 120.ms,
                  ),
                ),
              ),

              if (p.allergyAlerts.isNotEmpty ||
                  (p.childSafetyAlert?.isNotEmpty ?? false) ||
                  (p.pregnancyAlert?.isNotEmpty ?? false) ||
                  (p.skincareNotes?.isNotEmpty ?? false))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p24,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safety first',
                            style: AppTypography.headlineSmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p4),
                          Text(
                            'Important alerts — know before you take.',
                            style: AppTypography.bodySmall
                                .copyWith(color: L.sub),
                          ),
                          const SizedBox(height: AppSpacing.p16),
                          if (p.allergyAlerts.isNotEmpty) ...[
                            ScanSoftSection(
                              title: 'Allergy alerts',
                              tint: AppColors.pastelPink,
                              icon: Icons.warning_amber_rounded,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final a in p.allergyAlerts)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppSpacing.p8),
                                      child: Text(
                                        a,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                          color: L.text,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p12),
                          ],
                          if (p.childSafetyAlert?.isNotEmpty ?? false) ...[
                            ScanSoftSection(
                              title: 'Child safety',
                              subtitle:
                                  'Clear guidance to protect little ones.',
                              tint: AppColors.pastelSun,
                              icon: Icons.child_care_rounded,
                              child: Text(
                                p.childSafetyAlert!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: L.text,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p12),
                          ],
                          if (p.pregnancyAlert?.isNotEmpty ?? false) ...[
                            ScanSoftSection(
                              title: 'Pregnancy & nursing',
                              subtitle:
                                  'Decide with confidence — ask your clinician.',
                              tint: AppColors.pastelMint,
                              icon: Icons.pregnant_woman_rounded,
                              child: Text(
                                p.pregnancyAlert!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: L.text,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.p12),
                          ],
                          if (p.skincareNotes?.isNotEmpty ?? false)
                            ScanSoftSection(
                              title: 'Skincare notes',
                              subtitle: 'Patch-test tips for careful routines.',
                              tint: AppColors.pastelMint,
                              icon: Icons.spa_rounded,
                              child: Text(
                                p.skincareNotes!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: L.text,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      delay: 140.ms,
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p24,
                  AppSpacing.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _enter(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick insights',
                          style: AppTypography.headlineSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        Text(
                          'Based on your needs — tap through to understand more.',
                          style:
                              AppTypography.bodySmall.copyWith(color: L.sub),
                        ),
                        const SizedBox(height: AppSpacing.p16),
                        ScanInsightGrid(
                          tiles: [
                            ScanInsightTile(
                              label: 'Timing',
                              value: p.timing.isNotEmpty
                                  ? p.timing
                                  : 'As directed',
                              tint: AppColors.pastelSky,
                              icon: Icons.schedule_rounded,
                            ),
                            ScanInsightTile(
                              label: 'Evidence',
                              value: p.scientificEvidence.isNotEmpty
                                  ? (p.scientificEvidence.length > 42
                                      ? '${p.scientificEvidence.substring(0, 42)}…'
                                      : p.scientificEvidence)
                                  : 'See overview',
                              tint: AppColors.pastelMint,
                              icon: Icons.science_outlined,
                            ),
                            ScanInsightTile(
                              label: 'Halal',
                              value: p.halalStatus.isNotEmpty
                                  ? p.halalStatus
                                  : 'Unknown',
                              tint: AppColors.pastelSun,
                              icon: Icons.verified_outlined,
                            ),
                            ScanInsightTile(
                              label: 'Allergy risk',
                              value: p.allergyRiskLevel.isNotEmpty
                                  ? p.allergyRiskLevel
                                  : 'None',
                              tint: AppColors.pastelMint,
                              icon: Icons.health_and_safety_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                    delay: 160.ms,
                  ),
                ),
              ),

              if (p.sideEffects.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p24,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Side-effect map',
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p12),
                          ScanBubbleRow(
                            items: [
                              for (var i = 0;
                                  i < p.sideEffects.take(6).length;
                                  i++)
                                (
                                  label: p.sideEffects[i].effect,
                                  color: _severityTint(
                                      p.sideEffects[i].severity, i),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.p12),
                          for (final se in p.sideEffects.take(4))
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.p8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _severityTint(se.severity, 0),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.p8),
                                  Expanded(
                                    child: Text(
                                      '${se.effect} · ${se.severity}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: L.sub,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      delay: 180.ms,
                    ),
                  ),
                ),

              if (p.description.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p20,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      ScanSoftSection(
                        title: 'Overview',
                        tint: AppColors.pastelSky,
                        icon: Icons.info_outline_rounded,
                        child: Text(
                          p.description,
                          style: AppTypography.bodyMedium
                              .copyWith(color: L.sub, height: 1.5),
                        ),
                      ),
                      delay: 200.ms,
                    ),
                  ),
                ),

              if (p.howItWorks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p12,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      ScanSoftSection(
                        title: 'How this supports you',
                        tint: AppColors.pastelMint,
                        icon: Icons.biotech_rounded,
                        child: Text(
                          p.howItWorks,
                          style: AppTypography.bodyMedium
                              .copyWith(color: L.sub, height: 1.5),
                        ),
                      ),
                      delay: 220.ms,
                    ),
                  ),
                ),

              if (p.benefits.isNotEmpty ||
                  p.foodInteractions.isNotEmpty ||
                  p.medicineInteractions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p12,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      Column(
                        children: [
                          if (p.benefits.isNotEmpty)
                            ScanSoftSection(
                              title: 'Benefits',
                              tint: AppColors.pastelMint,
                              icon: Icons.favorite_outline_rounded,
                              child: _bulletList(p.benefits, L),
                            ),
                          if (p.benefits.isNotEmpty &&
                              (p.foodInteractions.isNotEmpty ||
                                  p.medicineInteractions.isNotEmpty))
                            const SizedBox(height: AppSpacing.p12),
                          if (p.foodInteractions.isNotEmpty ||
                              p.medicineInteractions.isNotEmpty)
                            ScanSoftSection(
                              title: 'Interactions',
                              subtitle: 'Food & medicine — check before stacking.',
                              tint: AppColors.pastelSun,
                              icon: Icons.link_off_rounded,
                              child: _bulletList([
                                ...p.foodInteractions.map((e) => 'Food · $e'),
                                ...p.medicineInteractions
                                    .map((e) => 'Med · $e'),
                              ], L),
                            ),
                        ],
                      ),
                      delay: 240.ms,
                    ),
                  ),
                ),

              if (p.expertPerspectives.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.p24,
                    AppSpacing.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _enter(
                      _ExpertBlock(
                        perspectives: p.expertPerspectives,
                        selectedIdx: _expertIdx,
                        onSelect: (i) => setState(() => _expertIdx = i),
                      ),
                      delay: 260.ms,
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.p24,
                  AppSpacing.gutter,
                  0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: Text(
                    'AI identification — always verify with your pharmacist or prescriber.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF9AA0A6),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: botPad + 140)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScanFloatingBar(
              bottomPad: botPad,
              child: _Dock(
                added: _added,
                onAdd: _trackMedicine,
                onImpact: () {
                  HapticEngine.heavyImpact();
                  context.push(AppRoutes.impactVisualizer);
                },
                onChat: () {
                  HapticEngine.selection();
                  context.push(
                    AppRoutes.analysisChat,
                    extra: ProductChatRouteArgs(product: widget.product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _severityTint(String severity, int i) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.pastelPink;
      case 'medium':
        return AppColors.pastelSun;
      default:
        const soft = [
          AppColors.pastelSky,
          AppColors.pastelMint,
          AppColors.pastelMint,
        ];
        return soft[i % soft.length];
    }
  }

  Widget _bulletList(List<String> items, AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.p8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodyMedium
                        .copyWith(color: L.sub, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        top + AppSpacing.p8,
        AppSpacing.gutter,
        AppSpacing.p12,
      ),
      child: Row(
        children: [
          AnimatedPressable(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Icon(Icons.arrow_back_rounded, color: L.text, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan result',
                  style: AppTypography.titleMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Smart · trusted · built for you',
                  style: AppTypography.bodySmall.copyWith(color: L.sub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  final File? imageFile;
  final String category;
  const _PhotoBlock({required this.imageFile, required this.category});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.pastelSky,
              child: imageFile != null
                  ? Image.file(imageFile!, fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        Icons.medication_rounded,
                        size: 64,
                        color: L.sub.withValues(alpha: 0.4),
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.38),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: L.text),
                    const SizedBox(width: 6),
                    Text(
                      category,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
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
  }
}

class _ExpertBlock extends StatelessWidget {
  final List<ExpertPerspective> perspectives;
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _ExpertBlock({
    required this.perspectives,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final idx = selectedIdx.clamp(0, perspectives.length - 1);
    final current = perspectives[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expert perspectives',
          style: AppTypography.headlineSmall.copyWith(
            color: L.text,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: perspectives.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = i == idx;
              return AnimatedPressable(
                onTap: () => onSelect(i),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? L.text : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? L.text
                          : L.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${perspectives[i].icon} ${perspectives[i].role}',
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? Colors.white : L.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.p12),
        ScanSoftSection(
          title: current.role,
          tint: AppColors.pastelMint,
          child: Text(
            current.explanation,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Dock extends StatelessWidget {
  final bool added;
  final VoidCallback onAdd;
  final VoidCallback onImpact;
  final VoidCallback onChat;

  const _Dock({
    required this.added,
    required this.onAdd,
    required this.onImpact,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _roundBtn(icon: Icons.monitor_heart_outlined, onTap: onImpact, L: L),
          const SizedBox(width: 8),
          _roundBtn(icon: Icons.chat_bubble_outline_rounded, onTap: onChat, L: L),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedPressable(
              onTap: onAdd,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: added
                      ? null
                      : const LinearGradient(
                          colors: [AppColors.lime, AppColors.limeDeep],
                        ),
                  color: added ? AppColors.sageGreen : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: added
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.limeDeep.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      added ? Icons.check_rounded : Icons.add_rounded,
                      color: AppColors.limeInk,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      added ? 'Added' : 'Track medicine',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.limeInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required VoidCallback onTap,
    required AppThemeColors L,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0EA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.inkStrong, size: 20),
      ),
    );
  }
}
