import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../models/product_analysis.dart';
import 'package:provider/provider.dart';
import '../../providers/controllers/medication_controller.dart';
import '../../providers/app_state.dart';
import '../paywall/premium_paywall_overlay.dart';

// ══════════════════════════════════════════════════════════
// PRODUCT ANALYSIS SCREEN — Cal AI 2026 Professional
// ══════════════════════════════════════════════════════════
class ProductAnalysisScreen extends StatefulWidget {
  final ProductAnalysis product;
  final File? imageFile;
  const ProductAnalysisScreen({super.key, required this.product, this.imageFile});

  @override
  State<ProductAnalysisScreen> createState() => _ProductAnalysisScreenState();
}

class _ProductAnalysisScreenState extends State<ProductAnalysisScreen>
    with TickerProviderStateMixin {
  int _expertIdx = 0;
  bool _added = false;
  late final ScrollController _scrollCtrl;
  late final AnimationController _heroCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pulseCtrl.value = 0.5;
    });
  }

  Widget _analysisEntrance(Widget child, {Duration? delay}) {
    if (MedAiA11y.reducedMotion(context)) return child;
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppDurations.fast, curve: AppCurves.smooth)
        .slideY(begin: 0.08, end: 0, curve: AppCurves.smooth);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int _computeSafetyScore(ProductAnalysis p) {
    int score = 80;
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
    if (ev.contains('strong') || ev.contains('well-established')) {
      score += 10;
    }
    if (ev.contains('limited') || ev.contains('insufficient')) {
      score -= 10;
    }
    if (ev.contains('high-risk') || ev.contains('dangerous')) {
      score -= 20;
    }
    return score.clamp(10, 98);
  }

  Color get _safetyColor {
    final score = _computeSafetyScore(widget.product);
    if (score >= 75) return AppColors.green;
    if (score >= 50) return AppColors.amber;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final botPad = MediaQuery.of(context).padding.bottom;

    return AppScaffold(
      showAurora: true,
      body: Stack(
        children: [
          if (!MedAiA11y.reducedMotion(context))
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MeshPainter(
                      color: _safetyColor,
                      pulse: _pulseCtrl.value,
                      themeContext: L,
                    ),
                  );
                },
              ),
            ),
          // Main Content
          CustomScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PremiumPageHeader(
                  title: 'Scan result',
                  subtitle: widget.product.category,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                  child: _HeroHeader(
                      product: widget.product,
                      safetyColor: _safetyColor,
                      imageFile: widget.imageFile)),

              // Honesty banner: when the AI wasn't confident, warn before the
              // user trusts the details, and offer a way to re-scan / search.
              if (!widget.product.identified ||
                  widget.product.confidence.toLowerCase() == 'low')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _analysisEntrance(
                      _LowConfidenceBanner(
                        identified: widget.product.identified,
                        onRetry: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

              if (widget.product.allergyAlerts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: _analysisEntrance(
                      _AllergyAlertCard(
                          alerts: widget.product.allergyAlerts),
                    ),
                  ),
                ),

              if (widget.product.childSafetyAlert != null && widget.product.childSafetyAlert!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: _analysisEntrance(
                      _ChildSafetyCard(
                          alertText: widget.product.childSafetyAlert!),
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _SafetyScoreCard(
                        product: widget.product, color: _safetyColor),
                    delay: 150.ms,
                  ),
                ),
              ),

              if (widget.product.allergyRiskLevel != 'None')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _analysisEntrance(
                      _AllergyRiskCard(product: widget.product),
                      delay: 200.ms,
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _QuickFacts(product: widget.product),
                    delay: 250.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _InfoSection(
                      label: 'Overview 📖',
                      icon: Icons.info_outline_rounded,
                      body: widget.product.description,
                    ),
                    delay: 350.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _InfoSection(
                      label: 'How It Works ⚙️',
                      icon: Icons.biotech_rounded,
                      body: widget.product.howItWorks,
                    ),
                    delay: 400.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _BenefitsRisksRow(product: widget.product),
                    delay: 450.ms,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _InteractionPanel(product: widget.product),
                    delay: 500.ms,
                  ),
                ),
              ),

              if (widget.product.expertPerspectives.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _analysisEntrance(
                      _ExpertSection(
                        perspectives: widget.product.expertPerspectives,
                        selectedIdx: _expertIdx,
                        onSelect: (i) => setState(() => _expertIdx = i),
                      ),
                      delay: 550.ms,
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _analysisEntrance(
                    _MetaRow(product: widget.product),
                    delay: 600.ms,
                  ),
                ),
              ),

              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(child: _ScanDisclaimer()),
              ),

              SliverToBoxAdapter(child: SizedBox(height: botPad + 140)),
            ],
          ),

          // High-End Floating Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomActionBar(
              product: widget.product,
              added: _added,
              botPad: botPad,
              onAdd: () {
                if (_added) return;
                HapticEngine.success();
                final newMed = Medicine(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: widget.product.name,
                  category: widget.product.category,
                  courseStartDate: DateTime.now().toIso8601String(),
                  intakeInstructions: widget.product.timing,
                  notes: widget.product.howItWorks,
                  schedule: [
                    ScheduleEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      h: 8,
                      m: 0,
                      label: 'Morning Dose',
                      days: [0, 1, 2, 3, 4, 5, 6],
                      enabled: true,
                      ritual: Ritual.withBreakfast,
                    )
                  ],
                  imageUrl: widget.imageFile?.path,
                  productAnalysis: widget.product,
                );
                if (!context.read<AppState>().canAddMedicine) {
                  PremiumPaywallOverlay.show(context,
                      triggerSource: 'unlimited_meds');
                  return;
                }
                context.read<MedicationController>().addMedicine(newMed);
                setState(() => _added = true);

                context.read<AppState>().showToast('Protocol Tracked Successfully!', type: 'success');
                final navigator = Navigator.of(context);
                Future.delayed(const Duration(milliseconds: 2000), () {
                  if (mounted) {
                    navigator.popUntil((route) => route.isFirst);
                  }
                });
              },
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
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// DYNAMIC MESH BACKGROUND
// ══════════════════════════════════════════════
class _MeshPainter extends CustomPainter {
  final Color color;
  final double pulse;
  final AppThemeColors themeContext;

