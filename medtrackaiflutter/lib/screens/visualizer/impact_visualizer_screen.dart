import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/med_ai_ui.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/premium_page_header.dart';
import '../../core/utils/haptic_engine.dart';

/// Which pharmacokinetic phase an organ's activity tracks.
///
/// The plasma concentration curve is the same for every drug, but different
/// organs "light up" at different times: the gut leads (absorption), systemic
/// targets track the plasma level, and the liver/kidneys trail (clearance).
enum _Phase { absorption, systemic, clearance }

/// A single anatomical organ we can draw and activate.
class _Organ {
  final String id;
  final String name;
  final String role;
  final Color color;
  final _Phase phase;

  /// Normalised position inside the body box (0..1, y grows downward).
  final Offset pos;

  /// Keywords (lowercase) that map an AI `bodySystems` label to this organ.
  final List<String> systems;

  const _Organ({
    required this.id,
    required this.name,
    required this.role,
    required this.color,
    required this.phase,
    required this.pos,
    required this.systems,
  });
}

/// The catalogue of organs the map can render, laid out head-to-pelvis.
const List<_Organ> _kOrgans = [
  _Organ(
    id: 'brain',
    name: 'Brain',
    role: 'Central nervous system — where mood, focus and pain signals are felt.',
    color: Color(0xFF00E5FF),
    phase: _Phase.systemic,
    pos: Offset(0.5, 0.085),
    systems: ['brain', 'nervous', 'cns', 'cognitive', 'neuro', 'mental', 'mood', 'psych'],
  ),
  _Organ(
    id: 'lungs',
    name: 'Lungs',
    role: 'Respiratory exchange — airways and breathing.',
    color: Color(0xFF64D2FF),
    phase: _Phase.systemic,
    pos: Offset(0.5, 0.34),
    systems: ['lung', 'respiratory', 'airway', 'bronch', 'pulmonary'],
  ),
  _Organ(
    id: 'heart',
    name: 'Heart',
    role: 'Cardiovascular engine — carries the drug to every tissue.',
    color: Color(0xFFFF375F),
    phase: _Phase.systemic,
    pos: Offset(0.435, 0.37),
    systems: ['heart', 'cardio', 'vascular', 'blood pressure', 'circulat', 'systemic'],
  ),
  _Organ(
    id: 'liver',
    name: 'Liver',
    role: 'Metabolic refinery — breaks the drug down (first-pass & clearance).',
    color: Color(0xFFFFB340),
    phase: _Phase.clearance,
    pos: Offset(0.40, 0.50),
    systems: ['liver', 'hepatic', 'metabol', 'detox', 'enzyme'],
  ),
  _Organ(
    id: 'stomach',
    name: 'Stomach',
    role: 'Absorption gateway — where an oral dose first dissolves.',
    color: Color(0xFFFF9F0A),
    phase: _Phase.absorption,
    pos: Offset(0.58, 0.49),
    systems: ['stomach', 'gastric', 'digest', 'gastro', 'gi ', 'gut', 'oral'],
  ),
  _Organ(
    id: 'kidneys',
    name: 'Kidneys',
    role: 'Renal filtration — excretes what the liver has processed.',
    color: Color(0xFFBF5AF2),
    phase: _Phase.clearance,
    pos: Offset(0.5, 0.60),
    systems: ['kidney', 'renal', 'urinary', 'bladder', 'excret'],
  ),
  _Organ(
    id: 'intestines',
    name: 'Intestines',
    role: 'Nutrient & drug uptake into the bloodstream.',
    color: Color(0xFF30D158),
    phase: _Phase.absorption,
    pos: Offset(0.5, 0.68),
    systems: ['intestin', 'bowel', 'colon', 'absorption', 'immune', 'inflamm'],
  ),
];

/// A resolved, drawable profile for one medication (or the demo).
class _ImpactProfile {
  final String title;
  final String subtitle;
  final String mechanism;
  final double onsetHours;
  final double peakHours;
  final double durationHours;
  final Set<String> activeOrganIds;
  final bool isDemo;

