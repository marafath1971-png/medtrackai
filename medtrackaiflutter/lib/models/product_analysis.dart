class ProductAnalysis {
  final String id;
  final String name;
  final String category; // Medicine, Supplement, Vitamin, etc.
  final String description; // What is this?
  final String whyTakeIt;
  final String howItWorks;
  final List<String> benefits;
  final List<SideEffect> sideEffects;
  final List<String> foodInteractions;
  final List<String> medicineInteractions;
  final String timing; // e.g. "Take with food, morning"
  final String halalStatus; // Halal, Haram, Doubtful
  final String scientificEvidence; // e.g. "Strong evidence for sleep"
  final String? childSafetyAlert;
  final String? pregnancyAlert;
  final String? skincareNotes;
  final List<String> allergyAlerts;
  final String allergyRiskLevel; // "None", "Low", "Medium", "High"
  final List<ExpertPerspective> expertPerspectives;

  /// Whether the AI could confidently identify the product. When false, the UI
  /// presents a "not identified — retake / search" state instead of a
  /// confident result.
  final bool identified;

  /// AI self-reported confidence: 'high' | 'medium' | 'low'. Drives the honest
  /// badge and the low-confidence warning. Defaults to 'low' when absent so an
  /// old or partial response can never masquerade as high-confidence.
  final String confidence;

  ProductAnalysis({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.whyTakeIt,
    required this.howItWorks,
    required this.benefits,
    required this.sideEffects,
    required this.foodInteractions,
    required this.medicineInteractions,
    required this.timing,
    required this.halalStatus,
    required this.scientificEvidence,
    this.childSafetyAlert,
    this.pregnancyAlert,
    this.skincareNotes,
    required this.allergyAlerts,
    required this.allergyRiskLevel,
    required this.expertPerspectives,
    this.identified = true,
    this.confidence = 'low',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'whyTakeIt': whyTakeIt,
        'howItWorks': howItWorks,
        'benefits': benefits,
        'sideEffects': sideEffects.map((e) => e.toJson()).toList(),
        'foodInteractions': foodInteractions,
        'medicineInteractions': medicineInteractions,
        'timing': timing,
        'halalStatus': halalStatus,
        'scientificEvidence': scientificEvidence,
        'childSafetyAlert': childSafetyAlert,
        'pregnancyAlert': pregnancyAlert,
        'skincareNotes': skincareNotes,
        'allergyAlerts': allergyAlerts,
        'allergyRiskLevel': allergyRiskLevel,
        'expertPerspectives': expertPerspectives.map((e) => e.toJson()).toList(),
        'identified': identified,
        'confidence': confidence,
      };

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    return ProductAnalysis(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown',
      category: json['category'] ?? 'Supplement',
      description: json['description'] ?? '',
      whyTakeIt: json['whyTakeIt'] ?? '',
      howItWorks: json['howItWorks'] ?? '',
      benefits: List<String>.from(json['benefits'] ?? []),
      sideEffects: (json['sideEffects'] as List<dynamic>?)
              ?.map((e) => SideEffect.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      foodInteractions: List<String>.from(json['foodInteractions'] ?? []),
      medicineInteractions: List<String>.from(json['medicineInteractions'] ?? []),
      timing: json['timing'] ?? '',
      halalStatus: json['halalStatus'] ?? 'Unknown',
      scientificEvidence: json['scientificEvidence'] ?? '',
      childSafetyAlert: json['childSafetyAlert'],
      pregnancyAlert: json['pregnancyAlert'],
      skincareNotes: json['skincareNotes'],
      allergyAlerts: List<String>.from(json['allergyAlerts'] ?? []),
      allergyRiskLevel: json['allergyRiskLevel'] ?? 'None',
      expertPerspectives: (json['expertPerspectives'] as List<dynamic>?)
              ?.map((e) => ExpertPerspective.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      // Default to identified=true for backward compat with stored history that
      // predates this field; confidence defaults to 'low' so a missing value is
      // never treated as a confident result.
      identified: json['identified'] as bool? ?? true,
      confidence: (json['confidence'] as String?) ?? 'low',
    );
  }

  // Mock Data
  static ProductAnalysis get mockMagnesium => ProductAnalysis(
        id: '1',
        name: 'Magnesium Glycinate',
        category: 'Supplement',
        description: 'A highly bioavailable form of magnesium bound to the amino acid glycine.',
        whyTakeIt: 'People take it to improve sleep quality, reduce anxiety, and support muscle recovery.',
        howItWorks: 'Glycine acts as a calming neurotransmitter in the brain, while magnesium relaxes muscles and regulates the nervous system.',
        benefits: ['Better Sleep', 'Muscle Relaxation', 'Anxiety Relief', 'Bone Health'],
        sideEffects: [
          SideEffect(effect: 'Mild stomach upset (rare)', severity: 'Low'),
          SideEffect(effect: 'Drowsiness if taken during the day', severity: 'Low'),
        ],
        foodInteractions: ['Avoid taking with high-calcium meals (reduces absorption).'],
        medicineInteractions: ['Antibiotics (take 2 hours apart)', 'Bisphosphonates'],
        timing: 'Best taken 30-60 minutes before bed.',
        halalStatus: 'Halal Certified',
        scientificEvidence: 'Strong clinical backing for sleep improvement and anxiety reduction.',
        allergyAlerts: [],
        allergyRiskLevel: 'None',
        expertPerspectives: [
          ExpertPerspective(
            role: 'Doctor',
            explanation: "Clinically, we recommend Magnesium Glycinate over Oxide because it doesn't cause laxative effects and crosses the blood-brain barrier effectively for neurological benefits.",
            icon: '👩‍⚕️',
          ),
          ExpertPerspective(
            role: 'Pharmacist',
            explanation: 'Make sure to separate this from your morning multivitamins containing calcium or iron, as they compete for absorption in your gut.',
            icon: '💊',
          ),
          ExpertPerspective(
            role: 'Scientist',
            explanation: 'The chelation to glycine ensures transport through dipeptide channels rather than standard mineral channels, drastically improving bioavailability.',
            icon: '🔬',
          ),
          ExpertPerspective(
            role: 'Fitness Coach',
            explanation: 'I tell my athletes to take this post-workout or before bed. It dramatically lowers cortisol and prevents muscle cramps after heavy lifts.',
            icon: '🏋️‍♂️',
          ),
        ],
        identified: true,
        confidence: 'high',
      );
}

class SideEffect {
  final String effect;
  final String severity; // "Low", "Medium", "High"

  SideEffect({
    required this.effect,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'effect': effect,
        'severity': severity,
      };

  factory SideEffect.fromJson(Map<String, dynamic> json) {
    return SideEffect(
      effect: json['effect'] ?? '',
      severity: json['severity'] ?? 'Low',
    );
  }
}

class ExpertPerspective {
  final String role;
  final String explanation;
  final String icon;

  ExpertPerspective({
    required this.role,
    required this.explanation,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'explanation': explanation,
        'icon': icon,
      };

  factory ExpertPerspective.fromJson(Map<String, dynamic> json) {
    return ExpertPerspective(
      role: json['role'] ?? '',
      explanation: json['explanation'] ?? '',
      icon: json['icon'] ?? '👤',
    );
  }
}
