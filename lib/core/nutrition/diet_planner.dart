import 'food_catalog.dart';
import 'nutrition_targets.dart';

class PlanLine {
  const PlanLine(this.food, this.quantity);
  final CatalogFood food;
  final double quantity;

  int get calories => (food.kcal * quantity).round();
  int get protein => (food.protein * quantity).round();

  String get text {
    final qty = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return '$qty × ${food.servingName} ${food.aliases.first} · $calories kcal · ${protein}g protein';
  }
}

class MealOption {
  const MealOption(this.name, this.lines);
  final String name;
  final List<PlanLine> lines;

  int get calories => lines.fold(0, (s, l) => s + l.calories);
  int get protein => lines.fold(0, (s, l) => s + l.protein);
}

class PlannedMeal {
  const PlannedMeal(this.title, this.options);
  final String title;
  final List<MealOption> options;
}

CatalogFood _food(String id) => foodCatalog.firstWhere((f) => f.id == id);

bool foodBlocked(CatalogFood food, List<String> allergies, String style) {
  if (style == 'vegan' && (food.meat || food.egg || food.dairy)) return true;
  if (style == 'vegetarian' && (food.meat || food.egg)) return true;
  if (style == 'eggetarian' && food.meat) return true;
  final tags = allergies.map((a) => a.toLowerCase()).toList();
  for (final allergen in food.allergens) {
    if (tags.any((t) => t.contains(allergen) || allergen.contains(t))) return true;
  }
  return false;
}

List<PlannedMeal> buildDietPlan({
  required String style,
  required List<String> allergies,
  required MacroTargets targets,
}) {
  MealOption? option(String name, List<(String, double)> parts) {
    final lines = <PlanLine>[];
    for (final part in parts) {
      final food = _food(part.$1);
      if (foodBlocked(food, allergies, style)) return null;
      lines.add(PlanLine(food, part.$2));
    }
    return MealOption(name, lines);
  }

  PlannedMeal meal(String title, List<MealOption?> options) {
    final kept = options.whereType<MealOption>().toList();
    if (kept.isEmpty) {
      final fallback = option('Simple plate', [('dal', 1), ('sabzi', 1), ('rice', 1)]);
      return PlannedMeal(title, [if (fallback != null) fallback]);
    }
    return PlannedMeal(title, kept);
  }

  return [
    meal('Breakfast', [
      option('Eggs and toast', [('egg', 3), ('bread', 2), ('apple', 1)]),
      option('Oats', [('oats', 1), ('milk', 1), ('almonds', 1)]),
      option('Idli and dal', [('idli', 3), ('dal', 1)]),
    ]),
    meal('Lunch', [
      option('Roti, dal, vegetables', [('roti', 2), ('dal', 1), ('sabzi', 1), ('curd', 1)]),
      option('Rice and rajma', [('rice', 1), ('rajma', 1), ('salad', 1)]),
      option('Chicken and rice', [('chicken', 1.5), ('rice', 1), ('salad', 1)]),
    ]),
    meal('Snack', [
      option('Fruit and nuts', [('apple', 1), ('almonds', 1)]),
      option('Protein scoop', [('whey', 1), ('banana', 1)]),
      option('Curd', [('curd', 1), ('peanuts', 1)]),
    ]),
    meal('Dinner', [
      option('Paneer and roti', [('roti', 2), ('paneer', 1), ('salad', 1)]),
      option('Dal and vegetables', [('dal', 1), ('sabzi', 1), ('roti', 2)]),
      option('Fish and rice', [('fish', 1.5), ('brown_rice', 1), ('salad', 1)]),
    ]),
  ];
}

String planIntro(MacroTargets targets) =>
    '${targets.goalLabel}. Aim for about ${targets.calories} kcal, '
    '${targets.protein}g protein, ${targets.carbs}g carbs, and ${targets.fat}g fat. '
    'BMI ${targets.bmi} (${targets.bmiLabel}). ${targets.note}';