  const _ImpactProfile({
    required this.title,
    required this.subtitle,
    required this.mechanism,
    required this.onsetHours,
    required this.peakHours,
    required this.durationHours,
    required this.activeOrganIds,
    required this.isDemo,
  });

  /// Plasma concentration (0..1) at [t] hours after the dose, using a simple
  /// absorption-to-peak ramp, a linear-ish decay to the end of action, then an
  /// exponential residual tail. Mirrors the app's PharmaTimeline model so the
  /// two visualisations agree.
  double concentration(double t) {
    if (durationHours <= 0) return 0;
    final onset = onsetHours.clamp(0.0, peakHours <= 0 ? 0.5 : peakHours);
    final peak = peakHours <= onset ? onset + 0.25 : peakHours;
    final duration = durationHours <= peak ? peak + 1 : durationHours;

    if (t < onset) {
      // Gentle uptake even before "onset" so the wave reads as continuous.
      return (t / onset).clamp(0.0, 1.0) * 0.12;
    }
    if (t < peak) {
      final r = (t - onset) / (peak - onset);
      return 0.12 + 0.88 * Curves.easeOut.transform(r.clamp(0.0, 1.0));
    }
    if (t < duration) {
      final r = (t - peak) / (duration - peak);
      return (1.0 - 0.9 * r).clamp(0.1, 1.0);
    }
    final tail = t - duration;
    return 0.1 * math.exp(-tail / 4.0);
  }

  /// Per-organ activation (0..1) at time [t]. Absorption organs lead the
  /// plasma curve, clearance organs trail it, systemic organs track it.
  double organActivation(_Organ organ, double t) {
    if (!activeOrganIds.contains(organ.id)) return 0;
    final c = concentration(t);
    switch (organ.phase) {
      case _Phase.systemic:
        return c;
      case _Phase.absorption:
        // Front-loaded: strongest between onset and peak, fades after.
        final lead = concentration(t + peakHours * 0.5);
        return (0.35 * c + 0.65 * lead).clamp(0.0, 1.0);
      case _Phase.clearance:
        // Back-loaded: ramps as the drug is metabolised/excreted.
        final past =
            (t / (durationHours <= 0 ? 1 : durationHours)).clamp(0.0, 1.0);
        final trail = concentration(t - peakHours * 0.4).clamp(0.0, 1.0);
        return (0.45 * c + 0.55 * (0.3 + 0.7 * past) * math.max(c, trail))
            .clamp(0.0, 1.0);
    }
  }
}

class ImpactVisualizerScreen extends StatefulWidget {
  /// Optionally focus a specific medication (by id) on open.
  final int? initialMedId;

  const ImpactVisualizerScreen({super.key, this.initialMedId});

  @override
  State<ImpactVisualizerScreen> createState() => _ImpactVisualizerScreenState();
}

