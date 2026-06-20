import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../models/product_analysis.dart';
import '../visualizer/impact_visualizer_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/controllers/medication_controller.dart';
import '../../domain/entities/entities.dart';
import 'product_chat_screen.dart';
import '../../providers/app_state.dart';

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
    with SingleTickerProviderStateMixin {
  int _expertIdx = 0;
  bool _added = false;
  late final ScrollController _scrollCtrl;
  late final AnimationController _heroCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  int _computeSafetyScore(ProductAnalysis p) {
    // Heuristic: start at 80, deduct for risks
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
          // ── Main Scroll ──────────────────────────────────
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO HEADER ──────────────────────────────
              SliverToBoxAdapter(child: _HeroHeader(product: widget.product, topPad: topPad, safetyColor: _safetyColor)),

              // ── SAFETY SCORE ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _SafetyScoreCard(product: widget.product, color: _safetyColor)
                      .animate().fadeIn(duration: 500.ms, delay: 150.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── QUICK FACTS BENTO ──────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _QuickFacts(product: widget.product)
                      .animate().fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── WHAT IS THIS ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InfoSection(
                    label: 'Overview 📖',
                    icon: Icons.info_outline_rounded,
                    body: widget.product.description,
                  ).animate().fadeIn(duration: 500.ms, delay: 250.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── HOW IT WORKS ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InfoSection(
                    label: 'How It Works ⚙️',
                    icon: Icons.biotech_rounded,
                    body: widget.product.howItWorks,
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── BENEFITS & RISKS ──────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _BenefitsRisksRow(product: widget.product)
                      .animate().fadeIn(duration: 500.ms, delay: 350.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── INTERACTIONS ──────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _InteractionPanel(product: widget.product)
                      .animate().fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              // ── EXPERT PERSPECTIVES ────────────────────────
              if (widget.product.expertPerspectives.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ExpertSection(
                      perspectives: widget.product.expertPerspectives,
                      selectedIdx: _expertIdx,
                      onSelect: (i) => setState(() => _expertIdx = i),
                    ).animate().fadeIn(duration: 500.ms, delay: 450.ms)
                        .slideY(begin: 0.08, end: 0),
                  ),
                ),

              // ── TIMING & EVIDENCE ──────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _MetaRow(product: widget.product)
                      .animate().fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideY(begin: 0.08, end: 0),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: botPad + 120)),
            ],
          ),

          // ── Floating Action Bar ────────────────────────────
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
                );
                context.read<MedicationController>().addMedicine(newMed);
                setState(() => _added = true);
                
                // Production level flow
                context.read<AppState>().showToast('Protocol Tracked Successfully!', type: 'success');
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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

          // ── Top back button ──────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticEngine.selection();
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: L.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: L.border, width: 0.8),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 16),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// HERO HEADER — large name + category
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
      padding: EdgeInsets.fromLTRB(20, topPad + 68, 20, 24),
      decoration: BoxDecoration(
        color: L.bg,
        boxShadow: [
          BoxShadow(
            color: safetyColor.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
        border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.5), width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  blurRadius: 10,
                )
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  product.category.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.06, end: 0),
          const SizedBox(height: 12),
          // Medicine name (hero)
          Text(
            product.name.toUpperCase(),
            style: AppTypography.displaySmall.copyWith(
              color: L.text,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              fontSize: 38,
              height: 1.1,
              shadows: [
                Shadow(color: L.text.withValues(alpha: 0.3), blurRadius: 12),
                Shadow(color: safetyColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 50.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          // Safety indicator row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: safetyColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _safetyLabel(safetyColor).toUpperCase(),
                style: AppTypography.bodySmall.copyWith(
                  color: safetyColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '·',
                style: AppTypography.bodySmall.copyWith(color: L.sub),
              ),
              const SizedBox(width: 16),
              Text(
                'AI ANALYSIS',
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),
        ],
      ),
    );
  }

  String _safetyLabel(Color c) {
    if (c == AppColors.green) return 'Generally Safe';
    if (c == AppColors.amber) return 'Use with Caution';
    return 'Consult Doctor';
  }
}

// ══════════════════════════════════════════════
// SAFETY SCORE CARD — the hero metric
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

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          // Score ring
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _ArcPainter(
                    value: score / 100,
                    color: color,
                    bg: L.border.withValues(alpha: 0.3),
                    strokeWidth: 8,
                  ),
                ),
                Text(
                  '$score',
                  style: AppTypography.titleLarge.copyWith(
                    color: L.text,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -1.0,
                    shadows: [
                      Shadow(color: color.withValues(alpha: 0.5), blurRadius: 12)
                    ]
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY RATING 🛡️',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _scoreDescription(score),
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Score bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutExpo,
                      builder: (_, val, __) => LinearProgressIndicator(
                        value: val,
                        minHeight: 6,
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
    );
  }

  String _scoreDescription(int score) {
    if (score >= 80) return 'Well-tolerated with standard usage';
    if (score >= 60) return 'Monitor for adverse effects';
    if (score >= 40) return 'Requires medical supervision';
    return 'High-risk — doctor consultation required';
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
    final bgP = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fgP = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, 6.283, false, bgP);
    if (value > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius), -1.5708, 6.283 * value, false, fgP);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.value != value;
}

