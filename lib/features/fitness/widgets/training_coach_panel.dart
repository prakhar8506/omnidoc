import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../premium/premium_screen.dart';

/// Daily training context from logged readiness. Missing inputs stay blank.
class TrainingCoachPanel extends StatelessWidget {
  const TrainingCoachPanel({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = Theme.of(context).colorScheme.surface;
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.7);
    final readiness = appState.recoveryResult?.readinessState;
    final zones = _zones();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: dark ? 0.08 : 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today’s training', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
            readiness == null
                ? 'No readiness score yet. Connect a wearable or keep logging before a plan can follow your recovery.'
                : 'Readiness on file: $readiness.',
            style: TextStyle(fontSize: 13, height: 1.35, color: muted),
          ),
          const SizedBox(height: 12),
          Text('Heart-rate zones', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
            zones ?? 'Add your date of birth and a measured resting heart rate to see zone ranges. Nothing is estimated from a default age.',
            style: TextStyle(fontSize: 13, height: 1.35, color: muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => PremiumAccess.require(
                context,
                appState,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => WorkoutPlanScreen(appState: appState)),
                ),
              ),
              icon: Icon(appState.hasPremium ? Icons.fitness_center_rounded : Icons.lock_rounded, size: 18),
              label: Text(appState.hasPremium ? 'Build my workout' : 'Workout plan · Premium'),
            ),
          ),
        ],
      ),
    );
  }

  String? _zones() {
    final dob = DateTime.tryParse(appState.dateOfBirth ?? '');
    final resting = appState.restingHeartRate;
    if (dob == null || resting <= 0) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    if (age < 13 || age > 100) return null;
    final maxHr = 220 - age;
    final reserve = maxHr - resting;
    if (reserve <= 0) return null;
    String zone(double low, double high) {
      final a = (resting + reserve * low).round();
      final b = (resting + reserve * high).round();
      return '$a–$b';
    }
    return 'From age $age and resting $resting bpm. Zone 2 ${zone(0.6, 0.7)} · Zone 3 ${zone(0.7, 0.8)} · Zone 4 ${zone(0.8, 0.9)}. This is a population formula, not a lab test.';
  }
}

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  int _minutes = 30;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final card = Theme.of(context).colorScheme.surface;
    final steps = _steps();

    return Scaffold(
      appBar: AppBar(title: Text('Workout plan', style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('How long today?', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final minutes in [15, 30, 45])
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: _minutes == minutes,
                  onSelected: (_) => setState(() => _minutes = minutes),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final step in steps)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
              child: Text(step, style: TextStyle(height: 1.35, color: ink)),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              widget.appState.logWorkout(
                title: 'Planned session',
                category: 'Custom plan',
                duration: '$_minutes min',
                caloriesBurned: 0,
                avgHr: 0,
              );
              Navigator.pop(context);
            },
            child: const Text('Log this session as done'),
          ),
        ],
      ),
    );
  }

  List<String> _steps() {
    final readiness = (widget.appState.recoveryResult?.readinessState ?? '').toLowerCase();
    final gentle = readiness.contains('rest') || widget.appState.glp1Status == 'Yes';
    final bpMed = widget.appState.heavyMedications.any((m) => m.toLowerCase().contains('blood pressure'));
    final notes = <String>[
      if (gentle) 'Keep the effort easy to talk through. A hard session is a poor match for a rest day or a new GLP-1 start.',
      if (bpMed) 'Skip breath-holding and all-out efforts while you are on blood-pressure medicine. Stop if you feel dizzy.',
      if (widget.appState.recoveryResult == null) 'This plan is a general session because no recovery score is on file yet.',
    ];
    final main = gentle
        ? 'Easy walk or mobility for $_minutes minutes. Finish with 2 minutes of slow breathing.'
        : _minutes <= 15
            ? '5 minutes easy, then 8 minutes of squats, wall push-ups, and a hip hinge, then an easy finish.'
            : '8 minutes easy, then two rounds of a squat, a push, and a hinge, leaving enough breath to speak a sentence, then an easy finish. Aim for about $_minutes minutes.';
    return [...notes, main];
  }
}
