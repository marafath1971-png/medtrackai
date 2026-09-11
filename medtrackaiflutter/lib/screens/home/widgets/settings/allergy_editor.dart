import 'package:flutter/material.dart';

import '../../../../core/utils/haptic_engine.dart';
import '../../../../domain/entities/allergy.dart';
import '../../../../theme/med_ai_ui.dart';

/// Editor for the user's medication allergies.
///
/// Until this existed, allergies could only be set once during onboarding, from
/// four fixed checkboxes — so a user who developed an allergy, or who is
/// allergic to anything outside that list, had no way to record it. The values
/// feed the scanner's ingredient cross-reference, so being unable to correct
/// them was a safety gap rather than a missing convenience.
///
/// Presets are offered as one-tap chips; free text covers everything else.
class AllergyEditor extends StatefulWidget {
  final List<String> allergies;
  final ValueChanged<List<String>> onChanged;
  final AppThemeColors L;

  const AllergyEditor({
    super.key,
    required this.allergies,
    required this.onChanged,
    required this.L,
  });

  @override
  State<AllergyEditor> createState() => _AllergyEditorState();
}

class _AllergyEditorState extends State<AllergyEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _has(String label) =>
      widget.allergies.any((a) => a.toLowerCase() == label.toLowerCase());

  void _commit(List<String> next) {
    // Normalize here too: the editor is a write path into the safety prompt,
    // so it must not be able to store blanks, duplicates, or overlong entries.
    widget.onChanged(normalizeAllergies(next));
  }

  void _toggle(String label) {
    HapticEngine.selection();
    if (_has(label)) {
      _commit(widget.allergies
          .where((a) => a.toLowerCase() != label.toLowerCase())
          .toList());
    } else {
      _commit([...widget.allergies, label]);
    }
  }

  void _addTyped() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (widget.allergies.length >= kMaxAllergyCount) return;
    HapticEngine.success();
    _commit([...widget.allergies, text]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final atCapacity = widget.allergies.length >= kMaxAllergyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.p16, AppSpacing.p12, AppSpacing.p16, AppSpacing.p8),
          child: Text(
            'Used to cross-check ingredients when you scan a product.',
            style: AppTypography.bodySmall.copyWith(color: L.sub),
          ),
        ),

        // Quick-add presets.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Wrap(
            spacing: AppSpacing.p8,
            runSpacing: AppSpacing.p8,
            children: [
              for (final label in kAllergyPresets.values)
                _AllergyChip(
                  label: label,
                  selected: _has(label),
                  onTap: () => _toggle(label),
                  L: L,
                ),
            ],
          ),
        ),

        // Anything the user added that isn't a preset.
        if (widget.allergies
            .any((a) => !kAllergyPresets.values.contains(a))) ...[
          const SizedBox(height: AppSpacing.p12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: Wrap(
              spacing: AppSpacing.p8,
              runSpacing: AppSpacing.p8,
              children: [
                for (final label in widget.allergies
                    .where((a) => !kAllergyPresets.values.contains(a)))
                  _AllergyChip(
                    label: label,
                    selected: true,
                    removable: true,
                    onTap: () => _toggle(label),
                    L: L,
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.p12),

        // Free-text entry for allergies outside the preset list.
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.p16, 0, AppSpacing.p16, AppSpacing.p16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !atCapacity,
                  maxLength: kMaxAllergyLength,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _addTyped(),
                  style: AppTypography.bodyMedium.copyWith(color: L.text),
                  decoration: InputDecoration(
                    hintText: atCapacity
                        ? 'Maximum reached'
                        : 'Add another, e.g. Codeine',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: L.sub),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: L.bg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.p12, vertical: AppSpacing.p12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: L.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: L.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              IconButton(
                onPressed: atCapacity ? null : _addTyped,
                icon: const Icon(Icons.add_rounded),
                color: L.accent,
                tooltip: 'Add allergy',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllergyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool removable;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _AllergyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.L,
    this.removable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Remove allergy $label' : 'Add allergy $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.p12, vertical: AppSpacing.p8),
          decoration: BoxDecoration(
            color: selected ? L.accent.withValues(alpha: 0.14) : L.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? L.accent : L.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? L.accent : L.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.p4),
                Icon(
                  removable ? Icons.close_rounded : Icons.check_rounded,
                  size: 14,
                  color: L.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
