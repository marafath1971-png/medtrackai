import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/med_ai_ui.dart';
import '../../../widgets/common/animated_pressable.dart';
import 'settings/profile_tab.dart';
import 'settings/stats_tab.dart';
import 'settings/app_tab.dart';
import 'settings/data_tab.dart';
import 'settings/ios_settings_style.dart';
import '../../../screens/settings/global_settings_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/haptic_engine.dart';

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
      {'id': 'profile', 'label': s.settingsProfile, 'icon': Icons.person_rounded},
      {'id': 'stats', 'label': s.settingsStats, 'icon': Icons.bar_chart_rounded},
      {'id': 'app', 'label': s.settingsApp, 'icon': Icons.phone_iphone_rounded},
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
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: size.height * 0.9,
                  width: size.width,
                  constraints: const BoxConstraints(maxWidth: 430),
                  decoration: BoxDecoration(
                    color: L.bg.withValues(alpha: 0.97),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: L.sub.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.settings,
                                style: AppTypography.headlineLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 34,
                                  color: L.text,
                                  letterSpacing: 0.37,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: 'Close settings',
                              child: AnimatedPressable(
                                onTap: widget.onClose,
                                child: SizedBox(
                                  width: MedAiA11y.minTapTarget,
                                  height: MedAiA11y.minTapTarget,
                                  child: Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: L.sub.withValues(alpha: 0.45),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).let((w) => reduceMotion
                            ? w
                            : w
                                .animate()
                                .fade(duration: 400.ms)
                                .slideY(begin: -0.06, end: 0)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: IosSettingsSegmentedBar(
                          scrollable: true,
                          labels: tabs
                              .map((t) => t['label'] as String)
                              .toList(),
                          icons: tabs
                              .map((t) => t['icon'] as IconData)
                              .toList(),
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
                          color: L.bg,
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
