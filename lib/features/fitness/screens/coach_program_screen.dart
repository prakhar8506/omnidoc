import 'package:flutter/material.dart';

import '../../../core/fitness/coach_program.dart';
import '../../../core/state/app_state.dart';

class CoachProgramScreen extends StatelessWidget {
  const CoachProgramScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.72);
    final card = Theme.of(context).colorScheme.surface;
    if (appState.fitnessAim.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Coach program', style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Choose a training goal first. The week is built from that choice, not from a default plan.',
            style: TextStyle(color: ink, height: 1.4),
          ),
        ),
      );
    }
    final readiness = (appState.recoveryResult?.readinessState ?? '').toLowerCase();
    final program = buildCoachProgram(
      aim: appState.fitnessAim,
      event: appState.fitnessEvent,
      raceDateIso: appState.raceDateIso,
      startedIso: appState.fitnessGoalStartedIso,
      weeklyHours: appState.weeklyTrainingHours,
      readiness: appState.recoveryResult?.readinessState,
      gentle: readiness.contains('rest') || _glpNoted,
      bloodPressureMedicine: appState.heavyMedications.any((m) => m.toLowerCase().contains('blood pressure')),
      hasHeartRateZones: _hasZones(),
      hasBodySize: appState.userHeightCm != null &&
          appState.userWeightKg != null &&
          (appState.biologicalSex ?? '').isNotEmpty &&
          appState.dateOfBirth != null,
      hasSleep: appState.sleepDuration.trim().isNotEmpty && appState.sleepDuration != '—',
    );

    return Scaffold(
      appBar: AppBar(title: Text('Coach program', style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(program.headline, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(program.phase, style: TextStyle(color: muted, height: 1.35)),
          const SizedBox(height: 14),
          for (final line in program.guardrails)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $line', style: TextStyle(color: ink, height: 1.35)),
            ),
          const SizedBox(height: 8),
          Text('This week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          for (final session in program.sessions)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ink.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 4),
                  Text(session.detail, style: TextStyle(height: 1.35, color: muted)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        appState.logWorkout(
                          title: session.title,
                          category: program.headline,
                          duration: session.title,
                          caloriesBurned: 0,
                          avgHr: 0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logged “${session.title}”.')),
                        );
                      },
                      child: const Text('Log as done'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _hasZones() {
    final dob = DateTime.tryParse(appState.dateOfBirth ?? '');
    return dob != null && appState.restingHeartRate > 0;
  }

  bool get _glpNoted {
    final glp = appState.glp1Status;
    return glp == 'Yes' || glp.startsWith('I have a prescription') || glp.startsWith('I’m in the process');
  }
}
