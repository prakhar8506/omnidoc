import 'package:flutter/material.dart';

import '../../../core/nutrition/diet_planner.dart';
import '../../../core/nutrition/nutrition_targets.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/holographic_background.dart';

class DietPlanScreen extends StatelessWidget {
  const DietPlanScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final targets = appState.nutritionTargets;
        final plan = buildDietPlan(
          style: appState.dietStyle,
          allergies: appState.allergies,
          targets: targets,
        );
        final focus = dietFocus(
          conditions: appState.chronicConditions,
          allergies: appState.allergies,
          labTests: appState.labTestsForDiet(),
        );
        return Scaffold(
          body: HolographicBackground(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      Text('Your diet plan', style: AppTypography.editorialSm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Goal', style: AppTypography.labelSm),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      ('deficit', 'Deficit'),
                      ('maintain', 'Maintain'),
                      ('surplus', 'Surplus'),
                      ('recomp', 'Recomp'),
                    ].map((item) {
                      return ChoiceChip(
                        label: Text(item.$2),
                        selected: appState.dietGoal == item.$1,
                        onSelected: (_) => appState.setDietGoal(item.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text('Eating style', style: AppTypography.labelSm),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      ('vegetarian', 'Vegetarian'),
                      ('eggetarian', 'Eggs ok'),
                      ('non-vegetarian', 'Non-veg'),
                      ('vegan', 'Vegan'),
                    ].map((item) {
                      return ChoiceChip(
                        label: Text(item.$2),
                        selected: appState.dietStyle == item.$1,
                        onSelected: (_) => appState.setDietStyle(item.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(planIntro(targets), style: const TextStyle(height: 1.4)),
                        const SizedBox(height: 8),
                        Text(
                          'Height ${appState.userHeightCm?.round() ?? '—'} cm · '
                          'Weight ${appState.userWeightKg?.toStringAsFixed(1) ?? '—'} kg · '
                          'Water about ${targets.waterMl} ml',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...focus.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $line', style: const TextStyle(height: 1.35, fontSize: 13.5)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...plan.map((meal) => _mealCard(meal)),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a meal pattern from average foods, your goal, allergies, and labs already saved in Cura. It is not a prescription.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mealCard(PlannedMeal meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meal.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ...meal.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.name} · ${option.calories} kcal · ${option.protein}g protein',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    ...option.lines.map(
                      (line) => Text(line.text, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
