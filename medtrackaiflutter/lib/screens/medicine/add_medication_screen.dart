import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/med_ai_ui.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _showSuggestions = false;
  String _selectedSchedule = 'Every day';
  bool _remindMe = true;

  final List<String> _scheduleOptions = ['Every day', 'Specific days', 'As needed'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    
    return Scaffold(
      backgroundColor: L.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: L.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Add Medication",
          style: AppTypography.titleMedium.copyWith(color: L.text, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication Name Input
            MedAiDepthCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Medication Name", style: AppTypography.labelMedium.copyWith(color: L.sub)),
                  TextField(
                    controller: _nameController,
                    onChanged: (val) {
                      setState(() {
                        _showSuggestions = val.isNotEmpty;
                      });
                    },
                    style: AppTypography.headlineMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: "e.g. Lisinopril",
                      hintStyle: AppTypography.headlineMedium.copyWith(
                        color: L.sub.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 8, bottom: 4),
                    ),
                  ),
                ],
              ),
            ),
            
            // Autocomplete Suggestions (Simulated)
            if (_showSuggestions)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MedAiDepthCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSuggestionItem("Lisinopril 10mg", Icons.medication),
                      const Divider(height: 1, thickness: 0.5),
                      _buildSuggestionItem("Lisinopril 20mg", Icons.medication),
                      const Divider(height: 1, thickness: 0.5),
                      _buildSuggestionItem("Lisinopril-HCTZ", Icons.medication_liquid),
                    ],
                  ),
                ),
              ).animate().fade(duration: 200.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 32),
            
            // Schedule Configuration
            const MedAiSectionHeader(
              title: "Schedule",
              subtitle: "When do you take this?",
            ),
            
            // Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _scheduleOptions.map((option) {
                  final isSelected = _selectedSchedule == option;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedSchedule = option);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? L.text : L.card,
                          borderRadius: AppRadius.roundXL,
                          border: isSelected
                              ? null
                              : Border.all(color: L.border.withValues(alpha: 0.5), width: 1),
                          boxShadow: isSelected ? AppShadows.glow(L.text, intensity: 0.2) : [],
                        ),
                        child: Text(
                          option,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected ? L.bg : L.text,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),

            // Remind Me Toggle
            MedAiDepthCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Remind Me",
                        style: AppTypography.titleMedium.copyWith(color: L.text, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Get a notification when it's time",
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _remindMe,
                    activeColor: L.accent,
                    onChanged: (val) {
                      setState(() => _remindMe = val);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),

            // Add Button
            MedAiCTA(
              label: "Add Medication",
              icon: Icons.check_circle_outline,
              onTap: () {
                // Return to previous screen
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String name, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _nameController.text = name;
          _showSuggestions = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.L.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.L.accent, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: AppTypography.titleMedium.copyWith(
                color: context.L.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
