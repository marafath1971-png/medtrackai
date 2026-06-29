import 'package:flutter/foundation.dart';

import '../../models/onboarding_prefs.dart';

/// Holds every answer collected through the 38-step viral onboarding funnel.
///
/// Answers are stored in a flexible map keyed by the step `id`, so adding or
/// reordering steps never requires touching this class. The few fields the rest
/// of the app already depends on ([OnboardingPrefs.medCount], `role`,
/// `schedule`) are derived in [toPrefs].
class OnboardingController extends ChangeNotifier {
  /// Single-select answers: stepId -> selected optionId.
  final Map<String, String> _single = {};

  /// Multi-select answers: stepId -> set of selected optionIds.
  final Map<String, Set<String>> _multi = {};

  /// Free numeric answers (age, counts) if ever needed.
  final Map<String, num> _numbers = {};

  // ── Reads ────────────────────────────────────────────────────────────
  String? single(String stepId) => _single[stepId];
  Set<String> multi(String stepId) => _multi[stepId] ?? <String>{};
  num? number(String stepId) => _numbers[stepId];

  bool isSelected(String stepId, String optionId, {required bool multiSelect}) {
    if (multiSelect) return multi(stepId).contains(optionId);
    return _single[stepId] == optionId;
  }

  /// Whether the given step currently has a valid answer (for enabling CTA).
  bool hasAnswer(String stepId, {required bool multiSelect}) {
    if (multiSelect) return (_multi[stepId]?.isNotEmpty ?? false);
    return _single[stepId] != null;
  }

  // ── Writes ───────────────────────────────────────────────────────────
  void selectSingle(String stepId, String optionId) {
    _single[stepId] = optionId;
    notifyListeners();
  }

  void toggleMulti(String stepId, String optionId) {
    final set = _multi.putIfAbsent(stepId, () => <String>{});
    if (!set.add(optionId)) set.remove(optionId);
    notifyListeners();
  }

  void setNumber(String stepId, num value) {
    _numbers[stepId] = value;
    notifyListeners();
  }

  // ── Derivations used elsewhere in the app ────────────────────────────
  OnboardingPrefs toPrefs() {
    final medCount = switch (_single['med_count']) {
      'one_two' => '1-2',
      'three_five' => '3-5',
      'six_nine' => '6+',
      'ten_plus' => '6+',
      _ => '1-2',
    };
    final role = switch (_single['persona'] ?? _single['managing_for']) {
      'caregiver' || 'loved_one' => 'caregiver',
      'family_leader' || 'me_family' => 'caregiver',
      _ => 'self',
    };
    final reminderIntensity = _single['reminder_intensity'] ?? 'normal';
    final schedule = switch (_single['timing']) {
      'afternoon' => 'afternoon',
      'evening' => 'evening',
      'multiple' => 'morning',
      _ => 'morning',
    };
    return OnboardingPrefs(
      medCount: medCount,
      role: role,
      schedule: schedule,
      reminderIntensity: reminderIntensity,
    );
  }

  /// A friendly first name if collected, else null.
  String? get name {
    final n = _single['name_value'];
    if (n == null || n.trim().isEmpty) return null;
    return n.trim();
  }

  /// Estimated current adherence (0..1) inferred from "how often miss" answer.
  double get inferredAdherence => switch (_single['miss_frequency']) {
        'often' => 0.55,
        'sometimes' => 0.72,
        'rarely' => 0.86,
        'never' => 0.93,
        _ => 0.70,
      };

  /// Projected adherence after using Med AI — the optimistic "after" number.
  double get projectedAdherence => 0.97;

  /// Olive-style baseline score (0..100) from onboarding answers.
  int get adherenceScore {
    var score = 72;
    switch (_single['miss_frequency']) {
      case 'often':
        score -= 26;
      case 'sometimes':
        score -= 14;
      case 'rarely':
        score -= 4;
      case 'never':
        score += 6;
    }
    switch (_single['interaction_known']) {
      case 'yes':
        score += 8;
      case 'unsure':
        score -= 6;
      case 'no':
        score -= 14;
    }
    if (_single['challenge'] == 'forgetting') score -= 8;
    if (_single['challenge'] == 'schedule') score -= 6;
    if (_single['supplements'] == 'many') score -= 4;
    if (_single['timing'] == 'multiple') score -= 5;
    return score.clamp(28, 88);
  }

  ({String label, String emoji}) get personaLabel {
    return switch (_single['persona'] ?? _single['managing_for']) {
      'caregiver' || 'loved_one' => (label: 'Dedicated Caregiver', emoji: '🤝'),
      'family_leader' || 'me_family' => (label: 'Family Health Lead', emoji: '👨‍👩‍👧'),
      'senior' => (label: 'Health-Focused Senior', emoji: '👴'),
      _ => (label: 'Self-Manager', emoji: '🙋'),
    };
  }

  String get medCountLabel => switch (_single['med_count']) {
        'one_two' => '1–2 medications',
        'three_five' => '3–5 medications',
        'six_nine' => '6–9 medications',
        'ten_plus' => '10+ medications',
        _ => 'Not set',
      };

  String get challengeLabel => switch (_single['challenge']) {
        'forgetting' => 'Forgetting doses',
        'schedule' => 'Complex schedule',
        'side_effects' => 'Side effects',
        'refills' => 'Refills & stock',
        _ => 'Not set',
      };

  List<({String label, bool positive})> get adherenceChecklist {
    final miss = _single['miss_frequency'];
    final interaction = _single['interaction_known'];
    final challenge = _single['challenge'];
    return [
      (
        label: miss == 'never' || miss == 'rarely'
            ? 'Stays on schedule most days'
            : 'Often misses doses',
        positive: miss == 'never' || miss == 'rarely',
      ),
      (
        label: interaction == 'yes'
            ? 'Knows about drug interactions'
            : 'Unsure about interactions',
        positive: interaction == 'yes',
      ),
      (
        label: _single['med_count'] != null
            ? 'Tracks medication count'
            : 'Medication count unknown',
        positive: _single['med_count'] != null,
      ),
      (
        label: challenge != 'refills'
            ? 'Refill tracking needs help'
            : 'Needs refill reminders',
        positive: challenge != 'refills',
      ),
      (
        label: 'Smart reminders not set up yet',
        positive: false,
      ),
    ];
  }
}
