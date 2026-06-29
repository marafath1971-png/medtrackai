import re

with open('lib/screens/scan/widgets/scan_result_detail_view.dart', 'r') as f:
    content = f.read()

# Replace the build method
new_build = '''  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final name = result.name.isNotEmpty ? result.name : 'Unknown product';
    final confidence = confidenceValue(result.confidence);

    final fg = onDark ? Colors.white : L.text;
    final sub = onDark ? Colors.white.withValues(alpha: 0.62) : L.sub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onClose != null)
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Close results',
              child: AnimatedPressable(
                onTap: onClose,
                child: Container(
                  width: MedAiA11y.minTapTarget,
                  height: MedAiA11y.minTapTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: onDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : L.fill.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded,
                      color: fg.withValues(alpha: 0.85), size: 22),
                ),
              ),
            ),
          ),
          
        const SizedBox(height: 12),

        // Header Card
        _entrance(
          reduceMotion,
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: onDark ? Colors.white.withValues(alpha: 0.04) : L.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: onDark ? Colors.white.withValues(alpha: 0.08) : L.border,
                width: 1,
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                if (capturedImage != null || (result.imageUrl != null && result.imageUrl!.isNotEmpty)) ...[
                  _HeroImage(
                    capturedImage: capturedImage,
                    imageUrl: result.imageUrl,
                    onDark: onDark,
                  ),
                  const SizedBox(height: 20),
                ],
                _StatusBadge(identified: result.identified, onDark: onDark),
                const SizedBox(height: 16),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                if (result.brand.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.brand,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: sub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (result.genericName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Generic: ${result.genericName}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(color: sub, height: 1.4),
                  ),
                ],
                const SizedBox(height: 24),
                ConfidenceMeter(confidence: confidence, onDark: onDark),
              ],
            ),
          ),
          delay: 50.ms,
        ),

        if (result.ahaMoment != null && result.ahaMoment!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _InsightBanner(text: result.ahaMoment!, onDark: onDark),
            delay: 100.ms,
          ),
        ],

        const SizedBox(height: 24),

        _entrance(
          reduceMotion,
          _QuickFactsGrid(result: result, onDark: onDark),
          delay: 120.ms,
        ),

        // Dosage & Supply
        if (_hasDosingInfo || _hasPackInfo) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Dosage & Supply',
              icon: Icons.medication_liquid_rounded,
              onDark: onDark,
              children: [
                if (_hasDosingInfo) _GroupedItem(icon: Icons.schedule_rounded, label: 'How to take', text: _dosingBody, onDark: onDark),
                if (_hasPackInfo) _GroupedItem(icon: Icons.inventory_2_outlined, label: 'Pack info', text: _packBody, onDark: onDark),
              ],
            ),
            delay: 140.ms,
          ),
        ],

        // Safety Profile
        if (result.warnings.isNotEmpty || result.sideEffects.isNotEmpty || result.interactions.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Safety Profile',
              icon: Icons.health_and_safety_rounded,
              accent: AppColors.amber,
              onDark: onDark,
              children: [
                if (result.warnings.isNotEmpty) _GroupedItem(icon: Icons.warning_amber_rounded, label: 'Warnings', text: result.warnings, accent: AppColors.amber, onDark: onDark),
                if (result.sideEffects.isNotEmpty) _GroupedItem(icon: Icons.healing_outlined, label: 'Side effects', text: result.sideEffects, onDark: onDark),
                if (result.interactions.isNotEmpty) _GroupedItem(icon: Icons.link_off_rounded, label: 'Interactions', text: result.interactions, accent: AppColors.red, onDark: onDark),
              ],
            ),
            delay: 160.ms,
          ),
        ],

        // Details
        if (result.description.isNotEmpty || result.storage.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _GroupedSection(
              title: 'Details',
              icon: Icons.info_outline_rounded,
              onDark: onDark,
              children: [
                if (result.description.isNotEmpty) _GroupedItem(icon: Icons.article_outlined, label: 'Overview', text: result.description, onDark: onDark),
                if (result.storage.isNotEmpty) _GroupedItem(icon: Icons.ac_unit_outlined, label: 'Storage', text: result.storage, onDark: onDark),
              ],
            ),
            delay: 180.ms,
          ),
        ],

        if (_hasRegulatoryInfo) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _RegulatorySection(result: result, onDark: onDark),
            delay: 200.ms,
          ),
        ],

        if (result.bodyImpact != null &&
            result.bodyImpact!.mechanismOfAction.isNotEmpty) ...[
          const SizedBox(height: 20),
          _entrance(
            reduceMotion,
            _BodyImpactSection(impact: result.bodyImpact!, onDark: onDark),
            delay: 220.ms,
          ),
        ],

        const SizedBox(height: 40),

        // CTAs in a subtle floating-like container
        _entrance(
          reduceMotion,
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: onDark ? Colors.black.withValues(alpha: 0.2) : L.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: onDark ? Colors.white.withValues(alpha: 0.1) : L.border.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                MedAiCTA(
                  label: 'Add to My Medicines',
                  icon: Icons.add_rounded,
                  onTap: onAddToMedicines,
                ),
                const SizedBox(height: 16),
                MedAiCTA(
                  label: 'Scan another',
                  secondary: true,
                  onTap: onScanAnother,
                ),
              ],
            ),
          ),
          delay: 240.ms,
        ),

        const SizedBox(height: 20),

        Text(
          'AI identification — always verify with your pharmacist or prescriber.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: sub.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
      ],
    );
  }'''

