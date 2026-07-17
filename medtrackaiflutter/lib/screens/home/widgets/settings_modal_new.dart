import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/haptic_engine.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';
import '../../../screens/settings/global_settings_screen.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import 'settings/app_tab.dart';
import 'settings/data_tab.dart';
import 'settings/ios_settings_style.dart';
import 'settings/profile_tab.dart';
import 'settings/stats_tab.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onClose;
  const SettingsModal({super.key, required this.onClose});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  String _activeTab = 'profile';

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final tabs = [
      {
        'id': 'profile',
        'label': s.settingsProfile,
        'icon': Icons.person_rounded
      },
      {
        'id': 'stats',
        'label': s.settingsStats,
        'icon': Icons.bar_chart_rounded
      },
      {
        'id': 'app',
        'label': s.settingsApp,
        'icon': Icons.phone_iphone_rounded
      },
      {'id': 'data', 'label': s.settingsData, 'icon': Icons.storage_rounded},
      {'id': 'global', 'label': s.settingsGlobal, 'icon': Icons.tune_rounded},
    ];
    final activeIndex =
        tabs.indexWhere((t) => t['id'] == _activeTab).clamp(0, tabs.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) widget.onClose();
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Close settings',
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: size.height * 0.92,
                  width: size.width,
                  constraints: const BoxConstraints(maxWidth: 430),
                  decoration: BoxDecoration(
                    color: IosSettingsTokens.canvas.withValues(alpha: 0.98),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 32,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.p12),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: L.sub.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.p20,
                          AppSpacing.p16,
                          AppSpacing.p12,
                          AppSpacing.p8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.settings,
                                    style: AppTypography.headlineLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 30,
                                      color: L.text,
                                      letterSpacing: -0.6,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Made for you — manage with confidence',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: L.sub,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Close settings',
                              child: AnimatedPressable(
                                onTap: widget.onClose,
                                child: Container(
                                  width: MedAiA11y.minTapTarget,
                                  height: MedAiA11y.minTapTarget,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CupertinoIcons.xmark,
                                    color: L.sub.withValues(alpha: 0.7),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).let((w) => reduceMotion
                            ? w
                            : w
                                .animate()
                                .fade(duration: 320.ms)
                                .slideY(begin: -0.04, end: 0)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.p20,
                          AppSpacing.p4,
                          AppSpacing.p20,
                          AppSpacing.p12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.p12),
                          decoration: BoxDecoration(
                            color: AppColors.pastelMint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: AppColors.limeInk,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.p12),
                              Expanded(
                                child: Text(
                                  'Your success settings — reminders, safety, and share.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: L.text.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.p20,
                          0,
                          AppSpacing.p20,
                          AppSpacing.p12,
                        ),
                        child: IosSettingsSegmentedBar(
                          scrollable: true,
                          labels:
                              tabs.map((t) => t['label'] as String).toList(),
                          icons:
                              tabs.map((t) => t['icon'] as IconData).toList(),
                          selectedIndex: activeIndex,
                          onSelected: (index) {
                            HapticEngine.selection();
                            setState(
                              () => _activeTab = tabs[index]['id'] as String,
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ColoredBox(
                          color: IosSettingsTokens.canvas,
                          child: KeyedSubtree(
                            key: ValueKey(_activeTab),
                            child: _buildContent(state, L),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppState state, AppThemeColors L) {
    switch (_activeTab) {
      case 'profile':
        return ProfileTab(state: state, L: L);
      case 'stats':
        return StatsTab(state: state, L: L);
      case 'app':
        return AppTab(state: state, L: L, onClose: widget.onClose);
      case 'data':
        return DataTab(state: state, L: L, onClose: widget.onClose);
      case 'global':
        return const GlobalSettingsScreen(embedded: true);
      default:
        return const SizedBox();
    }
  }
}

extension _SettingsModalLet<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
