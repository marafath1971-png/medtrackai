import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import 'widgets/caregiver_widgets.dart';
import 'widgets/monitoring_widgets.dart';
import 'widgets/add_cg_flow.dart';
import 'widgets/join_as_cg_view.dart';
import 'widgets/alert_log_widgets.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../core/utils/scan_safety_mapper.dart';

import '../../widgets/common/premium_texture.dart';

enum FamilyView {
  hub,
  addStep1,
  addStep2,
  addStep3,
  dashboard,
  join,
}

class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  FamilyView _view = FamilyView.hub;
  Caregiver? _newCg;
  String _inviteCode = '';
  Caregiver? _dashboardCg;
  MissedAlert? _alertDetail;

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _relation = 'Spouse';
  String _avatar = 'P';
  int _pivot = 1; // Default to Family Circle as per reference style
  int _alertDelay = 30;
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final L = context.L;

    Widget child;
    if (_alertDetail != null) {
      child = AlertDetailView(
          key: const ValueKey('alertDetail'),
          alert: _alertDetail!,
          onBack: () => setState(() => _alertDetail = null),
          L: L);
    } else if (_dashboardCg != null) {
      child = ProtectorInsights(
          key: const ValueKey('dashboard'),
          cg: _dashboardCg!,
          state: state,
          onBack: () => setState(() => _dashboardCg = null),
          L: L);
    } else if (_view == FamilyView.join) {
      child = JoinAsCaregiverView(
          key: const ValueKey('join'),
          state: state,
          L: L,
          onBack: () => setState(() => _view = FamilyView.hub),
          onJoined: (cg) {
            setState(() => _view = FamilyView.hub);
          });
    } else {
      switch (_view) {
        case FamilyView.addStep1:
          child = AddCgStep1(
              key: const ValueKey('add1'),
              nameCtrl: _nameCtrl,
              contactCtrl: _contactCtrl,
              relation: _relation,
              avatar: _avatar,
              alertDelay: _alertDelay,
              onRelChange: (v) => setState(() => _relation = v),
              onAvatarChange: (v) => setState(() => _avatar = v),
              onDelayChange: (v) => setState(() => _alertDelay = v),
              L: L,
              onBack: () => setState(() => _view = FamilyView.hub),
              onNext: () async {
                final s = Provider.of<AppState>(context, listen: false);
                final patientUid = AuthService.uid ?? '';
                const colors = [
                  '#111111',
                  '#1A1A1A',
                  '#222222',
                  '#2A2A2A',
                  '#333333'
                ];
                final color = colors[s.caregivers.length % colors.length];
                final cg = Caregiver(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: _nameCtrl.text.trim(),
                  relation: _relation,
                  contact: _contactCtrl.text.trim(),
                  avatar: _avatar,
                  alertDelay: _alertDelay,
                  addedAt: todayStr(),
                  color: color,
                  patientUid: patientUid,
                );
                s.addCaregiver(cg);
                final code = await s.createInvite(cg);
                setState(() {
                  _newCg = cg;
                  _inviteCode = code;
                  _view = FamilyView.addStep2;
                });
              });
          break;
        case FamilyView.addStep2:
          child = AddCgStep2(
              key: const ValueKey('add2'),
              cg: _newCg!,
              inviteCode: _inviteCode,
              L: L,
              onNext: () {
                final state = Provider.of<AppState>(context, listen: false);
                state.activateCaregiver(_newCg!.id);
                setState(() => _view = FamilyView.addStep3);
              });
          break;
        case FamilyView.addStep3:
          child = AddCgStep3(
              key: const ValueKey('add3'),
              cg: _newCg!,
              L: L,
              onDone: () {
                setState(() {
                  _view = FamilyView.hub;
                  _nameCtrl.clear();
                  _contactCtrl.clear();
                });
              });
          break;
        default:
          child = HubView(
              key: const ValueKey('hub'),
              state: state,
              L: L,
              pivot: _pivot,
              isScrolled: _isScrolled,
              scrollController: _scrollController,
              onPivotChanged: (v) => setState(() => _pivot = v),
              // Inviting/joining is FREE — it's the viral growth loop, never
              // paywall it (premium gates the advanced monitoring insights
              // instead, in monitoring_widgets). Gating the invite here was
              // masked while isPremium was hardcoded true; now it's real, so an
              // un-gate is required or non-premium users can't add anyone.
              onAddCg: () => setState(() => _view = FamilyView.addStep1),
              onJoin: () => setState(() => _view = FamilyView.join),
              onDashboard: (cg) => setState(() => _dashboardCg = cg),
              onAlertDetail: (a) => setState(() => _alertDetail = a),
              onMarkSeen: () => state.markAlertsAsSeen());
      }
    }

    final reduceMotion = MedAiA11y.reducedMotion(context);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      switchInCurve: AppCurves.emilOut,
      switchOutCurve: AppCurves.emilOut,
      transitionBuilder: (w, anim) {
        if (reduceMotion) return w;
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: AppCurves.emilOut)),
            child: w,
          ),
        );
      },
      child: child,
    );
  }
}

