import 'dart:ui';

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
  String _activeTab = 'profile'; // profile | stats | app | data | global

  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

  Future<bool> _onWillPop() async {
    final innerNav = _nestedNavKey.currentState;
    if (innerNav != null && innerNav.canPop()) {
      innerNav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    final tabs = [
      {'id': 'profile', 'label': s.settingsProfile, 'icon': '👤'},
      {'id': 'stats', 'label': s.settingsStats, 'icon': '📈'},
      {'id': 'app', 'label': s.settingsApp, 'icon': '📱'},
      {'id': 'data', 'label': s.settingsData, 'icon': '💾'},
      {'id': 'global', 'label': s.settingsGlobal, 'icon': '🌐'},
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldClose = await _onWillPop();
        if (shouldClose && context.mounted) widget.onClose();
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dimmed backdrop — tap outside to dismiss
          Positioned.fill(
            child: Semantics(
              button: true,
              label: 'Close settings',
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          // Glass sheet
          GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: size.height * 0.9,
                  width: size.width,
                  constraints: const BoxConstraints(maxWidth: 430),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        L.meshBg.withValues(alpha: 0.92),
                        L.bg.withValues(alpha: 0.96),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                    border: Border(
                      top: BorderSide(
                          color: L.glassBorder.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    boxShadow: AppShadows.premium,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!reduceMotion)
                        Positioned(
                          top: -80,
                          left: -40,
                          right: -40,
                          height: 220,
                          child: IgnorePointer(
                            child: AuroraBackground(
                              opacity: context.isDark ? 0.35 : 0.22,
                            ),
                          ),
                        ),
                      Column(children: [
                        const SizedBox(height: 12),
                        Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10))),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.settings,
                                        style: AppTypography.headlineLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: L.text,
                                                letterSpacing: -0.6)),
                                    const SizedBox(height: 2),
                                    Text('Your preferences',
                                        style: AppTypography.bodySmall
                                            .copyWith(color: L.sub)),
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
                                    decoration: BoxDecoration(
                                        color: L.text.withValues(alpha: 0.06),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: L.border
                                                .withValues(alpha: 0.12),
                                            width: 0.5)),
                                    child: Center(
                                        child: Icon(Icons.close_rounded,
                                            color: L.text, size: 22)),
                                  ),
                                ),
                              ),
                            ],
                          ).let((w) => reduceMotion
                              ? w
                              : w
                                  .animate()
                                  .fade(duration: 400.ms)
                                  .slideY(begin: -0.1, end: 0)),
                        ),
                        SizedBox(
                          height: MedAiA11y.minTapTarget,
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                                children: tabs.map((t) {
                              final isAct = _activeTab == t['id'];
                              final idx = tabs.indexOf(t);
                              final tabLabel = t['label'] as String;

                              Widget pill = Semantics(
                                button: true,
                                selected: isAct,
                                label: tabLabel,
                                child: AnimatedPressable(
                                  onTap: () {
                                    HapticEngine.selection();
                                    while (_nestedNavKey
                                            .currentState?.canPop() ==
                                        true) {
                                      _nestedNavKey.currentState!.pop();
                                    }
                                    setState(
                                        () => _activeTab = t['id'] as String);
                                  },
                                  child: AnimatedContainer(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 280),
                                    curve: AppCurves.smooth,
                                    constraints: const BoxConstraints(
                                        minHeight: MedAiA11y.minTapTargetCompact),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                        gradient: isAct
                                            ? LinearGradient(
                                                colors: [
                                                  L.accent,
                                                  L.accent
                                                      .withValues(alpha: 0.85),
                                                ],
                                              )
                                            : null,
                                        color: isAct
                                            ? null
                                            : L.card.withValues(alpha: 0.6),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: isAct
                                                ? L.accent
                                                    .withValues(alpha: 0.4)
                                                : L.border
                                                    .withValues(alpha: 0.1),
                                            width: 0.5),
                                        boxShadow: isAct
                                            ? L.accentGlow(intensity: 0.15)
                                            : null),
                                    child: Row(children: [
                                      Text(t['icon'] as String,
                                          style:
                                              const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Text(tabLabel,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: isAct
                                                      ? Colors.white
                                                      : L.text.withValues(
                                                          alpha: 0.55),
                                                  letterSpacing: 0.1,
                                                  fontSize: 12)),
                                    ]),
                                  ),
                                ),
                              );

                              if (!reduceMotion) {
                                pill = pill
                                    .animate()
                                    .fade(delay: (idx * 30).ms)
                                    .scale(begin: const Offset(0.95, 0.95));
                              }

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: pill,
                              );
                            }).toList()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: L.border.withValues(alpha: 0.1)),
                        Expanded(
                          child: Navigator(
                            key: _nestedNavKey,
                            onGenerateRoute: (settings) {
                              return MaterialPageRoute(
                                settings: settings,
                                builder: (_) => _buildContent(state, L),
                              );
                            },
                          ),
                        ),
                      ]),
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
