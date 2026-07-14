import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math';
import '../core/config/notification_copy.dart';

// ══════════════════════════════════════════════
// LOCAL NOTIFICATION SERVICE
// ══════════════════════════════════════════════

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<String> actionStream =
      StreamController<String>.broadcast();

  // Premium Haptic Feedback Profile for dynamic triggers
  static final Int64List _premiumHeartbeatVibration = Int64List.fromList([
    0,   // No delay
    40,  // Short pulse
    100, // Short pause
    60,  // Stronger pulse
    200, // Pause
    40,  // Echo pulse
  ]);

  static Future<void> init() async {
    await refreshTimeZone();

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'med_action',
          actions: [
            DarwinNotificationAction.plain('take', 'Take Now'),
            DarwinNotificationAction.plain('snooze_10', 'Snooze 10m'),
            DarwinNotificationAction.plain('skip', 'Skip'),
          ],
        ),
      ],
    );
    final initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
      macOS: initSettingsIOS,
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final action = response.actionId ?? 'tap';
          actionStream.add('$action|${response.payload}');
        }
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final response = launchDetails.notificationResponse;
      if (response != null && response.payload != null) {
        final action = response.actionId ?? 'tap';
        // Delay ensures AppState has time to initialize and listen
        Future.delayed(const Duration(seconds: 2), () {
          actionStream.add('$action|${response.payload}');
        });
      }
    }
  }

  static Future<bool> requestPermission() async {
    // IOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    // Android (Tiramisu+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  static Future<void> scheduleWeeklyReminder({
    required Medicine med,
    required ScheduleEntry sched,
    required int dayIdx,
    required int notifId,
    required bool enableSound,
    required bool enableVibration,
    required bool isTakenToday,
    bool isShabbatMode = false,
    String? profileName,
    bool showMedicationNames = true,
    required int currentStreak,
    bool persistent = false,
  }) async {
    bool useSound = enableSound;
    bool useVibration = enableVibration;

    // Shabbat Window: Friday 18:00 to Saturday 20:00
    if (isShabbatMode) {
      final isFriNight = dayIdx == 5 && sched.h >= 18;
      final isSat = dayIdx == 6 && sched.h < 20;
      if (isFriNight || isSat) {
        useSound = false;
        useVibration = true; // Gentle vibe only
      }
    }

    // "Ring until answered" (Pillo-style). Android FLAG_INSISTENT (0x4) loops
    // the alarm sound until the user acts on the notification. Only meaningful
    // with sound on, and it's opt-in via the persistent flag so we never force
    // a relentless alarm on users who didn't ask for it.
    final Int32List? insistentFlags =
        (persistent && useSound) ? Int32List.fromList([4]) : null;

    final androidDetails = AndroidNotificationDetails(
      'med_reminders_v2', // New channel for elevated priority
      'Medication Alarms',
      channelDescription:
          'High-priority persistent reminders for medication adherence',
      importance: useSound ? Importance.max : Importance.low,
      priority: useSound ? Priority.max : Priority.low,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: useVibration,
      playSound: useSound,
      visibility: NotificationVisibility.public,
      additionalFlags: insistentFlags,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('take', 'Take Now',
            showsUserInterface: true),
        const AndroidNotificationAction('snooze_10', 'Snooze 10m',
            showsUserInterface: true),
        const AndroidNotificationAction('skip', 'Skip',
            showsUserInterface: true, cancelNotification: true),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: useSound,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'med_action',
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();
    int targetWeekday = dayIdx == 0 ? 7 : dayIdx;

    // Calculate base scheduled date
    var baseDate = DateTime(now.year, now.month, now.day, sched.h, sched.m);
    int daysUntilTarget = (targetWeekday - now.weekday + 7) % 7;

    // If it's scheduled for today, but the user already marked it as taken today,
    // we must push the baseDate +7 days into the future so it doesn't ring today at all.
    bool pushToNextWeek = false;
    if (daysUntilTarget == 0) {
      if (isTakenToday) {
        pushToNextWeek = true;
      } else if (baseDate.isBefore(now)) {
        pushToNextWeek = true;
      }
    }

    if (pushToNextWeek) {
      daysUntilTarget = 7;
    }

    baseDate = baseDate.add(Duration(days: daysUntilTarget));

    // Single notification logic (March 11th style)
    var scheduledDate = baseDate;
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    try {
      final payload = '${med.id}|${sched.h}|${sched.m}|${sched.label}';
      
      final prefix = profileName != null ? '$profileName: ' : '';
      final title = showMedicationNames 
          ? '💊 ${prefix}Time to take ${med.name}' 
          : '💊 ${prefix}Time for your ${sched.label} dose';

      String body = showMedicationNames ? '${med.dose} · ${sched.label}' : 'Tap to record or snooze';
      if (sched.ritual != Ritual.none && showMedicationNames) {
        body = '${med.dose} · ${_getRitualMessage(sched.ritual)}';
      }
      
      // Inject Smart / Style-Rich Messaging
      final random = Random();
      if (currentStreak >= 3) {
        body += '\n\n${NotificationCopy.motivationalTips[random.nextInt(NotificationCopy.motivationalTips.length)]}';
      } else if (currentStreak == 0) {
        body += '\n\n${NotificationCopy.gentleNudges[random.nextInt(NotificationCopy.gentleNudges.length)]}';
      } else {
        body += '\n\n${NotificationCopy.firmReminders[random.nextInt(NotificationCopy.firmReminders.length)]}';
      }

      await _plugin.zonedSchedule(
        id: notifId.remainder(0x7FFFFFFF),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // Add dynamic streak nudge 1 hour later
      if (currentStreak > 0) {
        await scheduleStreakNudge(
          streak: currentStreak,
          id: (notifId + 500000).remainder(0x7FFFFFFF),
          targetDate: scheduledDate.add(const Duration(hours: 1)),
        );
      }

      // Schedule Caregiver Escalation 2 hours later
      await scheduleCaregiverEscalation(
        med: med,
        sched: sched,
        doseDate: scheduledDate,
        baseNotifId: notifId,
        profileName: profileName,
      );
    } catch (e) {
      await _plugin.show(
        id: notifId.remainder(0x7FFFFFFF),
        title: '💊 ${med.name}',
        body: '${med.dose} · ${sched.label}',
        notificationDetails: details,
      );
    }
  }

  static String _getRitualMessage(Ritual ritual) {
    switch (ritual) {
      case Ritual.beforeBreakfast:
        return 'Before your breakfast';
      case Ritual.withBreakfast:
        return 'With your breakfast';
      case Ritual.afterBreakfast:
        return 'After your breakfast';
      case Ritual.beforeLunch:
        return 'Before your lunch';
      case Ritual.withLunch:
        return 'With your lunch';
      case Ritual.afterLunch:
        return 'After your lunch';
      case Ritual.beforeDinner:
        return 'Before your dinner';
      case Ritual.withDinner:
        return 'With your dinner';
      case Ritual.afterDinner:
        return 'After your dinner';
      case Ritual.beforeSleep:
        return 'Before you go to sleep';
      default:
        return 'Reminder';
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  static Future<void> scheduleAll(List<Medicine> meds, {String? profileName, bool showMedicationNames = true, required int currentStreak, bool persistent = false}) async {
    for (var med in meds) {
      for (int i = 0; i < med.schedule.length; i++) {
        final sched = med.schedule[i];
        if (!sched.enabled) continue;
        for (var day in sched.days) {
          // Unique ID across profiles: hash the profile name into the ID base
          final profileHash = profileName?.hashCode ?? 0;
          final notifId = (profileHash.abs() % 10000) * 10000 + med.id * 100 + i * 10 + day;

          await scheduleWeeklyReminder(
            med: med,
            sched: sched,
            dayIdx: day,
            notifId: notifId,
            enableSound: true,
            enableVibration: true,
            isTakenToday: false,
            profileName: profileName,
            showMedicationNames: showMedicationNames,
            currentStreak: currentStreak,
            persistent: persistent,
          );
        }
      }
    }
  }

  static Future<void> showRefillAlert({
    required Medicine med,
    String? title,
    String? body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'refill_alerts',
      'Refill Alerts',
      channelDescription: 'Alerts when your medication supply is running low',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      id: (med.id + 100000).remainder(0x7FFFFFFF),
      title: title ?? NotificationCopy.refillTitle,
      body: body ?? NotificationCopy.refillBody.replaceAll('{medName}', med.name).replaceAll('{count}', med.count.toString()),
      notificationDetails: details,
    );
  }

  static Future<void> showFamilyAlert({String? profileName}) async {
    const androidDetails = AndroidNotificationDetails(
      'family_alerts',
      'Family Alerts',
      channelDescription: 'Alerts for family members doses',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    final prefix = profileName != null ? '$profileName: ' : '';
    await _plugin.show(
      id: 999000,
      title: '$prefix${NotificationCopy.familyAlertTitle}',
      body: NotificationCopy.familyAlertBody,
      notificationDetails: details,
    );
  }

  /// Displays an incoming remote (FCM) alert as a local notification. Needed
  /// because Android suppresses notification payloads while the app is in the
  /// foreground — this surfaces caregiver missed-dose alerts and nudges.
  static Future<void> showRemoteAlert({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'family_alerts',
      'Family Alerts',
      channelDescription: 'Alerts for family members doses',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      id: 999001,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> scheduleStreakNudge({required int streak, required int id, required DateTime targetDate}) async {
    final random = Random();
    final copy = NotificationCopy.streakNudges[random.nextInt(NotificationCopy.streakNudges.length)]
        .replaceAll('{streak}', streak.toString());
    
    const androidDetails = AndroidNotificationDetails(
      'streak_nudges',
      'Streak Nudges',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.zonedSchedule(
      id: id,
      title: 'Keep it up! 🏆',
      body: copy,
      scheduledDate: tz.TZDateTime.from(targetDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleReEngagement({required DateTime targetDate}) async {
    const androidDetails = AndroidNotificationDetails(
      're_engagement',
      'Re-engagement',
      importance: Importance.low,
      priority: Priority.low,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentSound: false);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _plugin.zonedSchedule(
      id: 888002,
      title: NotificationCopy.reEngagementTitle,
      body: NotificationCopy.reEngagementBody,
      scheduledDate: tz.TZDateTime.from(targetDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleCaregiverEscalation({
    required Medicine med,
    required ScheduleEntry sched,
    required DateTime doseDate,
    required int baseNotifId,
    String? profileName,
  }) async {
    final escalationDate = doseDate.add(const Duration(hours: 2));
    
    // Only schedule if the escalation time is still in the future
    if (escalationDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'caregiver_escalation',
      'Caregiver Escalations',
      channelDescription: 'High-priority alerts for missed critical doses',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      color: const Color(0xFFFF3B30),
      enableLights: true,
      ledColor: const Color(0xFFFF3B30),
      ledOnMs: 1000,
      ledOffMs: 500,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    final prefix = profileName != null ? '$profileName: ' : '';
    await _plugin.zonedSchedule(
      id: (baseNotifId + 1000000).remainder(0x7FFFFFFF),
      title: '🚨 CAREGIVER ESCALATION 🚨',
      body: '$prefix You missed your critical dose of ${med.name}. An alert has been escalated to your caregiver network.',
      scheduledDate: tz.TZDateTime.from(escalationDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleMorningSummary({
    required int totalDoses,
    required bool enableSound,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summaries',
      'Daily Summaries',
      channelDescription: 'Morning summary of your medications for the day',
      importance: Importance.low,
      priority: Priority.low,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 999999,
      title: 'Good morning! ☀️',
      body:
          'You have $totalDoses dose${totalDoses == 1 ? "" : "s"} scheduled for today.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleOneOffReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool enableSound = true,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'one_off_reminders',
      'One-off Reminders',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('take', 'Take Now', showsUserInterface: true),
        AndroidNotificationAction('snooze_10', 'Snooze 10m', showsUserInterface: true),
        AndroidNotificationAction('skip', 'Skip', showsUserInterface: true, cancelNotification: true),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: enableSound,
        categoryIdentifier: 'med_action');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      id: id.remainder(0x7FFFFFFF),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleMealFollowUp({
    required List<Medicine> meds,
    required Ritual mealRitual,
    required String profileName,
  }) async {
    final now = DateTime.now();
    final dayIdx = now.weekday % 7;
    
    final applicableMeds = meds.where((m) => m.schedule.any((s) => s.enabled && s.days.contains(dayIdx) && s.ritual == mealRitual)).toList();
    
    if (applicableMeds.isEmpty) return;
    
    final androidDetails = AndroidNotificationDetails(
      'dynamic_triggers',
      'Dynamic Triggers',
      channelDescription: 'Personalized triggers based on your logging activity',
      importance: Importance.max,
      priority: Priority.max,
      vibrationPattern: _premiumHeartbeatVibration,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    // Schedule 30 mins after logging the meal
    final scheduledDate = now.add(const Duration(minutes: 30)); 
    
    final prefix = profileName.isNotEmpty ? '$profileName: ' : '';
    await _plugin.zonedSchedule(
      id: 777001,
      title: '🍽️ $prefix${mealRitual.displayName} Follow-up',
      body: 'You recently logged a meal. Time to take your post-meal medications!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> scheduleIntakeCheckIn({
    required Medicine med,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'dynamic_triggers',
      'Dynamic Triggers',
      importance: Importance.max,
      priority: Priority.max,
      vibrationPattern: _premiumHeartbeatVibration,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    // Schedule 2 hours after intake
    final scheduledDate = DateTime.now().add(const Duration(hours: 2)); 
    
    await _plugin.zonedSchedule(
      id: 777002,
      title: 'How are you feeling? ✨',
      body: 'You took ${med.name} a couple hours ago. Log any side effects if needed.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> refreshTimeZone() async {
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback or ignore
    }
  }
}
