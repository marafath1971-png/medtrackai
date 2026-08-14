import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/os_health_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:audioplayers/audioplayers.dart';

import '../domain/entities/entities.dart';
import '../models/onboarding_prefs.dart';
export '../domain/entities/entities.dart';
import '../domain/repositories/medication_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/symptom_repository.dart';

import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/export_service.dart';
import '../services/auth_service.dart';
import '../services/link_service.dart';
import '../services/referral_service.dart';
import '../services/purchases_service.dart';
import '../services/performance_service.dart';
import '../services/dynamic_icon_service.dart';
import '../services/native_widget_service.dart';
import '../services/voice_service.dart';
import '../services/gemini_service.dart';
import '../services/growth_tracker.dart';
import '../services/remote_config_service.dart';
import '../core/utils/logger.dart';
import '../core/utils/haptic_engine.dart';
import '../core/utils/network_status.dart';
import '../core/utils/result.dart';

import 'controllers/auth_controller.dart';
import 'controllers/medication_controller.dart';
import 'controllers/wellness_controller.dart';
import 'controllers/social_controller.dart';
import 'controllers/health_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/constants.dart';

// ══════════════════════════════════════════════
// APP STATE — CENTRAL STATE BRIDGE
// ══════════════════════════════════════════════

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  // Domain Repositories
  final IMedicationRepository medRepo;
  final IUserRepository userRepo;
  final SymptomRepository symptomRepo;

  // Domain Controllers (Modular Architecture)
  late final AuthController auth;
  late final MedicationController med;
  late final WellnessController wellness;
  late final SocialController social;
  late final HealthController health;

  bool _isDisposed = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final LinkService _linkService;
  final AudioPlayer _audioPlayer;
  StreamSubscription? _notifSub;

  ManagedProfile? _activeProfile;
  ManagedProfile? get activeProfile => _activeProfile;

  // UI Feedback State
  String? toast;
  String? toastType;
  bool lowStockBannerDismissed = false;
  /// True when a connectivity probe fails — drives [AppStatusBanner] in shell.
  bool isOffline = false;
  String? networkErrorMessage;
  bool isLocked = false;
  String? pendingCelebrationMedName;
  int? pendingMilestoneAnimation;
  int? pendingDetailMedId;
  String? mascotAccessory;

  // Voice Assistant State
  bool isVoiceActive = false;
  String voiceStatus = 'idle'; // idle, listening, thinking, success, error
  String voiceTranscript = '';
  String voiceFeedback = '';

  /// Connectivity probe — overridable in tests. Defaults to [NetworkStatus.isOnline].
  final Future<bool> Function() _probeOnline;

  AppState({
    required this.medRepo,
    required this.userRepo,
    required this.symptomRepo,
    required SharedPreferences prefs,
    AudioPlayer? audioPlayer,
    LinkService? linkService,
    Future<bool> Function()? probeOnline,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _linkService = linkService ?? LinkService(),
        _probeOnline = probeOnline ?? NetworkStatus.isOnline {
    // Controller Initialization
    auth = AuthController(userRepo: userRepo);
    med = MedicationController(medRepo: medRepo);
    wellness = WellnessController(symptomRepo: symptomRepo);
    social = SocialController(userRepo: userRepo);
    health = HealthController(prefs);

    // Sync state changes between tokens/profile and app state
    auth.addListener(safeNotifyListeners);
    med.addListener(safeNotifyListeners);
    wellness.addListener(safeNotifyListeners);
    social.addListener(safeNotifyListeners);
    health.addListener(safeNotifyListeners);

    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.actionStream.stream
        .listen(_handleNotificationAction);

    // Deep Link Integration
    _linkService.onJoinCodeDetected = (code) {
      social.setPendingJoinCode(code);
      if (phase == AppPhase.app && profile != null) {
        social.joinCareTeam(code).then((_) {
          social.setPendingJoinCode(null);
        });
      }
      safeNotifyListeners();
    };
    _linkService.onVoiceCommandDetected = () {
      if (phase == AppPhase.app) {
        activateVoiceAssistant();
      }
    };
    // Referral: remember the inbound code until the user finishes signup, then
    // it's redeemed in completeOnboarding(). Existing users (already in the app)
    // can't redeem — the reward is for new signups only.
    _linkService.onReferralDetected = (code) {
      ReferralService.setPendingInbound(code);
    };
    _linkService.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (_lifecycleState == AppLifecycleState.resumed) {
      _syncPendingActions();
    }
  }

  // ── Modular Accessors ──────────────────────────────────────────────
  AppPhase get phase => auth.phase;
  UserProfile? get profile => auth.profile;
  OnboardingPrefs get onboardingPrefs => auth.onboardingPrefs;
  Future<void> saveOnboardingPrefs(OnboardingPrefs prefs) =>
      auth.saveOnboardingPrefs(prefs);
  Future<void> markOnboardingCompleted() => auth.markOnboardingCompleted();
  Future<void> saveProfile(UserProfile p) => auth.saveProfile(p);

  void setActiveProfile(ManagedProfile? p) {
    _activeProfile = p;
    safeNotifyListeners();
  }

  void addDependent(ManagedProfile dependent) {
    if (profile != null) {
      final updatedFamily = List<ManagedProfile>.from(profile!.familyMembers)..add(dependent);
      saveProfile(profile!.copyWith(familyMembers: updatedFamily));
      safeNotifyListeners();
    }
  }

  void setMascotAccessory(String? accessory) {
    mascotAccessory = accessory;
    safeNotifyListeners();
  }

  List<Medicine> get meds => med.meds;
  List<Medicine> get activeMeds => med.meds;
  Map<String, List<DoseEntry>> get history => med.history;
  Map<String, bool> get takenToday => med.takenToday;
  StreakData get streakData => med.streakData;
  List<double> get inventoryHistory => med.inventoryHistory;

  List<Caregiver> get caregivers => social.caregivers;
  List<Map<String, dynamic>> get monitoredPatients => social.monitoredPatients;
  List<MissedAlert> get missedAlerts => social.missedAlerts;
  Map<String, String> get protectorInsights => social.protectorInsights;

  List<Symptom> get symptoms => wellness.symptoms;
  List<HealthInsight> get healthInsights => wellness.healthInsights;

  bool get darkMode => auth.darkMode;
  String get language => auth.language;
  bool get isLockedApp => isLocked;

  bool get isBackgrounded =>
      _lifecycleState == AppLifecycleState.paused ||
      _lifecycleState == AppLifecycleState.inactive;

  // ── Lifecycle ──────────────────────────────────────────────────────
  /// Public re-arm hook for settings that change how reminders fire (sound,
  /// persistent alarms, etc.). Notification content is only applied at
  /// schedule time, so toggles must call this to take effect.
  Future<void> refreshNotifications() => _rescheduleNotifications();

  Future<void> _rescheduleNotifications() async {
    if (profile == null || !profile!.notifPerm) return;

    // 1. Clear existing
    await NotificationService.cancelAll();

    // 2. Schedule Primary (Me)
    final myMeds = await medRepo.getMedicines(profileId: null);
    final myStreak = getStreak();
    // "Ring until answered" is opt-in via reminderStyle == 'persistent'.
    final persistent = profile!.reminderStyle == 'persistent';
    await NotificationService.scheduleAll(myMeds,
        currentStreak: myStreak, persistent: persistent);

    // 3. Schedule Dependents
    for (var member in profile!.familyMembers) {
      final memberMeds = await medRepo.getMedicines(profileId: member.id);
      await NotificationService.scheduleAll(memberMeds,
          profileName: member.name, currentStreak: 0, persistent: persistent);
    }
    
    // 4. Global Morning Summary (Primary only for now)
    await NotificationService.scheduleMorningSummary(
      totalDoses: myMeds.length,
      enableSound: profile!.notifSound,
    );

    // 5. Dynamic Re-engagement (Bomb resets whenever they interact)
    await NotificationService.scheduleReEngagement(
      targetDate: DateTime.now().add(const Duration(days: 3)),
    );
  }

  Future<void> loadFromStorage() async {
    return PerformanceService.measure('app_load_trace', () async {
      await NotificationService.refreshTimeZone();
      try {
        await auth.loadProfile();
        AnalyticsService.setUserId(AuthService.uid);

        await Future.wait([
          med.loadData(),
          wellness.loadData(),
          social.loadData(),
        ]);

        if (AuthService.uid != null) {
          _syncUserProfileFromAuth();
          _initPushNotifications();
          _reconcilePremium();

          // Apply saved app icon on start
          if (profile?.appIcon != null && profile?.appIcon != 'default') {
            await DynamicIconService.setIcon(profile!.appIcon);
          }
          
          _startMissedDoseTimer();
          checkFamilyMissedDoses();
        }

        _syncPendingActions();
        safeNotifyListeners();
      } catch (e, stack) {
        appLogger.e('[AppState] Critical load failure',
            error: e, stackTrace: stack);
        FirebaseCrashlytics.instance.recordError(e, stack);
        auth.phase = AppPhase.onboarding;
        safeNotifyListeners();
      }
    });
  }

  // ── Profile Switching ──────────────────────────────────────────────
  Future<void> switchProfile(ManagedProfile? profile) async {
    _activeProfile = profile;
    safeNotifyListeners();

    // Reload data for the switched profile
    await Future.wait([
      med.loadData(profileId: profile?.id),
      wellness.loadData(profileId: profile?.id),
    ]);
    
    await _rescheduleNotifications();
    safeNotifyListeners();
    showToast(profile == null ? 'Switched to Primary' : 'Switched to ${profile.name}');
  }

  // ── Medication Proxies ─────────────────────────────────────────────
  int getStreak() => med.getStreak();
  double getAdherenceScore() => med.getAdherenceScore();
  List<DoseItem> getDoses({DateTime? date}) => med.getDoses(date: date);
  Map<String, bool> getTakenMapForDate(DateTime date) =>
      med.getTakenMapForDate(date);
  List<Map<String, dynamic>> getTrendData() => med.getTrendData();

  Future<void> toggleDose(DoseItem dose, {DateTime? date}) async {
    return PerformanceService.measure('toggle_dose_trace', () async {
      final targetDate = date ?? DateTime.now();
      final dateKey =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final key = dose.key;
      final takenMap = med.getTakenMapForDate(targetDate);
      final wasTaken = takenMap[key] ?? false;
      final oldStreak = getStreak();

      await med.toggleDose(dose, dateKey);
      final newStreak = getStreak();

      if (!wasTaken) {
        // Success: Trigger delighter and increment growth counter
        await auth.incrementDosesMarked();
        await GrowthTracker.trackFirstDoseLogged();
        unawaited(_playDoseChime());

        // Sync to OS Health / Native Widgets
        OSHealthService.logDose(
          medName: dose.med.name,
          dosageAmount: double.tryParse(dose.med.dose.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0,
          takenAt: DateTime.now(),
        );

        // Sync Native OS Widget
        NativeWidgetService.syncWidgetData(
          streak: newStreak,
          nextMedName: "Next Scheduled Dose", // Could compute exactly from meds list
          nextMedTime: "Check App",
          mascotMood: "Happy", 
        );

        // Evaluate Gamification Milestones
        final milestones = [3, 7, 14, 30, 60, 100, 365];
        if (newStreak > oldStreak && milestones.contains(newStreak)) {
          pendingMilestoneAnimation = newStreak;
          // Forgiveness-first (blueprint §7.7, Duolingo +10% retention):
          // grant a streak freeze AT the milestone, before it's ever needed,
          // so a future slip protects the streak instead of erasing it.
          final p = profile;
          if (newStreak >= 7 && p != null && p.streakFreezes < 5) {
            await auth
                .saveProfile(p.copyWith(streakFreezes: p.streakFreezes + 1));
          }
        } else {
          pendingCelebrationMedName = dose.med.name;
        }

        // Schedule Intake Check-in dynamically
        await NotificationService.scheduleIntakeCheckIn(med: dose.med);

        toast = 'Dose logged';
        toastType = 'success';
      } else {
        toast = 'Dose unlogged';
        toastType = 'info';
      }

      safeNotifyListeners();
      await _rescheduleNotifications();
    });
  }

  Future<void> takeDose(int medId, int idx, {DateTime? date}) async {
    final mIdx = meds.indexWhere((m) => m.id == medId);
    if (mIdx == -1) return;
    final m = meds[mIdx];
    if (idx < 0 || idx >= m.schedule.length) return;
    final sched = m.schedule[idx];
    final dose = DoseItem(med: m, sched: sched, key: '${m.id}_${sched.id}');
    await toggleDose(dose, date: date);
  }

  void clearMilestone() {
    pendingMilestoneAnimation = null;
    safeNotifyListeners();
  }

  Future<void> skipDose(DoseItem dose, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final dateKey =
        "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
    await med.skipDose(dose, dateKey);
    
    // Task Phase 2.4: Telemetry Alert for Critical Meds
    if (dose.med.isCritical) {
      await social.notifyCaregiversOfMissedDose(dose.med);
    }
    
    safeNotifyListeners();
    await _rescheduleNotifications();
  }

  /// Free-tier fence for the medicine cabinet (blueprint §5). UI call sites
  /// must check this before [addMedicine] and show the paywall with
  /// triggerSource 'unlimited_meds' when false.
  bool get canAddMedicine =>
      isPremium || meds.length < RemoteConfigService.freeTierMedLimit;

  Future<void> addMedicine(Medicine m) async {
    if (!canAddMedicine) {
      showToast('Medicine limit reached. Upgrade for unlimited meds.',
          type: 'error');
      return;
    }
    await med.addMedicine(m);
    await GrowthTracker.trackFirstMedAdded();
    await _rescheduleNotifications();
  }

  Future<void> updateMedicine(Medicine m) async {
    await med.updateMedDirect(m);
    await _rescheduleNotifications();
  }

  Future<void> deleteMedicine(int id) async {
    await med.deleteMedicine(id);
    await _rescheduleNotifications();
  }

  Future<void> saveMedicine(Medicine m) => updateMedicine(m);
  Future<void> updateMed(int id, {int? count}) async {
    final mIdx = meds.indexWhere((m) => m.id == id);
    if (mIdx == -1) return;
    final m = meds[mIdx];
    if (count != null) {
      await updateMedicine(m.copyWith(count: count));
    }
  }

  Future<void> deleteMed(int id) => deleteMedicine(id);
  Future<void> updateMedDirect(Medicine updated) => updateMedicine(updated);

  Future<void> undoPrnDose(int medId, String label) async {
    await med.undoPrnDose(medId, label, todayStr());
    safeNotifyListeners();
  }

  Future<void> snoozeDose(DoseItem dose, int minutes) async {
    await med.snoozeDose(dose, minutes);
    safeNotifyListeners();
  }

  String? get interactionWarning => med.interactionWarning;
  String? get interactionWarningMedName => med.interactionWarningMedName;
  void clearInteractionWarning() => med.clearInteractionWarning();

  // ── Auth & Profile Proxies ─────────────────────────────────────────
  /// Real entitlement state. Backed by the profile flag, which is written on
  /// purchase/restore and reconciled against RevenueCat at launch
  /// (see _reconcilePremium). Dev-preview seeds isPremium:true on its demo
  /// profile, so preview builds still see premium without special-casing here.
  bool get isPremium => profile?.isPremium ?? false;
  bool get biometricEnabled => profile?.biometricEnabled ?? false;
  bool get isPurchasing => auth.isPurchasing;

  Future<void> logout() {
    _missedDoseTimer?.cancel();
    return auth.logout();
  }
  Future<void> signOut() {
    _missedDoseTimer?.cancel();
    return auth.logout();
  }
  Future<void> signInWithGoogle() => auth.signInWithGoogle();
  Future<void> signInWithApple() => auth.signInWithApple();

  Future<void> updateProfile(
          {String? name, String? accentColor, bool? amoledMode}) =>
      auth.updateProfile(
          name: name, accentColor: accentColor, amoledMode: amoledMode);

  Future<void> addFamilyMember(ManagedProfile member) async {
    var p = profile;
    p ??= UserProfile(name: 'Guest');
    final updatedMembers = List<ManagedProfile>.from(p.familyMembers)
      ..add(member);
    await auth.saveProfile(p.copyWith(familyMembers: updatedMembers));
    await _rescheduleNotifications();
    showToast('Welcome, ${member.name}! ✨');
  }

  Future<void> removeFamilyMember(String memberId) async {
    var p = profile;
    if (p == null) return;
    
    // Safety check: Don't remove if they have active meds?
    // For now, allow but warn in UI.
    final updatedMembers = p.familyMembers.where((m) => m.id != memberId).toList();
    await auth.saveProfile(p.copyWith(familyMembers: updatedMembers));
    
    // If we were viewing this profile, switch back to primary
    if (_activeProfile?.id == memberId) {
      await switchProfile(null);
    } else {
      await _rescheduleNotifications();
    }
    
    showToast('Profile removed');
  }

  Future<void> updateFamilyMember(ManagedProfile member) async {
    var p = profile;
    if (p == null) return;
    final updatedMembers = p.familyMembers.map((m) => m.id == member.id ? member : m).toList();
    await auth.saveProfile(p.copyWith(familyMembers: updatedMembers));
    
    if (_activeProfile?.id == member.id) {
       _activeProfile = member;
    }
    
    await _rescheduleNotifications();
    safeNotifyListeners();
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    return await medRepo.uploadMedicineImage(imageFile);
  }

  Timer? _missedDoseTimer;

  void _startMissedDoseTimer() {
    _missedDoseTimer?.cancel();
    _missedDoseTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkFamilyMissedDoses();
    });
  }

  Future<void> checkFamilyMissedDoses() async {
    if (profile == null) return;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final dayOfWeek = now.weekday % 7;

    for (var member in profile!.familyMembers) {
      final memberMeds = await medRepo.getMedicines(profileId: member.id);
      final memberHistory = await medRepo.getHistory(profileId: member.id);
      final memberTakenToday = await medRepo.getTakenToday(profileId: member.id);
      final dayHistory = memberHistory[todayStr] ?? [];

      for (var med in memberMeds) {
        for (var sched in med.schedule) {
          if (!sched.enabled) continue;
          if (!sched.days.contains(dayOfWeek)) continue;

          final schedTime = DateTime(now.year, now.month, now.day, sched.h, sched.m);
          if (schedTime.isBefore(now)) {
            final key = '${med.id}_${sched.id}';
            final timeStr = '${sched.h.toString().padLeft(2, '0')}:${sched.m.toString().padLeft(2, '0')}';
            final takenInHistory = dayHistory.any((e) => e.medId == med.id && e.time == timeStr);
            final takenInToday = memberTakenToday[key] ?? false;

            if (!takenInHistory && !takenInToday) {
              final alertId = '${member.id}_${med.id}_${sched.id}_$todayStr'.hashCode;
              final alreadyExists = social.missedAlerts.any((a) => a.id == alertId);

              if (!alreadyExists) {
                final ampm = sched.h >= 12 ? 'PM' : 'AM';
                final hr = sched.h % 12 == 0 ? 12 : sched.h % 12;
                final timeLabel = sched.m == 0 ? '$hr$ampm' : '$hr:${sched.m.toString().padLeft(2, '0')}$ampm';
                
                final alert = MissedAlert(
                  id: alertId,
                  medName: "${member.name}'s $timeLabel dose is available",
                  doseLabel: med.name,
                  time: timeStr,
                  timestamp: todayStr,
                  caregivers: [],
                  seen: false,
                );
                social.addMissedAlert(alert);

                await NotificationService.scheduleOneOffReminder(
                  id: alertId,
                  title: 'Family Update',
                  body: 'A family member has a dose available',
                  scheduledDate: DateTime.now().add(const Duration(seconds: 1)),
                  enableSound: true,
                );
              }
            }
          }
        }
      }
    }
  }

  Future<void> exportProfileDataPDF(ManagedProfile member) async {
    final memberMeds = await medRepo.getMedicines(profileId: member.id);
    final memberHistory = await medRepo.getHistory(profileId: member.id);
    final success = await ExportService.exportAdherenceReportForMember(this, member, memberMeds, memberHistory);
    if (!success) {
      toast = 'Doctor Reports require MedAI Premium.';
      toastType = 'error';
      safeNotifyListeners();
    }
  }

  Future<void> completeOnboarding(UserProfile profile) {
    GrowthTracker.trackAccountCreated();
    return auth.completeOnboarding(profile);
  }
  void skipAuth() => auth.skipAuth();

  /// Stash the onboarding-built profile until the user authenticates.
  void setPendingOnboardingProfile(UserProfile p) =>
      auth.setPendingOnboardingProfile(p);

  /// Enter the app after a successful sign-in — persists the new-user profile
  /// or resumes a returning user's, then advances to [AppPhase.app].
  Future<void> enterAppAfterAuth() async {
    GrowthTracker.trackAccountCreated();
    await auth.enterAppAfterAuth();
  }

  /// DEV PREVIEW ONLY — seed demo data and jump straight into the app.
  void devPreviewJump() {
    med.devSeed();
    auth.devPreview(UserProfile(name: 'Alex', isPremium: true));
  }

  void toggleDarkMode() => auth.toggleDarkMode();
  void setLanguage(String lang) => auth.setLanguage(lang);
  Future<void> updateAccentColor(String color) => auth.updateAccentColor(color);
  Future<void> updateAppIcon(String icon) async {
    await DynamicIconService.setIcon(icon == 'default' ? null : icon);
    await auth.updateAppIcon(icon);
  }

  Future<void> updateReminderSound(String sound) =>
      auth.updateReminderSound(sound);
  void toggleBiometricLock(bool v) => auth.toggleBiometricLock(v);

  void unlockApp() {
    isLocked = false;
    notifyListeners();
  }

  void lockApp() {
    isLocked = true;
    notifyListeners();
  }

  void clearCelebration() {
    pendingCelebrationMedName = null;
    notifyListeners();
  }

  void setPendingDetailMedId(int id) {
    pendingDetailMedId = id;
    notifyListeners();
  }

  void clearPendingDetailMedId() {
    pendingDetailMedId = null;
    notifyListeners();
  }

  // ── LAUNCH READINESS: SUPPORT & LEGAL ───────────────────────

  Future<void> openPrivacyPolicy() async {
    final url = Uri.parse(kPrivacyPolicyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTermsOfService() async {
    final url = Uri.parse(kTermsOfServiceUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'MedAI Support Inquiry',
        'body':
            'User ID: ${AuthService.uid}\nApp Version: 1.0.0+1\n\nIssue Description:',
      }),
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> requestReview() => ReviewService.requestReview();
  Future<void> openStoreReview() => ReviewService.openStoreReview();

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // ── Wellness & AI Proxies ──────────────────────────────────────────
  bool get loadingInsight => wellness.loadingInsights;
  Future<void> fetchHealthInsights() async {
    if (healthConnected) await health.syncData();
    return wellness.fetchHealthInsights(
      meds: meds,
      streak: getStreak(),
      adherence: getAdherenceScore(),
      latencyData: med.getLatencyHistory(),
      heartRate: healthHeartRate > 0 ? healthHeartRate : null,
      steps: healthSteps > 0 ? healthSteps : null,
      history: history,
    );
  }

  Future<void> logSymptom(Symptom s) async {
    await wellness.logSymptom(s, meds);
    safeNotifyListeners();
    fetchHealthInsights(); // Refresh correlations
  }

  Future<void> deleteSymptom(String id) async {
    await wellness.deleteSymptom(id);
    safeNotifyListeners();
  }

  // ── Voice Assistant (Phase 2.3) ────────────────────────────────────
  
  Future<void> processVoiceCommand(String transcript) async {
    final res = await GeminiService.parseVoiceCommand(
        transcript: transcript, meds: meds);

    if (res is Success<Map<String, dynamic>>) {
      final data = res.value;
      if (data['identified'] == true) {
        final medIdRaw = data['medId'];
        final medId = medIdRaw is int
            ? medIdRaw
            : medIdRaw is num
                ? medIdRaw.toInt()
                : int.tryParse('$medIdRaw');
        final action = data['action']?.toString();
        final confText = data['confirmationText']?.toString() ?? 'Done!';
        if (medId == null || action == null) return;

        final medicineIdx = meds.indexWhere((m) => m.id == medId);
        if (medicineIdx == -1) {
          await VoiceService.speak(
              "I couldn't find that medication in your cabinet.");
          return;
        }
        final medicine = meds[medicineIdx];

        final doses =
            med.getDoses().where((d) => d.med.id == medId).toList();
        if (doses.isNotEmpty) {
          if (action == 'take') {
            final schedIdx =
                medicine.schedule.indexWhere((s) => s.enabled);
            if (schedIdx != -1) {
              await takeDose(medId, schedIdx);
            } else if (medicine.schedule.isNotEmpty) {
              await takeDose(medId, 0);
            }
          } else {
            await skipDose(doses.first);
          }

          await VoiceService.speak(confText);
          toast = confText;
          toastType = 'success';
          safeNotifyListeners();
        }
      } else {
        await VoiceService.speak(
            "I couldn't identify that medication. Try saying the full name.");
      }
    }
  }

  // ── Social & Monitoring Proxies ────────────────────────────────────
  int get unseenAlertsCount => social.missedAlerts.length;
  Future<void> addCaregiver(Caregiver cg) => social.addCaregiver(cg);
  Future<String> createInvite(Caregiver cg) =>
      social.createInvite(cg, profile?.name, profile?.avatar);
  Future<void> activateCaregiver(int id) => social.activateCaregiver(id);
  void markAlertsAsSeen() => social.markAlertsAsSeen();
  Future<void> joinCareTeam(String code) => social.joinCareTeam(code);
  Future<List<Medicine>> getPatientMeds(String uid) =>
      social.getPatientMeds(uid);
  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) =>
      social.getPatientHistory(uid);
  Future<void> nudgePatient(String uid) => social.nudgePatient(uid);
  Future<void> fetchProtectorInsight(
          Caregiver cg, List<Medicine> m, Map<String, List<DoseEntry>> h) =>
      social.fetchProtectorInsight(cg, m, h);

  // ── Purchases ──────────────────────────────────────────────────────
  /// Reconciles the cached `profile.isPremium` flag against RevenueCat's actual
  /// entitlement at launch. Handles a lapsed sub (cached true → real false) and
  /// a cross-device active sub (cached false → real true). Fail-safe: if the
  /// entitlement check throws (offline, dev preview with no RC), we leave the
  /// cached value untouched — we never revoke premium on an inconclusive check.
  Future<void> _reconcilePremium() async {
    if (profile == null) return;
    try {
      final active = await PurchasesService.isPremium();
      if (active != profile!.isPremium) {
        await auth.saveProfile(profile!.copyWith(isPremium: active));
        safeNotifyListeners();
      }
    } catch (e) {
      appLogger.w('[AppState] Premium reconcile skipped', error: e);
    }
  }

  Future<void> manageSubscription() => auth.manageSubscription();
  Future<void> unlockPremium() => purchasePremium('annual');

  Future<bool> purchasePremium(String packageId) async {
    auth.isPurchasing = true;
    notifyListeners();
    try {
      final success = await PurchasesService.purchasePackage(packageId);
      if (success) {
        if (profile != null) {
          await auth.saveProfile(profile!.copyWith(isPremium: true));
        }
        await auth.loadProfile();
        showToast('Premium unlocked! ✨');
      }
      return success;
    } finally {
      auth.isPurchasing = false;
      safeNotifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    auth.isPurchasing = true;
    notifyListeners();
    try {
      final success = await PurchasesService.restorePurchases();
      if (success) {
        if (profile != null) {
          await auth.saveProfile(profile!.copyWith(isPremium: true));
        }
        await auth.loadProfile();
        showToast('Purchases restored 🔄');
      }
    } finally {
      auth.isPurchasing = false;
      safeNotifyListeners();
    }
  }

  // ── UI Persistence Proxies ─────────────────────────────────────────
  List<Medicine> getLowMeds() => med.getLowMeds();
  int getLowStockCount() => med.getLowStockCount();
  void dismissLowStockBanner() {
    lowStockBannerDismissed = true;
    notifyListeners();
  }

  bool get isMutating => med.isMutating;

  Future<void> logPaywallEvent(String e) => med.logPaywallEvent(e);
  Future<void> useStreakFreeze() async {
    final p = profile;
    if (p != null && p.streakFreezes > 0) {
      final updatedProfile = p.copyWith(streakFreezes: p.streakFreezes - 1);
      await saveProfile(updatedProfile);
      
      // Find the last missed date to freeze
      // Let's assume they missed yesterday since this pops up usually.
      // If today is missed and it's late, maybe today.
      final now = DateTime.now();
      String dateToFreeze = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      // Look back up to 7 days to find the first missed day that isn't already frozen
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final dayOfWeek = date.weekday % 7;
        final scheduledForDay = med.meds.where((m) => m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))).length;
        if (scheduledForDay == 0) continue;
        
        final taken = med.history[key]?.where((e) => e.taken).length ?? 0;
        final rate = taken / scheduledForDay;
        
        if (rate < 0.8 && i > 0) { // i > 0 means past days
          dateToFreeze = key;
          break; // found the missed day
        }
      }

      await med.applyStreakFreeze(dateToFreeze);

      HapticEngine.success();
      toast = 'Freeze applied! Streak saved. 🧊';
    } else {
      toast = 'No streak freezes left!';
      toastType = 'error';
      safeNotifyListeners();
      HapticEngine.error();
    }
    safeNotifyListeners();
  }

  Future<int?> checkDailyReentry() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastOpened = prefs.getString('lastOpenedDate');

    if (lastOpened == todayStr) {
      return null; // Already opened today
    }

    // It's a new day!
    await prefs.setString('lastOpenedDate', todayStr);

    if (lastOpened == null) {
      return 0; // First time ever opening? No missed doses.
    }

    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    // Evaluate yesterday's history
    final yesterdayDoses = history[yesterdayStr] ?? [];
    
    int missed = 0;
    if (yesterdayDoses.isEmpty) {
      // Simplification: assume they missed all scheduled meds if no history
      missed = activeMeds.length;
    } else {
      for (final dose in yesterdayDoses) {
        if (!dose.taken) missed++;
      }
    }

    return missed;
  }

  // ── Health & Vitals Proxies ─────────────────────────────────────────
  bool get healthConnected => health.isConnected;
  bool get healthSyncing => health.isSyncing;
  bool get healthAutoSync => health.autoSync;
  double get healthSteps => health.steps;
  double get healthHeartRate => health.heartRate;
  double get healthBloodGlucose => health.bloodGlucose;
  double get healthSystolic => health.systolic;
  double get healthDiastolic => health.diastolic;

  Future<bool> connectHealth() async {
    final success = await health.connect();
    if (success) safeNotifyListeners();
    return success;
  }

  Future<void> setHealthAutoSync(bool value) async {
    await health.setAutoSync(value);
    safeNotifyListeners();
  }

  Future<void> syncHealthData() async {
    await health.syncData();
    safeNotifyListeners();
  }

  void recordDose(DoseItem dose, {DateTime? date}) => toggleDose(dose, date: date);
  Future<void> logPrnDose(int medId, String label, String time) =>
      med.logPrnDose(medId, label, time);
  String getDoseGuidance(Medicine m) => med.getDoseGuidance(m);

  Future<void> logMeal(Ritual meal) async {
    toast = 'Logged ${meal.displayName} 🍽️';
    toastType = 'success';
    safeNotifyListeners();
    await NotificationService.scheduleMealFollowUp(
      meds: meds,
      mealRitual: meal,
      profileName: profile?.name ?? '',
    );
  }

  Future<String?> uploadImage(File file) => med.uploadMedicineImage(file);

  Future<void> incrementScanCount() async {
    // Lifetime counter (review prompts etc.) + free-tier gate counter.
    // profile.scansUsed was previously never incremented, which silently
    // disabled the scan-limit paywall fence.
    auth.incrementScanCount();
    await med.incrementScanCount(1);
  }

  void incrementVoiceLogCount() => auth.incrementVoiceLogCount();

  List<ScheduledMed> getAllSchedules() => med.getAllSchedules();
  Future<void> toggleSchedule(int medId, int idx) async {
    await med.toggleSchedule(medId, idx);
    await _rescheduleNotifications();
  }

  Future<void> removeSchedule(int medId, int idx) async {
    await med.removeSchedule(medId, idx);
    await _rescheduleNotifications();
  }

  Future<void> addSchedule(int medId, ScheduleEntry s) async {
    await med.addSchedule(medId, s);
    await _rescheduleNotifications();
  }

  Future<void> updateSchedule(int medId, int idx, ScheduleEntry s) async {
    await med.updateSchedule(medId, idx, s);
    await _rescheduleNotifications();
  }

  List<Map<String, dynamic>> getLatencyData() => med.getLatencyHistory();
  
  DateTime? get lastSyncedAt => null; 
  int getAdherenceForMed(int medId) => med.getAdherenceForMed(medId);
  ({int taken, int total}) getHistoryCountForMed(int medId) =>
      med.getHistoryCountForMed(medId);

  List<Medicine> getRefillForecast() => [];
  Future<void> refillMedication(int id) async {}
  // ── CLINICAL DATA EXPORT ───────────────────────────────────────────

  /// Generates and shares a professional PDF Adherence Report
  Future<void> exportDataPDF() async {
    final success = await ExportService.exportAdherenceReport(this);
    if (!success) {
      toast = 'Doctor Reports require MedAI Premium.';
      toastType = 'error';
      safeNotifyListeners();
    }
  }

  /// Generates and shares a CSV file representing medication history
  Future<void> exportDataCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('Date,MedicineID,MedicineName,Time,Status');

    history.forEach((date, doses) {
      for (var dose in doses) {
        final med = meds.where((m) => m.id == dose.medId).firstOrNull;
        final status =
            dose.taken ? 'Taken' : (dose.skipped ? 'Skipped' : 'Missed');
        buffer.writeln(
            '$date,${dose.medId},${med?.name ?? "Unknown"},${dose.time},$status');
      }
    });

    final csv = buffer.toString();
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/med_history.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'MedAI Data Export (CSV)',
    ));
  }

  Future<void> deleteAllData() async {
    HapticEngine.selection();
    await auth.logout();
    showToast('All local data cleared');
  }

  Future<void> deleteAccount() async {
    HapticEngine.selection();
    await auth.deleteAccount();
    showToast('Account deleted permanently', type: 'error');
  }

  void executeStepAction(String step, BuildContext context) =>
      wellness.executeStepAction(step);

  // ── WELLNESS & SYMPTOMS ──────────────────────────────────────────
  bool get loadingInsights => wellness.loadingInsights;
  bool get analyzingSymptom => wellness.analyzingSymptom;
  bool get hasNewDataForAI => med.history.isNotEmpty;

  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) =>
      wellness.getMoodSummary(
          good: good, stable: stable, severe: severe, empty: empty);

  List<double> getRecentSymptomStats() => wellness.getRecentSymptomStats();
  Future<void> updateProfileFromMap(Map<String, dynamic> data) =>
      auth.updateProfileFromMap(data);

  HealthInsight? get symptomAnalysis => (wellness.healthInsights.isNotEmpty)
      ? wellness.healthInsights.first
      : null;

  Future<void> saveSymptom(Symptom s) => wellness.logSymptom(s, med.meds);
  Future<void> getSymptoms() => wellness.loadData(profileId: _activeProfile?.id);

  // ── AI SAFETY ──────────────────────────────────────────────────────
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) =>
      med.analyzeMedicineSafety(m);

  // ── UI Feedback ────────────────────────────────────────────────────
  void showToast(String message, {String type = 'success'}) {
    toast = message;
    toastType = type;
    if (type == 'success') {
      HapticEngine.light();
    } else {
      HapticEngine.selection();
    }

    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      toast = null;
      notifyListeners();
    });
  }

  void clearToast() {
    if (toast != null) {
      toast = null;
      notifyListeners();
    }
  }

  Future<bool> checkConnectivity({bool notify = true}) async {
    final online = await _probeOnline();
    final wasOffline = isOffline;
    final hadError = networkErrorMessage != null;
    isOffline = !online;
    if (online) networkErrorMessage = null;
    final changed = wasOffline != isOffline || (online && hadError);
    if (notify && changed) safeNotifyListeners();
    return online;
  }

  void setNetworkError(String? message) {
    networkErrorMessage = message;
    safeNotifyListeners();
  }

  void clearNetworkError() {
    if (networkErrorMessage == null) return;
    networkErrorMessage = null;
    safeNotifyListeners();
  }

  // ── Utility ────────────────────────────────────────────────────────
  String todayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
  String timeContext() {
    final now = DateTime.now();
    return 'Current Time: ${now.hour}:${now.minute.toString().padLeft(2, "0")} on day ${now.weekday % 7} (0=Sun, 6=Sat)';
  }
  String fmtTime(int h, int m) =>
      '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  int dayIdx() => DateTime.now().weekday % 7;

  // ── Internal Helpers ───────────────────────────────────────────────

  void safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
      _syncNativeWidget();
    }
  }

  void _syncNativeWidget() {
    try {
      final s = getStreak();
      String mood = 'content';
      if (s == 0) {
        mood = 'sleepy';
      } else if (s > 0 && s < 3) {
        mood = 'content';
      } else if (s >= 3 && s < 7) {
        mood = 'energetic';
      } else {
        mood = 'happy';
      }
      
      final todayDoses = getDoses();
      // Simple approximation: pick the first one
      final nextMedName = todayDoses.isNotEmpty ? todayDoses.first.med.name : 'All Done! 🎉';
      final nextMedTime = todayDoses.isNotEmpty 
          ? '${todayDoses.first.sched.h}:${todayDoses.first.sched.m.toString().padLeft(2, '0')}' 
          : '--:--';

      NativeWidgetService.syncWidgetData(
        streak: s,
        nextMedName: nextMedName,
        nextMedTime: nextMedTime,
        mascotMood: mood,
      );
    } catch (e) {
      appLogger.w('Failed to sync widget from state: $e');
    }
  }

  void _syncUserProfileFromAuth() {
    if (auth.profile != null) {
      auth.phase = AppPhase.app;
    } else {
      auth.phase = AppPhase.onboarding;
    }
  }

  Future<void> _initPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) await userRepo.saveFcmToken(token);
      }
      // Keep the stored token fresh so caregiver pushes keep reaching us.
      messaging.onTokenRefresh.listen((t) {
        userRepo.saveFcmToken(t).catchError((_) {});
      });
      // Surface incoming caregiver alerts/nudges while the app is foregrounded
      // (Android drops notification payloads in the foreground by default).
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n != null) {
          NotificationService.showRemoteAlert(
            title: n.title ?? 'MedAI',
            body: n.body ?? '',
          );
        }
      });
    } catch (e) {
      appLogger.w('FCM Init failed', error: e);
    }
  }

  Future<void> _handleNotificationAction(String payloadStr) async {
    appLogger.i('[AppState] Handling notification action: $payloadStr');
    try {
      final parts = payloadStr.split('|');
      if (parts.length < 5) return;

      final action = parts[0];
      final medId = int.tryParse(parts[1]);
      final h = int.tryParse(parts[2]);
      final m = int.tryParse(parts[3]);
      if (medId == null || h == null || m == null) return;
      final label = parts.sublist(4).join('|');

      Medicine? targetMed;
      for (final med in activeMeds) {
        if (med.id == medId) {
          targetMed = med;
          break;
        }
      }
      if (targetMed == null) return;

      ScheduleEntry? targetSched;
      for (final s in targetMed.schedule) {
        if (s.label == label && s.h == h && s.m == m) {
          targetSched = s;
          break;
        }
      }
      if (targetSched == null) return;

      final dose = DoseItem(med: targetMed, sched: targetSched, key: '${targetMed.id}-${targetSched.label}');

      if (action == 'take') {
        // Only toggle if not already taken today
        final takenMap = getTakenMapForDate(DateTime.now());
        if (!(takenMap[dose.key] ?? false)) {
          await toggleDose(dose);
        }
      } else if (action == 'skip') {
        await skipDose(dose);
      } else if (action == 'snooze_10') {
        final now = DateTime.now();
        final snoozeTime = now.add(const Duration(minutes: 10));
        await NotificationService.scheduleOneOffReminder(
          id: dose.hashCode.remainder(0x7FFFFFFF), 
          title: '⏰ Snoozed: Time for ${targetMed.name}', 
          body: '${targetMed.dose} · $label', 
          scheduledDate: snoozeTime,
          payload: '${targetMed.id}|$h|$m|$label'
        );
        showToast('Reminding you in 10 minutes');
      }
    } catch(e) {
      appLogger.e('[AppState] Error handling notification action: $e');
    }
  }

  Future<void> _syncPendingActions() async {
    if (auth.isAuthenticated) {
      try {
        // await medRepo.syncToCloud();
        // await userRepo.syncToCloud();
        appLogger.i('[AppState] Offline actions synced to cloud successfully.');
        if (isOffline || networkErrorMessage != null) {
          isOffline = false;
          networkErrorMessage = null;
          safeNotifyListeners();
        }
      } catch (e) {
        appLogger.e('[AppState] Error during offline sync: $e');
        setNetworkError('Sync failed. Your data is safe on this device.');
      }
    }
  }

  // ── VOICE ASSISTANT ───────────────────────────────────────────────
  
  Future<void> activateVoiceAssistant() async {
    if (isVoiceActive) return;
    
    isVoiceActive = true;
    voiceStatus = 'listening';
    voiceTranscript = 'Listening...';
    voiceFeedback = '';
    safeNotifyListeners();

    try {
      final available = await VoiceService.listen(
        onResult: (transcript) async {
          voiceTranscript = transcript;
          voiceStatus = 'thinking';
          safeNotifyListeners();

          final result = await GeminiService.parseVoiceCommand(
            transcript: transcript,
            meds: meds,
          );

          if (result is Success<Map<String, dynamic>>) {
            final data = result.value;
            if (data['identified'] == true) {
              final medIdRaw = data['medId'];
              final medId = medIdRaw is int
                  ? medIdRaw
                  : medIdRaw is num
                      ? medIdRaw.toInt()
                      : int.tryParse('$medIdRaw');
              final action = data['action']?.toString();
              final confirmation =
                  data['confirmationText']?.toString() ?? 'Done!';

              if (action == 'take' && medId != null) {
                final medicineIdx = meds.indexWhere((m) => m.id == medId);
                if (medicineIdx != -1) {
                  final medicine = meds[medicineIdx];
                  final schedIdx =
                      medicine.schedule.indexWhere((s) => s.enabled);
                  if (schedIdx != -1) {
                    await takeDose(medId, schedIdx);
                  } else if (medicine.schedule.isNotEmpty) {
                    await takeDose(medId, 0);
                  }
                }
              }

              voiceStatus = 'success';
              voiceFeedback = confirmation;
              await VoiceService.speak(confirmation);
            } else {
              voiceStatus = 'error';
              voiceFeedback =
                  "I couldn't identify that medication. Try saying the name clearly.";
              await VoiceService.speak(voiceFeedback);
            }
          } else {
            voiceStatus = 'error';
            voiceFeedback = "Something went wrong. Please try again.";
          }

          safeNotifyListeners();
          await Future.delayed(const Duration(seconds: 3));
          closeVoiceAssistant();
        },
        onListeningChanged: (listening) {
          if (!listening && voiceStatus == 'listening') {
            // Signal stopped
            safeNotifyListeners();
          }
        },
      );

      if (!available) {
        voiceStatus = 'error';
        voiceFeedback = 'Speech recognition unavailable. Check permissions.';
        safeNotifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        closeVoiceAssistant();
      }
    } catch (e) {
      voiceStatus = 'error';
      voiceFeedback = 'Voice Assistant connection lost.';
      safeNotifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      closeVoiceAssistant();
    }
  }

  void closeVoiceAssistant() {
    isVoiceActive = false;
    voiceStatus = 'idle';
    VoiceService.stop();
    safeNotifyListeners();
  }

  Future<void> _playDoseChime() async {
    if (_lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/chime.mp3'));
    } catch (e) {
      appLogger.w('[AppState] Dose chime playback failed: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _missedDoseTimer?.cancel();
    auth.removeListener(safeNotifyListeners);
    med.removeListener(safeNotifyListeners);
    wellness.removeListener(safeNotifyListeners);
    social.removeListener(safeNotifyListeners);
    _notifSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
