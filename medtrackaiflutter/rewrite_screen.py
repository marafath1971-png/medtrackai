import os

new_code = r'''import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../models/product_analysis.dart';
import '../visualizer/impact_visualizer_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/controllers/medication_controller.dart';
import 'product_chat_screen.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/medicine.dart';

// ══════════════════════════════════════════════════════════
// PRODUCT ANALYSIS SCREEN — Cal AI 2026 Professional
// ══════════════════════════════════════════════════════════
class ProductAnalysisScreen extends StatefulWidget {
  final ProductAnalysis product;
  const ProductAnalysisScreen({super.key, required this.product});

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
    )..repeat(reverse: true);
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
    score -= (p.sideEffects.length * 4).clamp(0, 30);
    score -= (p.medicineInteractions.length * 3).clamp(0, 20);
    final ev = p.scientificEvidence.toLowerCase();
    if (ev.contains('strong') || ev.contains('well-established')) score += 10;
    if (ev.contains('limited') || ev.contains('insufficient')) score -= 10;
    if (ev.contains('high-risk') || ev.contains('dangerous')) score -= 20;
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
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // Dynamic Mesh Background
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
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: _HeroHeader(
                      product: widget.product,
                      topPad: topPad,
                      safetyColor: _safetyColor)),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SafetyScoreCard(
                          product: widget.product, color: _safetyColor)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 150.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _QuickFacts(product: widget.product)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 250.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InfoSection(
                    label: 'Overview 📖',
                    icon: Icons.info_outline_rounded,
                    body: widget.product.description,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 350.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InfoSection(
                    label: 'How It Works ⚙️',
                    icon: Icons.biotech_rounded,
                    body: widget.product.howItWorks,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _BenefitsRisksRow(product: widget.product)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 450.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InteractionPanel(product: widget.product)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
              ),

              if (widget.product.expertPerspectives.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ExpertSection(
                      perspectives: widget.product.expertPerspectives,
                      selectedIdx: _expertIdx,
                      onSelect: (i) => setState(() => _expertIdx = i),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 550.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MetaRow(product: widget.product)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                ),
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
                  productAnalysis: widget.product,
                );
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ImpactVisualizerScreen()));
              },
              onChat: () {
                HapticEngine.selection();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ProductChatScreen(product: widget.product)));
              },
            ),
          ),

          // Frosted Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: topPad + 56,
                  color: L.bg.withValues(alpha: 0.5),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticEngine.selection();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: L.card.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: L.text, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
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
  final AppThemeExtension themeContext;

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
  final double topPad;
  final Color safetyColor;

  const _HeroHeader({
    required this.product,
    required this.topPad,
    required this.safetyColor,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPad + 76, 24, 32),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.3), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Glass Category Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      blurRadius: 16,
                    )
                  ]
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accent)
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      product.category.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.05, end: 0),
          const SizedBox(height: 16),
          // Medicine name (hero 3D)
          Text(
            product.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.displaySmall.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
              fontSize: 38,
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
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds),
              const SizedBox(width: 12),
              Text(
                _safetyLabel(safetyColor).toUpperCase(),
                style: AppTypography.bodySmall.copyWith(
                  color: safetyColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: safetyColor.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '•',
                style: AppTypography.bodySmall.copyWith(color: L.sub),
              ),
              const SizedBox(width: 16),
              Text(
                'AI VERIFIED',
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2.0,
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
    s -= (p.sideEffects.length * 4).clamp(0, 30);
    s -= (p.medicineInteractions.length * 3).clamp(0, 20);
    final ev = p.scientificEvidence.toLowerCase();
    if (ev.contains('strong') || ev.contains('well-established')) s += 10;
    if (ev.contains('limited') || ev.contains('insufficient')) s -= 10;
    if (ev.contains('high-risk') || ev.contains('dangerous')) s -= 20;
    return s.clamp(10, 98);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final score = _score(product);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Row(
            children: [
              // Glowing Animated Score Ring
              SizedBox(
                width: 90,
                height: 90,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: score / 100),
                  duration: const Duration(milliseconds: 2000),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: -1.0,
                            shadows: [
                              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 20)
                            ]
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
                          'SAFETY RATING',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2.0,
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
                    // Score bar (micro interactions)
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: score / 100),
                          duration: const Duration(milliseconds: 2000),
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
      (Icons.schedule_rounded, 'TIMING', product.timing.isNotEmpty ? product.timing : 'As directed'),
      (Icons.verified_rounded, 'HALAL', product.halalStatus.isNotEmpty ? product.halalStatus : 'N/A'),
      (Icons.science_rounded, 'EVIDENCE', product.scientificEvidence.isNotEmpty ? _shortEvidence(product.scientificEvidence) : 'N/A'),
    ];

    return Row(
      children: facts.asMap().entries.map((e) {
        final idx = e.key;
        final f = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 12),
            child: BouncingButton(
              onTap: () => HapticEngine.selection(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: L.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: L.border.withValues(alpha: 0.4), width: 1.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: L.sub.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: L.sub.withValues(alpha: 0.2), blurRadius: 10)
                            ]
                          ),
                          child: Icon(f.$1, size: 18, color: L.sub),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          f.$2,
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: L.border.withValues(alpha: 0.4), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
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
                        BoxShadow(color: L.accent.withValues(alpha: 0.2), blurRadius: 10)
                      ]
                    ),
                    child: Icon(icon, size: 18, color: L.accent),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2.0,
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
        ),
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
            title: 'BENEFITS',
            icon: Icons.thumb_up_alt_rounded,
            items: product.benefits,
            accent: AppColors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ListCard(
            title: 'SIDE EFFECTS',
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
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
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: accent.withValues(alpha: 0.4), blurRadius: 10)
                      ]
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
                                BoxShadow(color: accent.withValues(alpha: 0.8), blurRadius: 8)
                              ]
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
        ),
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
                  Icon(Icons.warning_amber_rounded, size: 20, color: L.amber)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms),
                  const SizedBox(width: 12),
                  Text(
                    'INTERACTIONS',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2.0,
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
                  label: 'FOOD & LIFESTYLE',
                  color: L.amber,
                  items: product.foodInteractions,
                ),
              if (product.medicineInteractions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _InteractionGroup(
                  icon: Icons.medication_rounded,
                  label: 'DRUG CONFLICTS',
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
                fontWeight: FontWeight.w900,
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
                    'EXPERT PERSPECTIVES',
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatars
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: perspectives.length,
                  itemBuilder: (_, i) {
                    final isSelected = safe == i;
                    final p = perspectives[i];
                    return GestureDetector(
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
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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
                          fontWeight: FontWeight.w900,
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
                        r.$2.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.0,
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: L.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: L.glassBorder, width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))
              ],
            ),
            child: Row(
              children: [
                // ── TRACK PROTOCOL BUTTON ──
                Expanded(
                  flex: 3,
                  child: BouncingButton(
                    onTap: onAdd,
                    child: AnimatedContainer(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                      height: 56,
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
                                duration: 800.ms),
                            const SizedBox(width: 12),
                            Text(
                              added ? 'PROTOCOL TRACKED' : 'TRACK PROTOCOL',
                              style: AppTypography.labelMedium.copyWith(
                                color: L.bg,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                const SizedBox(width: 12),

                // ── ORGAN IMPACT BUTTON ──
                BouncingButton(
                  onTap: onImpact,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: L.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: L.accent.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: AppShadows.glow(L.accent, intensity: 0.3),
                    ),
                    child: Icon(Icons.biotech_rounded,
                            color: L.accent, size: 26)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                            duration: 1.5.seconds,
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.05, 1.05)),
                  ),
                ),
                const SizedBox(width: 10),

                // ── AI ASSISTANT BUTTON ──
                BouncingButton(
                  onTap: onChat,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: L.text.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                            color: L.text, size: 24)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                            duration: 2000.ms,
                            color: AppColors.accent),
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
'''

file_path = '/Users/arafathossain/trackai-main/medtrackaiflutter/lib/screens/analysis/product_analysis_screen.dart'
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_code)
print("File rewritten successfully.")
