import 'package:flutter/material.dart';

import '../../../core/charts/charts.dart';
import '../../../core/fitness/fitness_goal.dart';
import '../../../core/nutrition/nutrition_targets.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/widgets/log_meal_sheet.dart';
import '../../premium/premium_screen.dart';
import '../screens/coach_program_screen.dart';
import '../screens/fitness_goal_screen.dart';

/// Goal, body size, food diary, and exercise diary. The multi-week coach stays premium.
class FitnessHubPanel extends StatelessWidget {
  const FitnessHubPanel({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.7);
    final card = Theme.of(context).colorScheme.surface;
    final inset = dark ? const Color(0xFF2A2C3A) : Colors.white.withValues(alpha: 0.9);
    final now = DateTime.now();
    final today = foodOnDay(appState.loggedMeals, now);
    final average = averageLoggedCalories(appState.loggedMeals, now);
    final bmi = bmiReading(
      heightCm: appState.userHeightCm,
      weightKg: appState.userWeightKg,
      dobIso: appState.dateOfBirth,
    );
    final energy = _energy();
    final trend = weightChangeLine(appState.weightLogs);
    final aim = FitnessAim.labelFor(appState.fitnessAim);
    final event = FitnessAim.eventLabel(appState.fitnessAim, appState.fitnessEvent);

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
          Text('Training goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
            aim.isEmpty
                ? 'Choose lose, gain, maintain, recomposition, or a race such as Ironman, HYROX, or running.'
                : [aim, if (event.isNotEmpty) event, '${appState.weeklyTrainingHours} h a week'].join(' · '),
            style: TextStyle(height: 1.35, color: muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FitnessGoalScreen(appState: appState)),
                ),
                child: Text(aim.isEmpty ? 'Set my goal' : 'Change goal'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => PremiumAccess.require(
                  context,
                  appState,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CoachProgramScreen(appState: appState)),
                  ),
                ),
                icon: Icon(appState.hasPremium ? Icons.flag_rounded : Icons.lock_rounded, size: 18),
                label: const Text('Coach program'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The week-by-week coach is part of Premium. Meals, weight, water, steps, and BMI stay available without it.',
            style: TextStyle(fontSize: 12, height: 1.35, color: muted),
          ),
          const SizedBox(height: 12),
          if (appState.recoveryResult == null)
            const GhostLine(caption: 'Readiness appears after a wearable sync.')
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ReadinessGauge(
                score: appState.recoveryResult!.score.toDouble(),
                caption: appState.recoveryResult!.readinessState,
              ),
            ),
          const SizedBox(height: 16),
          Text('Body', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          if (bmi == null)
            const GhostLine(caption: 'BMI needs a measured height and weight.')
          else
            RangeBar(
              value: bmi.value,
              low: 18.5,
              high: 24.9,
              caption: 'BMI ${bmi.value.toStringAsFixed(1)} · ${bmi.label}',
            ),
          const SizedBox(height: 4),
          Text(
            appState.userWeightKg == null
                ? 'No weight saved.'
                : 'Weight ${appState.userWeightKg!.toStringAsFixed(1)} kg',
            style: TextStyle(color: ink),
          ),
          if (trend != null) Text(trend, style: TextStyle(color: muted, height: 1.35)),
          if (appState.weightLogs.length == 1)
            Text('One weigh-in saved. A trend needs a second one on another day.', style: TextStyle(color: muted, height: 1.35)),
          if (appState.waistCm != null)
            Text('Waist ${appState.waistCm!.toStringAsFixed(1)} cm', style: TextStyle(color: ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: () => _askNumber(context, weight: true), child: const Text('Log weight')),
              OutlinedButton(onPressed: () => _askNumber(context, weight: false), child: const Text('Log waist')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Food diary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          WeekBars(
            values: [
              for (var i = 6; i >= 0; i--)
                () {
                  final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
                  final food = foodOnDay(appState.loggedMeals, day);
                  return food.meals == 0 ? null : food.calories.toDouble();
                }(),
            ],
            caption: 'Calories on days you logged a meal.',
          ),
          const SizedBox(height: 6),
          Text(
            today.meals == 0
                ? 'No meals logged today.'
                : '${today.meals} meal${today.meals == 1 ? '' : 's'} today · ${today.calories} kcal · protein ${today.protein} g · carbs ${today.carbs} g · fat ${today.fat} g',
            style: TextStyle(color: ink, height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            energy == null
                ? 'A calorie goal is hidden until height, weight, sex, and date of birth are all saved.'
                : '${energy.note} Activity setting: ${appState.activityLevel}.',
            style: TextStyle(color: muted, height: 1.35, fontSize: 13),
          ),
          if (energy != null) ...[
            const SizedBox(height: 8),
            _bar(inset, ink, 'Calories', today.calories, energy.calories, 'kcal'),
            _bar(inset, ink, 'Protein', today.protein, energy.protein, 'g'),
            _bar(inset, ink, 'Carbs', today.carbs, energy.carbs, 'g'),
            _bar(inset, ink, 'Fat', today.fat, energy.fat, 'g'),
          ],
          if (average != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'On the $average.days day${average.days == 1 ? '' : 's'} you logged in the last week, the average was ${average.calories} kcal. Days with no log are not counted as zero.',
                style: TextStyle(color: muted, height: 1.35, fontSize: 13),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            appState.userWeightKg == null
                ? 'Water logged today: ${appState.dailyHydrationMl} ml. A water amount is not estimated without a weight.'
                : 'Water ${appState.dailyHydrationMl} ml today. A rough guide from your weight is about ${(appState.userWeightKg! * 33).round()} ml. That is not a prescription.',
            style: TextStyle(color: muted, height: 1.35, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => LogMealSheet(appState: appState),
                ),
                child: const Text('Log a meal'),
              ),
              if (appState.loggedMeals.isNotEmpty)
                OutlinedButton(onPressed: () => _repeatLast(), child: const Text('Log last meal again')),
              OutlinedButton(onPressed: () => appState.addHydration(250), child: const Text('+250 ml')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Exercise diary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text(
            appState.dailySteps > 0
                ? '${appState.dailySteps.round()} steps from your watch today.'
                : 'No steps from your watch today.',
            style: TextStyle(color: ink, height: 1.35),
          ),
          const SizedBox(height: 4),
          if (appState.completedWorkouts.isEmpty)
            Text('No workout logged yet.', style: TextStyle(color: muted))
          else
            for (final workout in appState.completedWorkouts.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${workout['title'] ?? 'Workout'} · ${workout['duration'] ?? ''}',
                  style: TextStyle(color: ink, height: 1.3),
                ),
              ),
        ],
      ),
    );
  }

  MacroTargets? _energy() {
    final height = appState.userHeightCm;
    final weight = appState.userWeightKg;
    final sex = appState.biologicalSex ?? '';
    final dob = DateTime.tryParse(appState.dateOfBirth ?? '');
    if (height == null || weight == null || height <= 0 || weight <= 0 || sex.trim().isEmpty || dob == null) {
      return null;
    }
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    if (age < 18 || age > 100) return null;
    final targets = computeTargets(NutritionInputs(
      heightCm: height,
      weightKg: weight,
      age: age,
      sex: sex,
      goal: appState.dietGoal,
      activity: appState.activityLevel,
    ));
    return targets;
  }

  Widget _bar(Color inset, Color ink, String label, int current, int goal, String unit) {
    final fraction = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
    final over = current > goal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            over ? '$label $current / $goal $unit · over by ${current - goal}' : '$label $current / $goal $unit',
            style: TextStyle(fontSize: 12, color: ink),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: inset,
              color: AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _repeatLast() {
    final last = appState.loggedMeals.first;
    appState.addMeal({
      'title': last['title'],
      'category': last['category'] ?? 'Meal',
      'time': last['time'] ?? 'Meal',
      'calories': last['calories'] ?? 0,
      'protein': last['protein'] ?? 0,
      'carbs': last['carbs'] ?? 0,
      'fat': last['fat'] ?? 0,
      'fiber': last['fiber'] ?? 0,
    });
  }

  Future<void> _askNumber(BuildContext context, {required bool weight}) async {
    final controller = TextEditingController();
    final ink = Theme.of(context).colorScheme.onSurface;
    final saved = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(weight ? 'Weight in kg' : 'Waist in cm', style: TextStyle(color: ink)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: ink),
          decoration: InputDecoration(hintText: weight ? 'For example 72.4' : 'For example 84'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) return;
    if (weight) {
      appState.logBodyWeight(saved);
    } else {
      appState.saveWaist(saved);
    }
  }
}
