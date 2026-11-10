/// One calendar day of step data for one person.
///
/// The same shape is cached on the device, written to
/// `users/{uid}/stepDays/{dateKey}` and read back for a walking partner, so
/// it carries the owner's display name: a partner can only read these
/// documents, not the owner's profile.
class StepDay {
  /// `yyyy-MM-dd` in the owner's local time zone.
  final String dateKey;
  final int steps;

  /// The goal that applied on this day. Stored per day so changing today's
  /// goal does not rewrite whether last week's days were hits or misses.
  final int goal;

  /// Steps per hour of the day, index 0 = midnight. Empty when unknown, which
  /// is the case for every past day (only today is read hour by hour).
  final List<int> hourly;

  final String name;
  final String avatar;

  const StepDay({
    required this.dateKey,
    required this.steps,
    required this.goal,
    this.hourly = const [],
    this.name = '',
    this.avatar = '',
  });

  bool get goalMet => goal > 0 && steps >= goal;

  /// Uncapped: 1.4 means 140% of goal. Callers clamp for drawing.
  double get progress => goal <= 0 ? 0 : steps / goal;

  int get remaining => steps >= goal ? 0 : goal - steps;

  StepDay copyWith({int? steps, int? goal, List<int>? hourly}) => StepDay(
        dateKey: dateKey,
        steps: steps ?? this.steps,
        goal: goal ?? this.goal,
        hourly: hourly ?? this.hourly,
        name: name,
        avatar: avatar,
      );

  Map<String, dynamic> toJson() => {
        'steps': steps,
        'goal': goal,
        if (hourly.isNotEmpty) 'hourly': hourly,
        if (name.isNotEmpty) 'name': name,
        if (avatar.isNotEmpty) 'avatar': avatar,
      };

  factory StepDay.fromJson(String dateKey, Map<String, dynamic> j) => StepDay(
        dateKey: dateKey,
        steps: _int(j['steps']),
        goal: _int(j['goal']),
        hourly: (j['hourly'] as List? ?? const []).map(_int).toList(),
        name: j['name'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
      );

  // Firestore hands numbers back as int or double depending on how they were
  // written, and a partner's document is not ours to trust.
  static int _int(Object? v) {
    if (v is num && v.isFinite && v > 0) return v.round();
    return 0;
  }
}

/// The person you walk with.
class StepPartner {
  final String uid;
  final String name;
  final String avatar;

  const StepPartner({required this.uid, this.name = '', this.avatar = ''});

  StepPartner withFallback({String name = '', String avatar = ''}) =>
      StepPartner(
        uid: uid,
        name: this.name.isNotEmpty ? this.name : name,
        avatar: this.avatar.isNotEmpty ? this.avatar : avatar,
      );
}

enum StepCheerKind { cheer, nudge }

/// A tap of encouragement from a partner. Consumed once shown.
class StepCheer {
  final String id;
  final String fromUid;
  final StepCheerKind kind;

  const StepCheer(
      {required this.id, required this.fromUid, required this.kind});
}
