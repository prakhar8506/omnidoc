import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Metabolism context from logs the person actually has.
/// Missing inputs stay blank instead of being filled with sample numbers.
class MetabolismPanel extends StatelessWidget {
  final AppState appState;

  const MetabolismPanel({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF1C1E2A) : Colors.white;
    final ink = dark ? const Color(0xFFF4F2FA) : AppColors.textPrimary;
    final muted = dark ? const Color(0xFFB7B4C8) : AppColors.textSecondary;
    final estimate = _restingEstimate();
    final labs = _metabolicLabs();
    final now = DateTime.now();
    var mealCalories = 0.0;
    for (final meal in appState.loggedMeals) {
      final logged = DateTime.tryParse(meal['loggedAt']?.toString() ?? '');
      if (logged == null || logged.year != now.year || logged.month != now.month || logged.day != now.day) {
        continue;
      }
      mealCalories += (meal['calories'] as num?)?.toDouble() ?? 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.withValues(alpha: dark ? 1 : 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.08 : 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF8A3D), size: 20),
              const SizedBox(width: 8),
              Text('Metabolism', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Drawn from your activity, meals, medicines, and lab markers. This is context, not a diagnosis.',
            style: TextStyle(fontSize: 12, height: 1.35, color: muted),
          ),
          const SizedBox(height: 14),
          _row('Activity', appState.dailySteps > 0 ? '${appState.dailySteps.round()} steps today' : 'No steps recorded today', ink, muted),
          _row(
            'Meals',
            mealCalories > 0 ? '${mealCalories.round()} kcal logged today' : 'No meals logged today',
            ink,
            muted,
          ),
          _row(
            'Workouts',
            appState.completedWorkouts.isEmpty
                ? 'No workout logged yet'
                : '${appState.completedWorkouts.length} workout${appState.completedWorkouts.length == 1 ? '' : 's'} logged',
            ink,
            muted,
          ),
          _row('Resting burn', estimate ?? 'Add height, weight, sex, and date of birth to estimate this', ink, muted),
          _row('Medicines', _medicineLine(), ink, muted),
          _row('Labs', labs ?? 'No metabolic lab markers on file', ink, muted),
        ],
      ),
    );
  }

  String? _restingEstimate() {
    final height = appState.userHeightCm;
    final weight = appState.userWeightKg;
    final sex = (appState.biologicalSex ?? '').toLowerCase();
    final dob = DateTime.tryParse(appState.dateOfBirth ?? '');
    if (height == null || weight == null || height <= 0 || weight <= 0 || dob == null || sex.isEmpty) {
      return null;
    }
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    if (age < 13 || age > 100) return null;
    final female = sex.contains('female') || sex.contains('woman');
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + (female ? -161 : 5);
    return 'About ${bmr.round()} kcal/day at rest, from your height, weight, age, and sex';
  }

  String _medicineLine() {
    final glp = appState.glp1Status;
    final others = appState.heavyMedications.where((m) => m != 'None of these' && m != 'I prefer not to say');
    final parts = <String>[];
    if (glp == 'Yes' || glp.startsWith('I have a prescription') || glp.startsWith('I’m in the process')) {
      parts.add('GLP-1 noted');
    }
    parts.addAll(others);
    if (parts.isEmpty) return 'No metabolism-related medicine recorded';
    return parts.join(' · ');
  }

  String? _metabolicLabs() {
    final report = appState.activeReport;
    if (report == null) return null;
    const keys = ['glucose', 'a1c', 'hba1c', 'tsh', 'ldl', 'cholesterol', 'triglyceride'];
    final hits = report.biomarkers.where((b) {
      final name = '${b.name} ${b.code}'.toLowerCase();
      return keys.any(name.contains);
    }).toList();
    if (hits.isEmpty) return null;
    return hits.take(3).map((b) => '${b.name} ${b.value} ${b.unit}'.trim()).join(' · ');
  }

  Widget _row(String label, String value, Color ink, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, color: ink)),
        ],
      ),
    );
  }
}
