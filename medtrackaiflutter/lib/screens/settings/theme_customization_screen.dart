import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../services/dynamic_icon_service.dart';

class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() => _ThemeCustomizationScreenState();
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
    final L = context.L;

    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 16),
              child: Row(
                children: [
                  BouncingButton(
                    onTap: () {
                      HapticEngine.selection();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: L.border.withValues(alpha: 0.1)),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'App Appearance',
                      style: AppTypography.headlineMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  Text(
                    'APP ICONS',
                    style: AppTypography.labelLarge.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _icons.map((icon) {
                      final isSelected = _currentIcon == icon['id'];
                      return BouncingButton(
                        onTap: () => _setIcon(icon['id'] as String?),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: (MediaQuery.of(context).size.width - (AppSpacing.screenPadding * 2) - 16) / 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? L.accent.withValues(alpha: 0.1) : L.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? L.accent : L.border.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: icon['color'] as Color,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: (icon['color'] as Color).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
                                  ] : [],
                                ),
                                child: isSelected 
                                    ? const Icon(Icons.check_rounded, color: Colors.white)
                                    : null,
                              ).animate(target: isSelected ? 1 : 0).scaleXY(end: 1.1, curve: Curves.easeOutBack),
                              const SizedBox(height: 12),
                              Text(
                                icon['name'] as String,
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected ? L.text : L.sub,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppGradients.glass(L.accent),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: L.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: L.accent, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'More themes coming soon!',
                                style: AppTypography.titleMedium.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Unlock exclusive aesthetics with streaks.',
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
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