// ══════════════════════════════════════════════
// QUICK FACTS BENTO — dose / form / timing
// ══════════════════════════════════════════════
class _QuickFacts extends StatelessWidget {
  final ProductAnalysis product;
  const _QuickFacts({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final facts = [
      (Icons.schedule_rounded, 'TIMING ⏱️', product.timing.isNotEmpty ? product.timing : 'As directed'),
      (Icons.verified_rounded, 'HALAL ✅', product.halalStatus.isNotEmpty ? product.halalStatus : 'N/A'),
      (Icons.science_rounded, 'EVIDENCE 🔬', product.scientificEvidence.isNotEmpty ? _shortEvidence(product.scientificEvidence) : 'N/A'),
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: L.card.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: L.sub.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f.$1, size: 16, color: L.sub),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      f.$2,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
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
// INFO SECTION — Overview / How it works
// ══════════════════════════════════════════════
class _InfoSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final String body;

  const _InfoSection({required this.label, required this.icon, required this.body});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: L.accent),
              ),
              const SizedBox(width: 12),
              Text(
                label.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              height: 1.8,
              fontSize: 15,
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
            title: 'BENEFITS 🚀',
            icon: Icons.thumb_up_alt_rounded,
            items: product.benefits,
            accent: AppColors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ListCard(
            title: 'SIDE EFFECTS ⚠️',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
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
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.take(5).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                            BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)
                          ]
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.5,
                          fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.amber.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: L.amber.withValues(alpha: 0.05),
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
              Icon(Icons.warning_amber_rounded, size: 18, color: L.amber),
              const SizedBox(width: 10),
              Text(
                'INTERACTIONS ⚡️',
                style: AppTypography.labelMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(color: L.amber.withValues(alpha: 0.4), blurRadius: 10)
                  ]
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (product.foodInteractions.isNotEmpty)
            _InteractionGroup(
              icon: Icons.restaurant_rounded,
              label: 'FOOD & LIFESTYLE',
              color: L.amber,
              items: product.foodInteractions,
            ),
          if (product.medicineInteractions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InteractionGroup(
              icon: Icons.medication_rounded,
              label: 'DRUG–DRUG CONFLICTS',
              color: AppColors.red,
              items: product.medicineInteractions,
            ),
          ],
          if (product.foodInteractions.isEmpty && product.medicineInteractions.isEmpty)
            Text(
              'No known major interactions reported. However, always consult your physician.',
              style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.6, fontStyle: FontStyle.italic),
            ),
        ],
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
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.flash_on_rounded, size: 12, color: color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i,
                        style: AppTypography.bodySmall.copyWith(
                          color: L.sub,
                          height: 1.5,
                          fontSize: 13,
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
// EXPERT SECTION
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_rounded, size: 16, color: L.accent),
              const SizedBox(width: 8),
              Text(
                'Expert Perspectives',
                style: AppTypography.labelMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Avatar row
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: perspectives.length,
              itemBuilder: (_, i) {
                final isSelected = safe == i;
                final p = perspectives[i];
                return GestureDetector(
                  onTap: () {
                    HapticEngine.light();
                    onSelect(i);
                  },
                  child: AnimatedContainer(
                    duration: 250.ms,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? L.accent.withValues(alpha: 0.10)
                          : L.fill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? L.accent.withValues(alpha: 0.4)
                            : L.border,
                        width: isSelected ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p.icon,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          p.role,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? L.accent : L.sub,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Quote
          AnimatedSwitcher(
            duration: 300.ms,
            child: Container(
              key: ValueKey(safe),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: L.fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: L.border, width: 0.8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: L.accent.withValues(alpha: 0.3),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expert.explanation,
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// META ROW — timing + halal + evidence
// ══════════════════════════════════════════════
class _MetaRow extends StatelessWidget {
  final ProductAnalysis product;
  const _MetaRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final rows = [
      (Icons.schedule_rounded, 'Best Timing', product.timing),
      (Icons.verified_rounded, 'Halal Status', product.halalStatus),
      (Icons.science_rounded, 'Scientific Evidence', product.scientificEvidence),
    ];

    return Column(
      children: rows.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.border, width: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: L.fill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.$1, size: 18, color: L.sub),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$2,
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.$3.isNotEmpty ? r.$3 : 'N/A',
                        style: AppTypography.bodySmall.copyWith(
                          color: L.text,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
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
// BOTTOM ACTION BAR
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, botPad + 16),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: 0.70),
            border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.4), width: 1.0)),
          ),
          child: Row(
            children: [
              // Primary — Track It
              Expanded(
                flex: 3,
                child: BouncingButton(
                  onTap: onAdd,
                  child: AnimatedContainer(
                    duration: 300.ms,
                    height: 56,
                    decoration: BoxDecoration(
                      color: added ? L.green : L.text,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: added ? [] : [
                        BoxShadow(color: L.text.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            added
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: added ? Colors.white : L.bg,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            added ? 'ADDED TO PROTOCOL' : 'TRACK PROTOCOL',
                            style: AppTypography.labelLarge.copyWith(
                              color: added ? Colors.white : L.bg,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Body Impact
              BouncingButton(
                onTap: onImpact,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        L.accent.withValues(alpha: 0.2),
                        L.accent.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: L.accent.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: AppShadows.glow(L.accent, intensity: 0.4),
                  ),
                  child: Icon(Icons.science_rounded,
                      color: L.accent, size: 26).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                ),
              ),
              const SizedBox(width: 12),
              // AI Chat
              BouncingButton(
                onTap: onChat,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        L.text.withValues(alpha: 0.15),
                        L.text.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: L.border.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: L.text.withValues(alpha: 0.1), blurRadius: 12)
                    ],
                  ),
                  child: Icon(Icons.smart_toy_rounded,
                      color: L.text, size: 24).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
