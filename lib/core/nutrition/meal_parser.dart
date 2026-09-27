import 'food_catalog.dart';

class ParsedFoodLine {
  const ParsedFoodLine({
    required this.food,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final CatalogFood food;
  final double quantity;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  String get label {
    final qty = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    final unit = food.per100g ? '× 100 g' : food.servingName;
    return '$qty $unit ${food.aliases.first}';
  }

  Map<String, dynamic> toJson() => {
        'id': food.id,
        'label': label,
        'quantity': quantity,
        'calories': calories.round(),
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      };
}

class ParsedMeal {
  const ParsedMeal({required this.lines, required this.unmatched});

  final List<ParsedFoodLine> lines;
  final List<String> unmatched;

  double get calories => lines.fold(0, (s, l) => s + l.calories);
  double get protein => lines.fold(0, (s, l) => s + l.protein);
  double get carbs => lines.fold(0, (s, l) => s + l.carbs);
  double get fat => lines.fold(0, (s, l) => s + l.fat);
  double get fiber => lines.fold(0, (s, l) => s + l.fiber);

  bool get isEmpty => lines.isEmpty;
}

const _numberWords = {
  'a': 1.0,
  'an': 1.0,
  'one': 1.0,
  'two': 2.0,
  'three': 3.0,
  'four': 4.0,
  'five': 5.0,
  'six': 6.0,
  'seven': 7.0,
  'eight': 8.0,
  'nine': 9.0,
  'ten': 10.0,
  'half': 0.5,
};

/// Turns phrases like "3 eggs and 2 roti" into average calories and macros.
ParsedMeal parseMealText(String raw) {
  var text = raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  text = text
      .replaceAll(RegExp(r'\b(for breakfast|for lunch|for dinner|for snack|i had|i ate|had|ate)\b'), ' ')
      .replaceAll(RegExp(r'\b(and|with|\+|\&)\b'), ',');
  final chunks = text.split(RegExp(r'[,;]')).map((c) => c.trim()).where((c) => c.isNotEmpty);
  final lines = <ParsedFoodLine>[];
  final unmatched = <String>[];

  for (final chunk in chunks) {
    final parsed = _parseChunk(chunk);
    if (parsed == null) {
      if (chunk.length > 1) unmatched.add(chunk);
    } else {
      lines.add(parsed);
    }
  }
  return ParsedMeal(lines: lines, unmatched: unmatched);
}

ParsedFoodLine? _parseChunk(String chunk) {
  final grams = RegExp(r'(\d+(?:\.\d+)?)\s*(g|grams?)\b').firstMatch(chunk);
  final food = matchFood(chunk);
  if (food == null) return null;

  var qty = 1.0;
  final leading = RegExp(
    r'^(a|an|one|two|three|four|five|six|seven|eight|nine|ten|half|\d+(?:\.\d+)?)',
  ).firstMatch(chunk.trim());
  if (leading != null) {
    final token = leading.group(1)!;
    qty = _numberWords[token] ?? double.tryParse(token) ?? 1;
  }

  if (grams != null && food.per100g) {
    qty = (double.tryParse(grams.group(1)!) ?? 100) / 100;
  } else if (grams != null && !food.per100g) {
    // "100g chicken" when the catalog row is already per 100 g is handled above.
    // For piece foods, keep the count unless the only number is grams.
    if (leading == null) qty = (double.tryParse(grams.group(1)!) ?? 100) / 100;
  }

  if (qty <= 0) qty = 1;
  return ParsedFoodLine(
    food: food,
    quantity: qty,
    calories: food.kcal * qty,
    protein: food.protein * qty,
    carbs: food.carbs * qty,
    fat: food.fat * qty,
    fiber: food.fiber * qty,
  );
}