class HubView extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final int pivot;
  final bool isScrolled;
  final ScrollController scrollController;
  final ValueChanged<int> onPivotChanged;
  final VoidCallback onAddCg, onJoin, onMarkSeen;
  final void Function(Caregiver) onDashboard;
  final void Function(MissedAlert) onAlertDetail;

  const HubView({
    super.key,
    required this.state,
    required this.L,
    required this.pivot,
    required this.isScrolled,
    required this.scrollController,
    required this.onPivotChanged,
    required this.onAddCg,
    required this.onJoin,
    required this.onDashboard,
    required this.onAlertDetail,
    required this.onMarkSeen,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount =
        state.caregivers.where((c) => c.status == "active").length;
    final unseenCount = state.missedAlerts.where((a) => !a.seen).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: pivot == 1
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: Semantics(
                button: true,
                label: 'Add guardian',
                child: FloatingActionButton.extended(
                  onPressed: onAddCg,
                  backgroundColor: L.text,
                  elevation: 0,
                  extendedIconLabelSpacing: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.roundL,
                  ),
                  icon: Icon(Icons.person_add_rounded,
                      color: L.bg, size: 20),
                  label: Text(
                    'Add guardian',
                    style: AppTypography.labelLarge.copyWith(
                      color: L.bg,
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          PremiumHomeSurface(
            child: SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            controller: scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 140 + MediaQuery.of(context).padding.top),

                // ── HUB CONTENT ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _familyEntrance(
                        context,
                        Row(
                          children: [
                            Expanded(
                              child: _CircleStatBento(
                                label: 'Protectors',
                                value: '$activeCount',
                                icon: Icons.shield_outlined,
                                L: L,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            Expanded(
                              child: _CircleStatBento(
                                label: 'Monitoring',
                                value: unseenCount > 0 ? 'Urgent' : 'Secure',
                                icon: unseenCount > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.verified_user_outlined,
                                iconColor:
                                    unseenCount > 0 ? L.error : L.success,
                                L: L,
                                glow: unseenCount > 0,
                                accentGlow: unseenCount > 0,
                              ),
                            ),
                          ],
                        ),
                        delayMs: 80,
                      ),

                      const SizedBox(height: AppSpacing.p24),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.p4),
                            decoration: BoxDecoration(
                              color: L.card,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: L.border.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.eatoNavy.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _CompactPivotPill(
                                  label: 'Family',
                                  active: pivot == 1,
                                  onTap: () => onPivotChanged(1),
                                  L: L,
                                ),
                                const SizedBox(width: AppSpacing.p4),
                                _CompactPivotPill(
                                  label: 'Care',
                                  active: pivot == 0,
                                  onTap: () => onPivotChanged(0),
                                  L: L,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.p24),

                      if (unseenCount > 0)
                        Semantics(
                          button: true,
                          label: '$unseenCount missed medication alerts',
                          child: AnimatedPressable(
                            onTap: onMarkSeen,
                            scaleFactor: 0.985,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.p12),
                              padding: const EdgeInsets.all(AppSpacing.p16),
                              decoration: BoxDecoration(
                                color: AppColors.pastelPink,
                                borderRadius: BorderRadius.circular(AppRadius.l),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.s),
                                    ),
                                    child: Icon(Icons.warning_amber_rounded,
                                        color: AppColors.red, size: 22),
                                  ),
                                  const SizedBox(width: AppSpacing.p12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Urgent monitoring',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: L.sub,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '$unseenCount missed medication alerts',
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            color: L.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_outward_rounded,
                                      color: L.sub.withValues(alpha: 0.5),
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (state.meds.any((m) => m.hasCriticalSafetyAlerts))
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.p24),
                          padding: const EdgeInsets.all(AppSpacing.p16),
                          decoration: BoxDecoration(
                            color: AppColors.pastelSun,
                            borderRadius: BorderRadius.circular(AppRadius.l),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.s),
                                ),
                                child: Icon(Icons.menu_book_rounded,
                                    color: L.text, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.p12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Know your medicine',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: L.text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sensitive meds in this circle — caregivers should review warnings before dose time.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: L.sub,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // CONTENT BASED ON PIVOT
                      if (pivot == 1) ...[
                        // FAMILY CIRCLE (Monitoring others)
                        if (state.monitoredPatients.isEmpty)
                          _buildEmptyMonitoringState(context, L, onJoin)
                              .animate()
                              .fadeIn(duration: 600.ms)
                        else ...[
                          ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.monitoredPatients.length,
                            itemBuilder: (context, index) {
                              final p = state.monitoredPatients[index];
                              return PatientCard(
                                patient: p,
                                state: state,
                                L: L,
                                onTap: () {
                                  onDashboard(Caregiver(
                                    id: 0,
                                    name: p['name'] ?? 'Patient',
                                    relation: p['relation'] ?? 'Family',
                                    patientUid: p['uid'],
                                    addedAt: p['addedAt'] ?? 'just now',
                                    avatar: p['avatar'] ?? 'P',
                                  ));
                                },
                              ).animate().fadeIn(
                                  delay: (100 + index * 50).ms,
                                  duration: 500.ms);
                            },
                          ),
                        ],
                      ] else ...[
                        // ACCOUNT SECURITY / MY CAREGIVERS
                        if (state.profile?.familyMembers.isNotEmpty ?? false) ...[
                          MedAiSectionHeader(
                            title: 'Managing',
                            subtitle: '${state.profile!.familyMembers.length} profiles',
                          ),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              scrollDirection: Axis.horizontal,
                              itemCount: state.profile!.familyMembers.length,
                              itemBuilder: (context, index) {
                                final member = state.profile!.familyMembers[index];
                                return AnimatedPressable(
                                  onTap: () async {
                                    HapticEngine.selection();
                                    if (member.pin != null && member.pin!.isNotEmpty) {
                                      final success = await context.push<bool>(
                                        AppRoutes.familyPin,
                                        extra: ProfilePinRouteArgs(profile: member),
                                      );
                                      if (success == true) {
                                        state.switchProfile(member);
                                        state.showToast('Switched to ${member.name}');
                                      }
                                    } else {
                                      state.switchProfile(member);
                                      state.showToast('Switched to ${member.name}');
                                    }
                                  },
                                  onLongPress: () {
                                    HapticEngine.selection();
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => SimpleDialog(
                                        title: Text('Manage ${member.name}', style: TextStyle(color: L.text, fontWeight: FontWeight.bold)),
                                        backgroundColor: L.card,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: L.border.withValues(alpha: 0.1))),
                                        children: [
                                          SimpleDialogOption(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              state.switchProfile(member);
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.swap_horiz_rounded, color: L.primary),
                                                const SizedBox(width: AppSpacing.p12),
                                                Text('Switch to Profile', style: TextStyle(color: L.text)),
                                              ],
                                            ),
                                          ),
                                          SimpleDialogOption(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              context.push(
                                                AppRoutes.familyEditMember,
                                                extra: EditFamilyMemberRouteArgs(member: member),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, color: L.primary),
                                                const SizedBox(width: AppSpacing.p12),
                                                Text('Edit Profile', style: TextStyle(color: L.text)),
                                              ],
                                            ),
                                          ),
                                          SimpleDialogOption(
                                            onPressed: () async {
                                              Navigator.pop(ctx);
                                              state.showToast('Generating PDF...');
                                              await state.exportProfileDataPDF(member);
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.picture_as_pdf_rounded, color: L.primary),
                                                const SizedBox(width: AppSpacing.p12),
                                                Text('Generate Adherence PDF', style: TextStyle(color: L.text)),
                                              ],
                                            ),
                                          ),
                                          SimpleDialogOption(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              showDialog(
                                                context: context,
                                                builder: (removeCtx) => AlertDialog(
                                                  backgroundColor: L.card,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: L.border.withValues(alpha: 0.1))),
                                                  title: Text('Remove profile?', style: AppTypography.titleLarge.copyWith(color: L.text, fontWeight: FontWeight.w800)),
                                                  content: Text('This will stop all reminders for ${member.name}. History for this member will be preserved in the cloud.', style: AppTypography.bodyMedium.copyWith(color: L.sub)),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(removeCtx), child: Text('Cancel', style: AppTypography.labelLarge.copyWith(color: L.sub))),
                                                    TextButton(
                                                      onPressed: () {
                                                        state.removeFamilyMember(member.id);
                                                        Navigator.pop(removeCtx);
                                                      },
                                                      child: Text('Remove', style: AppTypography.labelLarge.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            child: const Row(
                                              children: [
                                                Icon(Icons.delete_forever_rounded, color: AppColors.red),
                                                SizedBox(width: AppSpacing.p12),
                                                Text('Remove Profile', style: TextStyle(color: AppColors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsetsDirectional.only(end: AppSpacing.p12),
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
                                    decoration: BoxDecoration(
                                      color: L.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: member.isCritical 
                                            ? AppColors.red.withValues(alpha: 0.3) 
                                            : L.border.withValues(alpha: 0.1),
                                        width: member.isCritical ? 1.5 : 1.0,
                                      ),
                                      boxShadow: AppShadows.soft,
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Text(member.avatar, style: const TextStyle(fontSize: 18)),
                                            if (member.isCritical)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: AppColors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: AppSpacing.p12),
                                        Expanded(
                                          child: Text(
                                            member.name,
                                            style: AppTypography.labelSmall.copyWith(
                                              color: L.text,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.p32),
                        ],

                        if (state.caregivers.isEmpty)
                          _buildEmptyState(context, L, onAddCg)
                              .animate()
                              .fadeIn(duration: 600.ms)
                        else ...[
                          ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.caregivers.length,
                            itemBuilder: (context, index) => CaregiverCard(
                              cg: state.caregivers[index],
                              state: state,
                              L: L,
                              onDashboard: () =>
                                  onDashboard(state.caregivers[index]),
                            ).animate().fadeIn(
                                delay: (100 + index * 50).ms, duration: 500.ms),
                          ),
                        ],
                      ],

                      const SizedBox(height: AppSpacing.p32),

                      // ALERT LOG
                      if (state.missedAlerts.isNotEmpty) ...[
                        MedAiSectionHeader(
                          title: 'Recent activity',
                          subtitle: '${state.missedAlerts.length} alerts',
                        ),
                        ListView.builder(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.missedAlerts.length,
                          itemBuilder: (context, index) => AlertLogCard(
                            alert: state.missedAlerts[index],
                            L: L,
                            onTap: () =>
                                onAlertDetail(state.missedAlerts[index]),
                          ).animate().fadeIn(
                              delay: (300 + index * 50).ms, duration: 500.ms),
                        ),
                      ],

                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),

          // ── PREMIUM HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FamilyHeader(
              scrollOffset:
                  scrollController.hasClients ? scrollController.offset : 0,
              isActive: activeCount > 0 || state.monitoredPatients.isNotEmpty,
              L: L,
              onAdd: onAddCg,
              onJoin: onJoin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppThemeColors L, VoidCallback onAddCg) {
    return PremiumEmptyState(
      title: 'No guardians found',
      subtitle:
          'Invite family or medical professionals to monitor your medication safety.',
      mascotFeature: 'caregiver',
      icon: Icons.shield_outlined,
      actionLabel: 'Invite Guardian',
      onAction: onAddCg,
    );
  }

  Widget _buildEmptyMonitoringState(
      BuildContext context, AppThemeColors L, VoidCallback onJoin) {
    return PremiumEmptyState(
      title: 'Protect your family',
      subtitle:
          'Join as a caregiver to see real-time health updates for your loved ones.',
      mascotFeature: 'family',
      icon: Icons.groups_rounded,
      actionLabel: 'Join Circle',
      onAction: onJoin,
    );
  }
}

class _CompactPivotPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _CompactPivotPill({
    required this.label,
    required this.active,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: AnimatedPressable(
        onTap: () {
          HapticEngine.selection();
          onTap();
        },
        scaleFactor: 0.97,
        child: AnimatedContainer(
          duration: MedAiA11y.motion(context, AppDurations.fast),
          curve: AppCurves.emilOut,
          constraints: const BoxConstraints(minHeight: AppA11y.minTapTargetCompact),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.p12),
          decoration: BoxDecoration(
            color: active ? AppColors.limeDeep : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.limeDeep
                  : L.border.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: active ? Colors.white : L.text.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyHeader extends StatelessWidget {
  final double scrollOffset;
  final bool isActive;
  final AppThemeColors L;
  final VoidCallback onAdd, onJoin;

  const _FamilyHeader({
    required this.scrollOffset,
    required this.isActive,
    required this.L,
    required this.onAdd,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, topPad + AppSpacing.p12, AppSpacing.gutter, AppSpacing.p12),
      decoration: BoxDecoration(
        color: scrollOffset > 18
            ? L.bg.withValues(alpha: 0.96)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Circle',
                  style: AppTypography.headlineMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Monitoring active' : 'Care for loved ones',
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _CircleIconBtn(
            icon: Icons.link_rounded,
            label: 'Join family circle',
            onTap: onJoin,
            L: L,
          ),
          const SizedBox(width: AppSpacing.p8),
          _CircleIconBtn(
            icon: Icons.person_add_rounded,
            label: 'Invite guardian',
            onTap: onAdd,
            L: L,
          ),
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _CircleIconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedPressable(
        onTap: onTap,
        child: PremiumTextureCard(
          padding: EdgeInsets.zero,
          radius: 999,
          texture: PremiumTextureStyle.none,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: L.text.withValues(alpha: 0.9)),
          ),
        ),
      ),
    );
  }
}

class _CircleStatBento extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? iconColor;
  final AppThemeColors L;
  final bool glow;
  final bool accentGlow;
  const _CircleStatBento({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    required this.L,
    this.glow = false,
    this.accentGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 14,
      color: iconColor ?? L.primary,
    );

    return PremiumTextureCard(
      padding: const EdgeInsets.all(AppSpacing.p16),
      radius: 22,
      texture: PremiumTextureStyle.dots,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.p8),
                decoration: BoxDecoration(
                  color: (iconColor ?? L.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: iconWidget,
              ),
              const SizedBox(width: AppSpacing.p12),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: L.sub,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.p16),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _familyEntrance(BuildContext context, Widget child, {int delayMs = 0}) {
  if (MedAiA11y.reducedMotion(context)) return child;
  return child
      .animate(delay: delayMs.ms)
      .fadeIn(duration: AppDurations.fast, curve: AppCurves.emilOut)
      .slideY(begin: 0.03, end: 0, curve: AppCurves.emilOut);
}