  _MeshPainter({required this.color, required this.pulse, required this.themeContext});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05 + (pulse * 0.03))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), size.width * 0.6, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.6), size.width * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════
// HERO HEADER
// ══════════════════════════════════════════════
class _HeroHeader extends StatelessWidget {
  final ProductAnalysis product;
  final Color safetyColor;
  final File? imageFile;

  const _HeroHeader({
    required this.product,
    required this.safetyColor,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.3), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageFile != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: safetyColor.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: -5,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms).scale(curve: Curves.easeOutBack, begin: const Offset(0.9, 0.9)),
            ),
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  product.category,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 16),
          // Medicine name (hero 3D)
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displaySmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontSize: 34,
              height: 1.05,
              shadows: [
                Shadow(color: L.text.withValues(alpha: 0.4), blurRadius: 16),
                Shadow(color: safetyColor.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8)),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          // Safety indicator row
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: safetyColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: safetyColor.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)
                  ]
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _safetyLabel(safetyColor),
                style: AppTypography.bodySmall.copyWith(
                  color: safetyColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.1,
                  shadows: [Shadow(color: safetyColor.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '•',
                style: AppTypography.bodySmall.copyWith(color: L.sub),
              ),
              const SizedBox(width: 16),
              Icon(Icons.auto_awesome_rounded, size: 12, color: L.sub),
              const SizedBox(width: 5),
              Text(
                _confidenceLabel(product),
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  /// Honest identification label — never claims "verified". Reflects the AI's
  /// self-reported confidence so an uncertain result reads as an estimate.
  String _confidenceLabel(ProductAnalysis p) {
    if (!p.identified) return 'Not confirmed';
    switch (p.confidence.toLowerCase()) {
      case 'high':
        return 'AI estimate · high confidence';
      case 'medium':
        return 'AI estimate · medium confidence';
      default:
        return 'AI estimate · low confidence';
    }
  }

  String _safetyLabel(Color c) {
    if (c == AppColors.green) return 'Highly Safe';
    if (c == AppColors.amber) return 'Moderate Risk';
    return 'High Risk';
  }
}

// ══════════════════════════════════════════════
// SAFETY SCORE GAUGE
// ══════════════════════════════════════════════
class _SafetyScoreCard extends StatelessWidget {
  final ProductAnalysis product;
  final Color color;

  const _SafetyScoreCard({required this.product, required this.color});

  int _score(ProductAnalysis p) {
    int s = 80;
    for (final se in p.sideEffects) {
      if (se.severity == 'High') {
        s -= 10;
      } else if (se.severity == 'Medium') {
        s -= 4;
      } else {
        s -= 1;
      }
    }
    s -= (p.medicineInteractions.length * 3).clamp(0, 20);
    if (p.allergyRiskLevel == 'High') {
      s -= 20;
    } else if (p.allergyRiskLevel == 'Medium') {
      s -= 10;
    }
    final ev = p.scientificEvidence.toLowerCase();
    if (ev.contains('strong') || ev.contains('well-established')) {
      s += 10;
    }
    if (ev.contains('limited') || ev.contains('insufficient')) {
      s -= 10;
    }
    if (ev.contains('high-risk') || ev.contains('dangerous')) {
      s -= 20;
    }
    return s.clamp(10, 98);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final score = _score(product);

    return Semantics(
      label: 'Safety rating $score percent. ${_scoreDescription(score)}',
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: MedAiDepthCard(
          accentGlow: true,
          padding: const EdgeInsets.all(28),
          radius: 28,
          child: Row(
            children: [
              // Glowing Animated Score Ring
              SizedBox(
                width: 90,
                height: 90,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: score / 100),
                  duration: MedAiA11y.motion(
                      context, const Duration(milliseconds: 2000)),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(90, 90),
                          painter: _ArcPainter(
                            value: val,
                            color: color,
                            bg: L.border.withValues(alpha: 0.2),
                            strokeWidth: 10,
                          ),
                        ),
                        Text(
                          '${(val * 100).toInt()}',
                          style: AppTypography.displaySmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                            letterSpacing: -1.0,
                            shadows: [
                              Shadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 20)
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_rounded, color: L.sub, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Safety rating',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scoreDescription(score),
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 10)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: score / 100),
                          duration: MedAiA11y.motion(
                              context, const Duration(milliseconds: 2000)),
                          curve: Curves.easeOutExpo,
                          builder: (_, val, __) => LinearProgressIndicator(
                            value: val,
                            minHeight: 8,
                            backgroundColor: L.fill,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _scoreDescription(int score) {
    if (score >= 80) return 'Optimal safety profile for general use.';
    if (score >= 60) return 'Generally safe; monitor minor effects.';
    if (score >= 40) return 'Caution advised. Consult physician.';
    return 'High risk interactions detected.';
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color bg;
  final double strokeWidth;

  const _ArcPainter({
    required this.value,
    required this.color,
    required this.bg,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background Arc
    final bgP = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    // Glow Layer
    final glowP = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeCap = StrokeCap.round;

    // Foreground Arc
    final fgP = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, 6.283, false, bgP);
    if (value > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.283 * value, false, glowP);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.283 * value, false, fgP);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.value != value;
}

// ══════════════════════════════════════════════
// QUICK FACTS BENTO GRID
// ══════════════════════════════════════════════
class _QuickFacts extends StatelessWidget {
  final ProductAnalysis product;
  const _QuickFacts({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final facts = [
      (Icons.schedule_rounded, 'Timing', product.timing.isNotEmpty ? product.timing : 'As directed'),
      (Icons.verified_rounded, 'Halal', product.halalStatus.isNotEmpty ? product.halalStatus : 'N/A'),
      (Icons.science_rounded, 'Evidence', product.scientificEvidence.isNotEmpty ? _shortEvidence(product.scientificEvidence) : 'N/A'),
    ];

    return Row(
      children: facts.asMap().entries.map((e) {
        final idx = e.key;
        final f = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 12),
            child: MedAiGlass(
              padding: const EdgeInsets.all(18),
              radius: 20,
              onTap: () => HapticEngine.selection(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: L.sub.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: L.sub.withValues(alpha: 0.2), blurRadius: 10)
                      ],
                    ),
                    child: Icon(f.$1, size: 18, color: L.sub),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    f.$2,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f.$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _shortEvidence(String s) {
    final words = s.split(' ');
    return words.take(4).join(' ') + (words.length > 4 ? '…' : '');
  }
}

// ══════════════════════════════════════════════
// ANIMATED INFO SECTION
// ══════════════════════════════════════════════
class _InfoSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final String body;

  const _InfoSection({required this.label, required this.icon, required this.body});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      padding: const EdgeInsets.all(24),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: L.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: L.accent.withValues(alpha: 0.2), blurRadius: 10)
                  ],
                ),
                child: Icon(icon, size: 18, color: L.accent),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.8,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BENEFITS & RISKS ROW
// ══════════════════════════════════════════════
class _BenefitsRisksRow extends StatelessWidget {
  final ProductAnalysis product;
  const _BenefitsRisksRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ListCard(
            title: 'Benefits',
            icon: Icons.thumb_up_alt_rounded,
            items: product.benefits,
            accent: AppColors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SideEffectsCard(
            title: 'Side effects',
            icon: Icons.warning_amber_rounded,
            items: product.sideEffects,
            accent: AppColors.red,
          ),
        ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color accent;

  const _ListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      padding: const EdgeInsets.all(20),
      radius: 24,
      tint: accent.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: accent.withValues(alpha: 0.4), blurRadius: 10)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.take(5).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: accent.withValues(alpha: 0.8),
                                blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.5,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// INTERACTION PANEL
// ══════════════════════════════════════════════
class _InteractionPanel extends StatelessWidget {
  final ProductAnalysis product;
  const _InteractionPanel({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: L.amber.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: L.amber.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: L.amber),
                  const SizedBox(width: 12),
                  Text(
                    'Interactions',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.1,
                      shadows: [
                        Shadow(color: L.amber.withValues(alpha: 0.5), blurRadius: 15)
                      ]
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (product.foodInteractions.isNotEmpty)
                _InteractionGroup(
                  icon: Icons.restaurant_rounded,
                  label: 'Food & lifestyle',
                  color: L.amber,
                  items: product.foodInteractions,
                ),
              if (product.medicineInteractions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _InteractionGroup(
                  icon: Icons.medication_rounded,
                  label: 'Drug conflicts',
                  color: AppColors.red,
                  items: product.medicineInteractions,
                ),
              ],
              if (product.foodInteractions.isEmpty && product.medicineInteractions.isEmpty)
                Text(
                  'No major interactions reported. Always consult a professional.',
                  style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.6, fontStyle: FontStyle.italic, fontSize: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<String> items;

  const _InteractionGroup({
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(
               label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                            fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.flash_on_rounded, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        i,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.6,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// EXPERT PERSPECTIVES SOCIAL STYLE
// ══════════════════════════════════════════════
class _ExpertSection extends StatelessWidget {
  final List<ExpertPerspective> perspectives;
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _ExpertSection({
    required this.perspectives,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final safe = selectedIdx.clamp(0, perspectives.length - 1);
    final expert = perspectives[safe];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: L.border.withValues(alpha: 0.4), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_rounded, size: 20, color: L.accent),
                  const SizedBox(width: 12),
                  Text(
                    'Expert perspectives',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatars
              SizedBox(
                height: 80,
                child: ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: perspectives.length,
                  itemBuilder: (_, i) {
                    final isSelected = safe == i;
                    final p = perspectives[i];
                    return AnimatedPressable(
                      onTap: () {
                        HapticEngine.selection();
                        onSelect(i);
                      },
                      child: AnimatedContainer(
                        duration: 300.ms,
                        curve: Curves.easeOutCirc,
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? L.accent.withValues(alpha: 0.15) : L.fill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? L.accent.withValues(alpha: 0.6) : L.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected ? AppShadows.glow(L.accent, intensity: 0.2) : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text(
                              p.role,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? L.accent : L.sub,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Quote
              AnimatedSwitcher(
                duration: 400.ms,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(safe),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: L.accent.withValues(alpha: 0.4),
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          expert.explanation,
                          style: AppTypography.bodyMedium.copyWith(
                            color: L.text,
                            height: 1.7,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
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

// ══════════════════════════════════════════════
// META ROW
// ══════════════════════════════════════════════
class _MetaRow extends StatelessWidget {
  final ProductAnalysis product;
  const _MetaRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final rows = [
      (Icons.schedule_rounded, 'Timing Protocol', product.timing),
      (Icons.verified_rounded, 'Halal Certification', product.halalStatus),
      (Icons.science_rounded, 'Scientific Grounding', product.scientificEvidence),
    ];

    return Column(
      children: rows.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.0),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: L.fill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r.$1, size: 20, color: L.sub),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$2,
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.$3.isNotEmpty ? r.$3 : 'N/A',
                        style: AppTypography.bodySmall.copyWith(
                          color: L.text,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }
}

// ══════════════════════════════════════════════
// FLOATING ACTION BAR
// ══════════════════════════════════════════════
class _BottomActionBar extends StatelessWidget {
  final ProductAnalysis product;
  final bool added;
  final double botPad;
  final VoidCallback onAdd;
  final VoidCallback onImpact;
  final VoidCallback onChat;

  const _BottomActionBar({
    required this.product,
    required this.added,
    required this.botPad,
    required this.onAdd,
    required this.onImpact,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final trackLabel = added ? 'Protocol tracked' : 'Track protocol';

    Widget trackButton = AnimatedContainer(
      duration: MedAiA11y.motion(context, 400.ms),
      curve: Curves.easeOutBack,
      constraints: const BoxConstraints(minHeight: MedAiA11y.minTapTarget),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: added
              ? [L.green, L.green.withValues(alpha: 0.8)]
              : [L.text, L.text.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: added
            ? AppShadows.glow(L.green, intensity: 0.5)
            : AppShadows.glow(L.text, intensity: 0.2),
        border: Border.all(
          color: L.bg.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              added ? Icons.task_alt_rounded : Icons.add_circle_rounded,
              color: L.bg,
              size: 24,
            ).animate(target: added ? 1 : 0).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                curve: Curves.elasticOut,
                duration: reduceMotion ? 0.ms : 800.ms),
            const SizedBox(width: 12),
            Text(
              trackLabel,
              style: AppTypography.labelMedium.copyWith(
                color: L.bg,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
    final impactIcon = Icon(Icons.biotech_rounded, color: L.accent, size: 26);
    final chatIcon =
        Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, botPad + 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                L.bg.withValues(alpha: 0.0),
                L.bg.withValues(alpha: 0.85),
                L.bg,
              ],
            ),
          ),
          child: MedAiGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            radius: 32,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Semantics(
                    button: true,
                    label: trackLabel,
                    child: AnimatedPressable(
                      onTap: onAdd,
                      child: trackButton,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Semantics(
                  button: true,
                  label: 'Organ impact',
                  child: AnimatedPressable(
                    onTap: onImpact,
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            L.accent.withValues(alpha: 0.25),
                            L.accent.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: L.accent.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: AppShadows.glow(L.accent, intensity: 0.3),
                      ),
                      child: Center(child: impactIcon),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: 'AI assistant',
                  child: AnimatedPressable(
                    onTap: onChat,
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.3),
                            AppColors.accent.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6),
                            width: 1.5),
                        boxShadow:
                            AppShadows.glow(AppColors.accent, intensity: 0.4),
                      ),
                      child: Center(child: chatIcon),
                    ),
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

// ══════════════════════════════════════════════
// ALLERGY ALERT CARD
// ══════════════════════════════════════════════
class _AllergyAlertCard extends StatelessWidget {
  final List<String> alerts;
  const _AllergyAlertCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      label: 'Critical allergy alert. ${alerts.length} allergens detected.',
      child: MedAiGlass(
        padding: const EdgeInsets.all(24),
        radius: 24,
        tint: AppColors.red.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Critical allergy alert',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This product contains ingredients that match your known allergies. Do not consume without consulting a physician.',
              style: AppTypography.bodySmall.copyWith(
                color: L.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...alerts.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4, right: 8),
                        child: Icon(Icons.close_rounded,
                            color: AppColors.red, size: 16),
                      ),
                      Expanded(
                        child: Text(
                          a,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// PEDIATRIC SAFETY CARD
// ══════════════════════════════════════════════
class _ChildSafetyCard extends StatelessWidget {
  final String alertText;
  const _ChildSafetyCard({required this.alertText});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Semantics(
      label: 'Pediatric safety alert. $alertText',
      child: MedAiGlass(
        padding: const EdgeInsets.all(24),
        radius: 24,
        tint: AppColors.amber.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.child_care_rounded,
                      color: AppColors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pediatric safety alert',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4, right: 8),
                  child: Icon(Icons.shield_rounded,
                      color: AppColors.amber, size: 16),
                ),
                Expanded(
                  child: Text(
                    alertText,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SIDE EFFECTS CARD
// ══════════════════════════════════════════════
class _SideEffectsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<SideEffect> items;
  final Color accent;

  const _SideEffectsCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return MedAiGlass(
      padding: const EdgeInsets.all(20),
      radius: 24,
      tint: accent.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: accent.withValues(alpha: 0.4), blurRadius: 10)
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.take(5).map((item) {
            Color sevColor = AppColors.green;
            if (item.severity == 'Medium') sevColor = AppColors.amber;
            if (item.severity == 'High') sevColor = AppColors.red;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sevColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: sevColor.withValues(alpha: 0.8),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.effect,
                      style: AppTypography.bodySmall.copyWith(
                        color: L.sub,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ALLERGY RISK CARD
// ══════════════════════════════════════════════
class _AllergyRiskCard extends StatelessWidget {
  final ProductAnalysis product;
  const _AllergyRiskCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    Color alertColor = AppColors.green;
    IconData alertIcon = Icons.check_circle_outline;
    String alertLabel = 'Allergy Safe';
    
    if (product.allergyRiskLevel == 'Medium') {
      alertColor = AppColors.amber;
      alertIcon = Icons.warning_amber_rounded;
      alertLabel = 'Moderate Allergy Risk';
    } else if (product.allergyRiskLevel == 'High') {
      alertColor = AppColors.red;
      alertIcon = Icons.error_outline_rounded;
      alertLabel = 'High Allergy Risk';
    }
    
    return Semantics(
      label: 'Allergy risk alert. $alertLabel',
      child: MedAiGlass(
        padding: const EdgeInsets.all(24),
        radius: 24,
        tint: alertColor.withValues(alpha: 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alertIcon, color: alertColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  alertLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: alertColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            if (product.allergyAlerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...product.allergyAlerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 8),
                      child: Icon(Icons.shield_rounded, color: alertColor, size: 16),
                    ),
                    Expanded(
                      child: Text(
                        alert,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// LOW-CONFIDENCE / NOT-IDENTIFIED HONESTY BANNER
// ══════════════════════════════════════════════
class _LowConfidenceBanner extends StatelessWidget {
  final bool identified;
  final VoidCallback onRetry;

  const _LowConfidenceBanner({required this.identified, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final title = identified
        ? "We're not fully sure about this one"
        : "We couldn't confidently identify this";
    final body = identified
        ? 'The details below are a low-confidence estimate. Double-check the name against the packaging before relying on them.'
        : 'This may be a guess. Retake a clearer photo, or search by the medicine name for a reliable result.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.bodySmall
                      .copyWith(color: L.sub, height: 1.4),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    HapticEngine.selection();
                    onRetry();
                  },
                  child: Semantics(
                    button: true,
                    label: 'Retake or search again',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            size: 16, color: AppColors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Retake or search again',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.amber,
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
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// PERSISTENT MEDICAL DISCLAIMER (always shown)
// ══════════════════════════════════════════════
class _ScanDisclaimer extends StatelessWidget {
  const _ScanDisclaimer();

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.health_and_safety_outlined, size: 16, color: L.sub),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI-generated information — it can be incomplete or wrong. '
            'Always verify with the packaging, your pharmacist, or your doctor '
            'before taking or changing any medication.',
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              height: 1.4,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
