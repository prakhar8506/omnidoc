import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/nutrition/meal_parser.dart';
import 'package:health_companion/core/nutrition/nutrition_targets.dart';

void main() {
  test('three eggs use the average for a large egg', () {
    final meal = parseMealText('I had 3 eggs for breakfast');
    expect(meal.lines, hasLength(1));
    expect(meal.calories.round(), 216);
    expect(meal.protein.round(), 19);
    expect(meal.unmatched, isEmpty);
  });

  test('mixed Indian plate adds each food', () {
    final meal = parseMealText('2 roti and 1 bowl dal');
    expect(meal.lines, hasLength(2));
    expect(meal.calories.round(), 104 * 2 + 170);
    expect(meal.protein.round(), (3.1 * 2 + 11).round());
  });

  test('paneer grams scale from the 100 g average', () {
    final meal = parseMealText('100g paneer');
    expect(meal.calories.round(), 265);
    expect(meal.protein.round(), 18);
  });

  test('recomp target sits slightly under maintenance with high protein', () {
    final targets = computeTargets(
      const NutritionInputs(
        heightCm: 170,
        weightKg: 70,
        age: 30,
        sex: 'female',
        goal: 'recomp',
        activity: 'moderate',
      ),
    );
    expect(targets.calories, lessThan(targets.tdee));
    expect(targets.protein, 140);
    expect(targets.goalLabel, 'Body recomposition');
  });
}