build_pattern = re.compile(r'  @override\s+Widget build\(BuildContext context\) \{.*?(?=  bool get _hasDosingInfo)', re.DOTALL)
content = build_pattern.sub(new_build + '\n\n', content)

# Replace _DetailSection with _GroupedSection and _GroupedItem
grouped_widgets = '''class _GroupedSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accent;
  final bool onDark;

  const _GroupedSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accent,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final accentColor = accent ?? AppColors.sageGreen;
    final fg = onDark ? Colors.white : L.text;

    return MedAiGlass(
      radius: AppRadius.l,
      padding: const EdgeInsets.all(20),
      tint: onDark ? Colors.white.withValues(alpha: 0.04) : L.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children.map((child) => Padding(
            padding: EdgeInsets.only(bottom: child == children.last ? 0 : 20),
            child: child,
          )),
        ],
      ),
    );
  }
}

class _GroupedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color? accent;
  final bool onDark;

  const _GroupedItem({
    required this.icon,
    required this.label,
    required this.text,
    this.accent,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final sub = onDark ? Colors.white.withValues(alpha: 0.7) : L.sub;
    final fg = onDark ? Colors.white : L.text;
    final accentColor = accent ?? (onDark ? Colors.white.withValues(alpha: 0.5) : L.sub.withValues(alpha: 0.5));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: AppTypography.bodySmall.copyWith(
                  color: sub,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}'''

detail_pattern = re.compile(r'class _DetailSection extends StatelessWidget \{.*?\}\n\}', re.DOTALL)
content = detail_pattern.sub(grouped_widgets, content)

# Update _RegulatorySection to use _GroupedSection
reg_pattern = re.compile(r'class _RegulatorySection extends StatelessWidget \{.*?(?=class _BodyImpactSection)', re.DOTALL)

new_reg = '''class _RegulatorySection extends StatelessWidget {
  final ScanResult result;
  final bool onDark;

  const _RegulatorySection({required this.result, required this.onDark});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (result.din.isNotEmpty) parts.add('DIN: ${result.din}');
    if (result.halalStatus != 'unknown') {
      parts.add('Halal status: ${_formatHalal(result.halalStatus)}');
    }
    if (result.halalNote.isNotEmpty) parts.add(result.halalNote);

    return _GroupedSection(
      title: 'Regulatory',
      icon: Icons.verified_user_outlined,
      onDark: onDark,
      children: [
        _GroupedItem(
          icon: Icons.rule_rounded,
          label: 'Information',
          text: parts.join('\\n\\n'),
          onDark: onDark,
        ),
      ],
    );
  }

  String _formatHalal(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

'''
content = reg_pattern.sub(new_reg, content)

with open('lib/screens/scan/widgets/scan_result_detail_view.dart', 'w') as f:
    f.write(content)

print("UI updated successfully")
