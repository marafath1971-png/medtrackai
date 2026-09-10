import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/med_ai_ui.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../widgets/common/premium_illustration_banner.dart';
import '../../core/constants/premium_graphics.dart';
import '../../services/dynamic_icon_service.dart';
import '../../l10n/app_localizations.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen> {
  String? _currentIcon;

  final List<Map<String, dynamic>> _icons = [
    {'id': null, 'name': 'Classic Vibe', 'color': Colors.blue},
    {'id': 'blue', 'name': 'Ocean Breeze', 'color': Colors.lightBlueAccent},
    {'id': 'dark', 'name': 'OLED Dark', 'color': Colors.black87},
    {'id': 'gold', 'name': 'Premium Gold', 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentIcon();
  }

  Future<void> _loadCurrentIcon() async {
    final icon = await DynamicIconService.getCurrentIcon();
    if (mounted) {
      setState(() => _currentIcon = icon);
    }
  }

  Future<void> _setIcon(String? iconId) async {
    HapticEngine.selection();
    setState(() => _currentIcon = iconId);
    await DynamicIconService.setIcon(iconId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final L = context.L;
    final reduceMotion = MedAiA11y.reducedMotion(context);
    final tileWidth =
        (MediaQuery.of(context).size.width - (AppSpacing.screenPadding * 2) - 16) /
            2;

    return AppScaffold(
      showAurora: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumPageHeader(
            title: l10n.homeAppAppearance,
            subtitle: 'Icons and visual style',
            onBack: () {
              HapticEngine.selection();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                const PremiumIllustrationBanner(
                  asset: PremiumGraphics.paywallPro,
                  height: 110,
                  padding: EdgeInsets.all(14),
                ),
                const SizedBox(height: 16),
                  MedAiSectionHeader(title: l10n.settingsAppIcons),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _icons.map((icon) {
                      final isSelected = _currentIcon == icon['id'];
                      final iconColor = icon['color'] as Color;

                      Widget tile = MedAiDepthCard(
                        padding: const EdgeInsets.all(16),
                        accentGlow: isSelected,
                        onTap: () => _setIcon(icon['id'] as String?),
                        child: SizedBox(
                          width: tileWidth - 32,
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: iconColor.withValues(
                                                alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                        color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                icon['name'] as String,
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected ? L.text : L.sub,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );

                      if (!reduceMotion && isSelected) {
                        tile = tile
                            .animate()
                            .scaleXY(end: 1.02, curve: AppCurves.emilOut);
                      }

                      return SizedBox(width: tileWidth, child: tile);
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  MedAiGlass(
                    child: Row(
                      children: [
                        Container(
                          width: MedAiA11y.minTapTargetCompact,
                          height: MedAiA11y.minTapTargetCompact,
                          decoration: BoxDecoration(
                            color: L.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              color: L.accent, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.settingsMoreThemesComingSoon,
                                style: AppTypography.titleMedium.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                l10n.settingsUnlockExclusiveAestheticsWithStreaks,
                                style: AppTypography.labelLarge.copyWith(
                                  color: L.sub,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