class _ImpactVisualizerScreenState extends State<ImpactVisualizerScreen>
    with SingleTickerProviderStateMixin {
  double _currentHour = 0.0;
  int _selectedMedIndex = 0;
  bool _isPlaying = false;
  String? _tappedOrganId;
  Timer? _playTimer;

  late final AnimationController _pulse;
  List<Medicine> _profileMeds = const [];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppDurations.breathe,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _profileMeds = _collectMeds();
      if (widget.initialMedId != null) {
        final i = _profileMeds.indexWhere((m) => m.id == widget.initialMedId);
        if (i >= 0) _selectedMedIndex = i;
      }
      // Only breathe when motion is allowed; otherwise hold a steady glow.
      if (MedAiA11y.reducedMotion(context)) {
        _pulse.value = 0.6;
      } else {
        _pulse.repeat(reverse: true);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  /// Meds that carry usable pharmacokinetic data.
  List<Medicine> _collectMeds() {
    final state = context.read<AppState>();
    return state.meds.where((m) {
      final p = m.aiSafetyProfile;
      return p != null && p.durationHours > 0 && p.bodySystems.isNotEmpty;
    }).toList();
  }

  Set<String> _organIdsFor(List<String> bodySystems) {
    final ids = <String>{};
    for (final raw in bodySystems) {
      final s = raw.toLowerCase();
      for (final organ in _kOrgans) {
        if (organ.systems.any(s.contains)) ids.add(organ.id);
      }
    }
    // Almost every oral drug is cleared through the liver + kidneys, so surface
    // them as secondary actors whenever the user has a real profile.
    if (ids.isNotEmpty) {
      ids.add('liver');
      ids.add('kidneys');
    }
    return ids;
  }

  _ImpactProfile get _profile {
    if (_profileMeds.isEmpty) {
      // Illustrative fallback so the screen is never empty.
      return const _ImpactProfile(
        title: 'Sample: Ibuprofen 400mg',
        subtitle: 'Demo — scan a medicine for your own map',
        mechanism:
            'Blocks COX enzymes to reduce inflammation and pain signalling.',
        onsetHours: 0.5,
        peakHours: 1.5,
        durationHours: 6.0,
        activeOrganIds: {
          'brain',
          'heart',
          'stomach',
          'liver',
          'kidneys',
          'intestines',
        },
        isDemo: true,
      );
    }
    final med = _profileMeds[_selectedMedIndex.clamp(0, _profileMeds.length - 1)];
    final p = med.aiSafetyProfile!;
    return _ImpactProfile(
      title: med.name,
      subtitle: med.dose.isNotEmpty ? med.dose : (med.brand),
      mechanism: p.mechanismOfAction,
      onsetHours: p.onsetMinutes / 60.0,
      peakHours: p.peakHours,
      durationHours: p.durationHours,
      activeOrganIds: _organIdsFor(p.bodySystems),
      isDemo: false,
    );
  }

  void _selectMed(int i) {
    HapticEngine.selection();
    setState(() {
      _selectedMedIndex = i;
      _tappedOrganId = null;
    });
  }

  void _onScrub(double v) => setState(() => _currentHour = v);

  void _togglePlay() {
    HapticEngine.selection();
    if (_isPlaying) {
      _playTimer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }
    if (_currentHour >= 24) _currentHour = 0;
    setState(() => _isPlaying = true);
    _playTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      setState(() {
        _currentHour += 0.35;
        if (_currentHour >= 24) {
          _currentHour = 24;
          _isPlaying = false;
          _playTimer?.cancel();
          HapticEngine.selection();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final reduceMotion = MedAiA11y.reducedMotion(context);

    // Precompute activations once per frame; shared by canvas, labels, legend.
    final activations = <String, double>{
      for (final o in _kOrgans) o.id: profile.organActivation(o, _currentHour),
    };

    return AppScaffold(
      showAurora: true,
      body: SafeArea(
        child: Column(
          children: [
            PremiumPageHeader(
              title: 'Organ impact map',
              subtitle: 'How your medicine moves through the body',
              onBack: () => Navigator.pop(context),
            ),
            _MedSelector(
              meds: _profileMeds,
              selectedIndex: _selectedMedIndex,
              onSelect: _selectMed,
              isDemo: profile.isDemo,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return _BodyStage(
                        profile: profile,
                        activations: activations,
                        pulse: _pulse.value,
                        tappedOrganId: _tappedOrganId,
                        onTapOrgan: (id) {
                          HapticEngine.selection();
                          setState(() =>
                              _tappedOrganId = _tappedOrganId == id ? null : id);
                        },
                        constraints: constraints,
                        reduceMotion: reduceMotion,
                      );
                    },
                  );
                },
              ),
            ),
            _ScrubberPanel(
              profile: profile,
              currentHour: _currentHour,
              isPlaying: _isPlaying,
              onScrub: _onScrub,
              onTogglePlay: _togglePlay,
              concentration: profile.concentration(_currentHour),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Medication selector
// ─────────────────────────────────────────────────────────────────────────

class _MedSelector extends StatelessWidget {
  final List<Medicine> meds;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isDemo;

  const _MedSelector({
    required this.meds,
    required this.selectedIndex,
    required this.onSelect,
    required this.isDemo,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    if (isDemo || meds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Row(
          children: [
            Icon(Icons.science_outlined, size: 15, color: L.sub),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing a sample medicine. Scan or analyse a medicine to see your own organ map.',
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: meds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          final med = meds[i];
          return Semantics(
            button: true,
            selected: selected,
            label: 'Show organ map for ${med.name}',
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? L.accent.withValues(alpha: 0.16)
                      : L.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.max),
                  border: Border.all(
                    color: selected
                        ? L.accent.withValues(alpha: 0.55)
                        : L.border.withValues(alpha: 0.14),
                    width: selected ? 1.2 : 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  med.name,
                  style: AppTypography.labelSmall.copyWith(
                    color: selected ? L.text : L.sub,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Body + organs stage
// ─────────────────────────────────────────────────────────────────────────

/// Geometry helper shared by the painter and the tappable label layer so an
/// organ's dot and its label always agree on where the organ is.
class _BodyGeometry {
  final Rect box; // the body's bounding box within the stage

  _BodyGeometry(Size size)
      : box = _fit(size);

  static Rect _fit(Size size) {
    const aspect = 0.62; // width : height of the body box
    var h = size.height * 0.96;
    var w = h * aspect;
    if (w > size.width * 0.92) {
      w = size.width * 0.92;
      h = w / aspect;
    }
    final left = (size.width - w) / 2;
    final top = (size.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  Offset project(Offset norm) =>
      Offset(box.left + norm.dx * box.width, box.top + norm.dy * box.height);

  double get unit => box.width; // scale reference for organ sizing
}

class _BodyStage extends StatelessWidget {
  final _ImpactProfile profile;
  final Map<String, double> activations;
  final double pulse;
  final String? tappedOrganId;
  final ValueChanged<String> onTapOrgan;
  final BoxConstraints constraints;
  final bool reduceMotion;

  const _BodyStage({
    required this.profile,
    required this.activations,
    required this.pulse,
    required this.tappedOrganId,
    required this.onTapOrgan,
    required this.constraints,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final geo = _BodyGeometry(size);

    final visibleOrgans =
        _kOrgans.where((o) => profile.activeOrganIds.contains(o.id)).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OrganMapPainter(
              geo: geo,
              organs: _kOrgans,
              activeIds: profile.activeOrganIds,
              activations: activations,
              pulse: pulse,
              currentHour:
                  profile.durationHours <= 0 ? 0.0 : _scanFraction(context),
              bodyColor: L.text,
              fillColor: L.fill,
              reduceMotion: reduceMotion,
            ),
          ),
        ),
        // Tap targets + labels, positioned to match the painter geometry.
        ...visibleOrgans.map((organ) {
          final center = geo.project(organ.pos);
          final act = activations[organ.id] ?? 0;
          final isLeft = organ.pos.dx < 0.5;
          final selected = tappedOrganId == organ.id;
          const labelW = 96.0;
          final labelLeft = isLeft
              ? center.dx - labelW - geo.unit * 0.10
              : center.dx + geo.unit * 0.10;

          return Positioned(
            left: labelLeft.clamp(4.0, size.width - labelW - 4),
            top: (center.dy - 16).clamp(4.0, size.height - 40),
            width: labelW,
            child: _OrganLabel(
              organ: organ,
              activation: act,
              alignEnd: isLeft,
              selected: selected,
              onTap: () => onTapOrgan(organ.id),
            ),
          );
        }),
        // Detail sheet for a tapped organ.
        if (tappedOrganId != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 8,
            child: _OrganDetail(
              organ: _kOrgans.firstWhere((o) => o.id == tappedOrganId),
              activation: activations[tappedOrganId] ?? 0,
            ),
          ),
      ],
    );
  }

  // A slow vertical scan position (0..1) used for the sweep line.
  double _scanFraction(BuildContext context) =>
      reduceMotion ? 0.5 : pulse;
}

class _OrganLabel extends StatelessWidget {
  final _Organ organ;
  final double activation;
  final bool alignEnd;
  final bool selected;
  final VoidCallback onTap;

  const _OrganLabel({
    required this.organ,
    required this.activation,
    required this.alignEnd,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final active = activation > 0.08;
    final pct = (activation * 100).round();

    return Semantics(
      button: true,
      label: '${organ.name}, $pct percent active. Tap for detail.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              organ.name,
              textAlign: alignEnd ? TextAlign.right : TextAlign.left,
              style: AppTypography.labelSmall.copyWith(
                color: active ? organ.color : L.sub.withValues(alpha: 0.8),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.1,
                shadows: active
                    ? [Shadow(color: organ.color.withValues(alpha: 0.5), blurRadius: 12)]
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: AppTypography.bodyMedium.copyWith(
                color: active ? L.text : L.text.withValues(alpha: 0.45),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              child: Text('$pct%'),
            ),
            const SizedBox(height: 3),
            _MiniBar(value: activation, color: organ.color, alignEnd: alignEnd),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double value;
  final Color color;
  final bool alignEnd;

  const _MiniBar({
    required this.value,
    required this.color,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Align(
      alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        width: 54,
        height: 4,
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3),
        ),
        child: FractionallySizedBox(
          alignment: alignEnd ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          widthFactor: value.clamp(0.0, 1.0),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.7), color],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganDetail extends StatelessWidget {
  final _Organ organ;
  final double activation;

  const _OrganDetail({required this.organ, required this.activation});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final pct = (activation * 100).round();
    return MedAiGlass(
      radius: AppRadius.l,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: organ.color,
              boxShadow: [
                BoxShadow(color: organ.color.withValues(alpha: 0.6), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      organ.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct% active',
                      style: AppTypography.labelSmall.copyWith(
                        color: organ.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  organ.role,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Scrubber panel
// ─────────────────────────────────────────────────────────────────────────

class _ScrubberPanel extends StatelessWidget {
  final _ImpactProfile profile;
  final double currentHour;
  final bool isPlaying;
  final ValueChanged<double> onScrub;
  final VoidCallback onTogglePlay;
  final double concentration;

  const _ScrubberPanel({
    required this.profile,
    required this.currentHour,
    required this.isPlaying,
    required this.onScrub,
    required this.onTogglePlay,
    required this.concentration,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: MedAiGlass(
        radius: AppRadius.squircle,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _stat(L, 'Onset', _fmtOnset(profile.onsetHours)),
                _divider(L),
                _stat(L, 'Peak', '${_trim(profile.peakHours)}h'),
                _divider(L),
                _stat(L, 'Duration', '${_trim(profile.durationHours)}h'),
                _divider(L),
                _stat(L, 'In blood', '${(concentration * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: isPlaying ? 'Pause timeline' : 'Play timeline',
                  child: GestureDetector(
                    onTap: onTogglePlay,
                    child: Container(
                      width: MedAiA11y.minTapTarget,
                      height: MedAiA11y.minTapTarget,
                      decoration: BoxDecoration(
                        color: L.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: L.accent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: L.accent,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label:
                        'Time since dose ${currentHour.toStringAsFixed(1)} hours',
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6,
                        activeTrackColor: L.accent,
                        inactiveTrackColor: L.text.withValues(alpha: 0.08),
                        thumbColor: Colors.white,
                        overlayColor: L.accent.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 11,
                          elevation: 4,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: MedAiA11y.minTapTarget / 2,
                        ),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: currentHour,
                        min: 0,
                        max: 24,
                        onChanged: onScrub,
                        onChangeEnd: (_) => HapticEngine.selection(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0h · dose',
                    style: _cap(L)),
                Text('${currentHour.toStringAsFixed(1)}h',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
                Text('24h · cleared', style: _cap(L)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Illustrative model based on typical pharmacokinetics — not medical advice.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: L.sub.withValues(alpha: 0.55),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _cap(AppThemeColors L) => AppTypography.labelSmall.copyWith(
        color: L.sub,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      );

  Widget _divider(AppThemeColors L) => Container(
        width: 1,
        height: 26,
        color: L.border.withValues(alpha: 0.12),
      );

  Widget _stat(AppThemeColors L, String label, String value) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );

  String _fmtOnset(double h) {
    if (h <= 0) return '—';
    if (h < 1) return '${(h * 60).round()}m';
    return '${_trim(h)}h';
  }

  String _trim(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Painter: body silhouette + anatomical organs
// ─────────────────────────────────────────────────────────────────────────

class _OrganMapPainter extends CustomPainter {
  final _BodyGeometry geo;
  final List<_Organ> organs;
  final Set<String> activeIds;
  final Map<String, double> activations;
  final double pulse;
  final double currentHour; // scan fraction 0..1
  final Color bodyColor;
  final Color fillColor;
  final bool reduceMotion;

  _OrganMapPainter({
    required this.geo,
    required this.organs,
    required this.activeIds,
    required this.activations,
    required this.pulse,
    required this.currentHour,
    required this.bodyColor,
    required this.fillColor,
    required this.reduceMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final body = _buildBodyPath();

    // 1. Body fill + outline.
    canvas.drawPath(
      body,
      Paint()..color = fillColor.withValues(alpha: 0.035),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = bodyColor.withValues(alpha: 0.11),
    );

    // 2. Subtle anatomical grid, clipped to the body.
    canvas.save();
    canvas.clipPath(body);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = bodyColor.withValues(alpha: 0.03);
    const n = 14;
    for (var i = 0; i <= n; i++) {
      final y = geo.box.top + geo.box.height * i / n;
      canvas.drawLine(
          Offset(geo.box.left, y), Offset(geo.box.right, y), grid);
    }
    // 3. Scan sweep line.
    final scanY = geo.box.top + geo.box.height * currentHour;
    final scanRect = Rect.fromLTWH(
        geo.box.left, scanY - 2, geo.box.width, 4);
    canvas.drawRect(
      Rect.fromLTWH(geo.box.left, scanY, geo.box.width, 1.5),
      Paint()
        ..shader = LinearGradient(colors: [
          bodyColor.withValues(alpha: 0),
          bodyColor.withValues(alpha: 0.35),
          bodyColor.withValues(alpha: 0),
        ]).createShader(scanRect),
    );
    canvas.restore();

    // 4. Vascular links between active organs (drug travelling via blood).
    _drawVascular(canvas);

    // 5. Organs, drawn back-to-front (largest/deepest first is fine here).
    for (final organ in organs) {
      if (!activeIds.contains(organ.id)) {
        _drawOrgan(canvas, organ, 0, dim: true);
      }
    }
    for (final organ in organs) {
      if (activeIds.contains(organ.id)) {
        _drawOrgan(canvas, organ, activations[organ.id] ?? 0);
      }
    }
  }

  void _drawVascular(Canvas canvas) {
    final heart = organs.firstWhere((o) => o.id == 'heart');
    final hp = geo.project(heart.pos);
    for (final organ in organs) {
      if (organ.id == 'heart' || !activeIds.contains(organ.id)) continue;
      final act = activations[organ.id] ?? 0;
      if (act <= 0.04) continue;
      final p = geo.project(organ.pos);
      final mid = Offset((hp.dx + p.dx) / 2 + geo.unit * 0.04,
          (hp.dy + p.dy) / 2);
      final path = Path()
        ..moveTo(hp.dx, hp.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p.dx, p.dy);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8 + 1.4 * act
          ..color = organ.color
              .withValues(alpha: (0.12 + 0.28 * act) * (0.8 + 0.2 * pulse)),
      );
    }
  }

  void _drawOrgan(Canvas canvas, _Organ organ, double act, {bool dim = false}) {
    final c = geo.project(organ.pos);
    final u = geo.unit;
    final path = _organPath(organ.id, c, u);

    if (dim) {
      canvas.drawPath(
        path,
        Paint()..color = bodyColor.withValues(alpha: 0.05),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = bodyColor.withValues(alpha: 0.08),
      );
      return;
    }

    final glow = (0.8 + 0.2 * pulse);
    // Outer bloom.
    if (act > 0.05) {
      canvas.drawPath(
        path,
        Paint()
          ..color = organ.color.withValues(alpha: 0.35 * act * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 10 * act),
      );
    }
    // Gradient fill scaled by activation.
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            organ.color.withValues(alpha: 0.25 + 0.6 * act),
            organ.color.withValues(alpha: 0.08 + 0.25 * act),
          ],
        ).createShader(bounds),
    );
    // Crisp rim.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.8 * act
        ..color = organ.color.withValues(alpha: 0.5 + 0.5 * act),
    );
    // Hot core dot for strongly active organs.
    if (act > 0.15) {
      canvas.drawCircle(
        c,
        u * 0.012 + u * 0.02 * act * glow,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * act),
      );
    }
  }

  // Body silhouette (head + torso + shoulders + hips), normalised.
  Path _buildBodyPath() {
    final p = Path();
    Offset n(double x, double y) => geo.project(Offset(x, y));

    // Head.
    final head = n(0.5, 0.085);
    p.addOval(Rect.fromCircle(center: head, radius: geo.unit * 0.13));

    // Torso outline.
    p.moveTo(n(0.44, 0.17).dx, n(0.44, 0.17).dy); // neck L
    p.quadraticBezierTo(
        n(0.36, 0.20).dx, n(0.36, 0.20).dy, n(0.20, 0.235).dx, n(0.20, 0.235).dy); // shoulder L
    p.quadraticBezierTo(
        n(0.30, 0.36).dx, n(0.30, 0.36).dy, n(0.30, 0.50).dx, n(0.30, 0.50).dy); // ribs L
    p.quadraticBezierTo(
        n(0.28, 0.62).dx, n(0.28, 0.62).dy, n(0.33, 0.72).dx, n(0.33, 0.72).dy); // waist->hip L
    p.lineTo(n(0.40, 0.80).dx, n(0.40, 0.80).dy); // hip L
    p.quadraticBezierTo(
        n(0.50, 0.83).dx, n(0.50, 0.83).dy, n(0.60, 0.80).dx, n(0.60, 0.80).dy); // pelvis base
    p.lineTo(n(0.67, 0.72).dx, n(0.67, 0.72).dy); // hip R
    p.quadraticBezierTo(
        n(0.72, 0.62).dx, n(0.72, 0.62).dy, n(0.70, 0.50).dx, n(0.70, 0.50).dy); // waist R
    p.quadraticBezierTo(
        n(0.70, 0.36).dx, n(0.70, 0.36).dy, n(0.80, 0.235).dx, n(0.80, 0.235).dy); // ribs->shoulder R
    p.quadraticBezierTo(
        n(0.64, 0.20).dx, n(0.64, 0.20).dy, n(0.56, 0.17).dx, n(0.56, 0.17).dy); // shoulder->neck R
    p.close();
    return p;
  }

  // Recognisable, stylised organ outlines centred on [c], scaled by [u].
  Path _organPath(String id, Offset c, double u) {
    switch (id) {
      case 'brain':
        return _brainPath(c, u * 0.115);
      case 'lungs':
        return _lungsPath(c, u);
      case 'heart':
        return _heartPath(c, u * 0.085);
      case 'liver':
        return _liverPath(c, u * 0.16);
      case 'stomach':
        return _stomachPath(c, u * 0.12);
      case 'kidneys':
        return _kidneysPath(c, u);
      case 'intestines':
        return _intestinesPath(c, u * 0.14);
      default:
        return Path()..addOval(Rect.fromCircle(center: c, radius: u * 0.06));
    }
  }

  Path _brainPath(Offset c, double r) {
    // Two bumpy hemispheres.
    final p = Path();
    p.addOval(Rect.fromCenter(center: c, width: r * 2.1, height: r * 1.7));
    for (var i = 0; i < 5; i++) {
      final a = math.pi * (i / 4);
      final b = Offset(
          c.dx + math.cos(a) * r * 0.95, c.dy - math.sin(a).abs() * r * 0.7);
      p.addOval(Rect.fromCircle(center: b, radius: r * 0.34));
    }
    return p;
  }

  Path _lungsPath(Offset c, double u) {
    // Two lobes flanking the sternum.
    final p = Path();
    final w = u * 0.11, h = u * 0.16;
    for (final s in [-1.0, 1.0]) {
      final lobe = Offset(c.dx + s * u * 0.085, c.dy);
      final r = Rect.fromCenter(center: lobe, width: w, height: h);
      p.addRRect(RRect.fromRectAndCorners(
        r,
        topLeft: Radius.circular(w * 0.6),
        topRight: Radius.circular(w * 0.6),
        bottomLeft: Radius.circular(s < 0 ? w * 0.9 : w * 0.3),
        bottomRight: Radius.circular(s < 0 ? w * 0.3 : w * 0.9),
      ));
    }
    return p;
  }

  Path _heartPath(Offset c, double r) {
    final p = Path();
    p.moveTo(c.dx, c.dy + r * 0.9);
    p.cubicTo(c.dx - r * 1.5, c.dy - r * 0.2, c.dx - r * 0.7,
        c.dy - r * 1.4, c.dx, c.dy - r * 0.5);
    p.cubicTo(c.dx + r * 0.7, c.dy - r * 1.4, c.dx + r * 1.5,
        c.dy - r * 0.2, c.dx, c.dy + r * 0.9);
    p.close();
    return p;
  }

  Path _liverPath(Offset c, double r) {
    // Wedge with a soft lower edge.
    final p = Path();
    p.moveTo(c.dx - r, c.dy - r * 0.5);
    p.lineTo(c.dx + r, c.dy - r * 0.62);
    p.quadraticBezierTo(
        c.dx + r * 0.9, c.dy + r * 0.5, c.dx - r * 0.2, c.dy + r * 0.55);
    p.quadraticBezierTo(
        c.dx - r * 0.9, c.dy + r * 0.5, c.dx - r, c.dy - r * 0.5);
    p.close();
    return p;
  }

  Path _stomachPath(Offset c, double r) {
    // J / bean shape.
    final p = Path();
    p.moveTo(c.dx + r * 0.2, c.dy - r * 0.8);
    p.quadraticBezierTo(
        c.dx + r * 1.0, c.dy - r * 0.5, c.dx + r * 0.7, c.dy + r * 0.4);
    p.quadraticBezierTo(
        c.dx + r * 0.4, c.dy + r * 1.1, c.dx - r * 0.4, c.dy + r * 0.7);
    p.quadraticBezierTo(
        c.dx - r * 0.9, c.dy + r * 0.4, c.dx - r * 0.5, c.dy - r * 0.2);
    p.quadraticBezierTo(
        c.dx - r * 0.2, c.dy - r * 0.7, c.dx + r * 0.2, c.dy - r * 0.8);
    p.close();
    return p;
  }

  Path _kidneysPath(Offset c, double u) {
    final p = Path();
    final r = u * 0.055;
    for (final s in [-1.0, 1.0]) {
      final k = Offset(c.dx + s * u * 0.075, c.dy);
      final path = Path();
      path.moveTo(k.dx - s * r * 0.2, k.dy - r);
      path.quadraticBezierTo(
          k.dx + s * r * 1.1, k.dy - r * 0.8, k.dx + s * r * 1.0, k.dy);
      path.quadraticBezierTo(
          k.dx + s * r * 1.1, k.dy + r * 0.8, k.dx - s * r * 0.2, k.dy + r);
      path.quadraticBezierTo(
          k.dx - s * r * 0.5, k.dy, k.dx - s * r * 0.2, k.dy - r);
      path.close();
      p.addPath(path, Offset.zero);
    }
    return p;
  }

  Path _intestinesPath(Offset c, double r) {
    // Coiled loops approximated by stacked rounded rects.
    final p = Path();
    p.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: r * 1.9, height: r * 1.5),
      Radius.circular(r * 0.6),
    ));
    for (var i = 0; i < 3; i++) {
      final y = c.dy - r * 0.4 + i * r * 0.45;
      p.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(c.dx, y), width: r * 1.5, height: r * 0.28),
        Radius.circular(r * 0.14),
      ));
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _OrganMapPainter old) {
    return old.pulse != pulse ||
        old.currentHour != currentHour ||
        old.activeIds != activeIds ||
        old.activations != activations;
  }
}
