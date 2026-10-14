/// Training aims the person picks. Race distances are public course facts.
class FitnessAim {
  const FitnessAim(this.id, this.label);

  final String id;
  final String label;

  static const aims = [
    FitnessAim('lose', 'Lose weight'),
    FitnessAim('gain', 'Gain weight'),
    FitnessAim('maintain', 'Maintain'),
    FitnessAim('recomp', 'Recomposition'),
    FitnessAim('ironman', 'Ironman'),
    FitnessAim('hyrox', 'HYROX'),
    FitnessAim('running', 'Running'),
  ];

  static const raceAims = {'ironman', 'hyrox', 'running'};

  static String labelFor(String id) {
    for (final aim in aims) {
      if (aim.id == id) return aim.label;
    }
    return '';
  }

  static String dietGoalFor(String aim) {
    return switch (aim) {
      'lose' => 'deficit',
      'gain' => 'surplus',
      'recomp' => 'recomp',
      _ => 'maintain',
    };
  }

  static List<FitnessAim> eventsFor(String aim) {
    return switch (aim) {
      'ironman' => const [
          FitnessAim('70.3', '70.3 · 1.9 km swim, 90 km bike, 21.1 km run'),
          FitnessAim('full', 'Full · 3.8 km swim, 180 km bike, 42.2 km run'),
        ],
      'hyrox' => const [
          FitnessAim('open', 'Open division'),
          FitnessAim('pro', 'Pro division'),
        ],
      'running' => const [
          FitnessAim('5k', '5 km'),
          FitnessAim('10k', '10 km'),
          FitnessAim('half', 'Half marathon · 21.1 km'),
          FitnessAim('marathon', 'Marathon · 42.2 km'),
        ],
      _ => const [],
    };
  }

  static String eventLabel(String aim, String event) {
    for (final item in eventsFor(aim)) {
      if (item.id == event) return item.label;
    }
    return '';
  }
}

class BmiReading {
  const BmiReading({required this.value, required this.label, required this.note});

  final double value;
  final String label;
  final String note;
}

/// Adult BMI from measured height and weight. No stand-in body size is used.
BmiReading? bmiReading({
  required double? heightCm,
  required double? weightKg,
  String? dobIso,
  DateTime? now,
}) {
  if (heightCm == null || weightKg == null || heightCm < 120 || heightCm > 230 || weightKg < 30 || weightKg > 300) {
    return null;
  }
  final clock = now ?? DateTime.now();
  final dob = DateTime.tryParse(dobIso ?? '');
  if (dob != null) {
    var age = clock.year - dob.year;
    if (clock.month < dob.month || (clock.month == dob.month && clock.day < dob.day)) age--;
    if (age < 18) return null;
  }
  final meters = heightCm / 100;
  final bmi = weightKg / (meters * meters);
  final label = bmi < 18.5
      ? 'Underweight'
      : bmi < 25
          ? 'Healthy range'
          : bmi < 30
              ? 'Overweight'
              : 'Obese range';
  final note = dob == null
      ? 'Adult BMI categories. Add a date of birth so this is not applied without an age on file. This is a screening number, not a diagnosis.'
      : 'Adult BMI categories from your height, weight, and date of birth. This is a screening number, not a diagnosis.';
  return BmiReading(value: double.parse(bmi.toStringAsFixed(1)), label: label, note: note);
}

class DayFood {
  const DayFood({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int meals;
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

DayFood foodOnDay(List<Map<String, dynamic>> meals, DateTime day) {
  var calories = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
  var count = 0;
  for (final meal in meals) {
    final logged = DateTime.tryParse(meal['loggedAt']?.toString() ?? '');
    if (logged == null || !_sameDay(logged, day)) continue;
    count++;
    calories += (meal['calories'] as num?)?.toDouble() ?? 0;
    protein += (meal['protein'] as num?)?.toDouble() ?? 0;
    carbs += (meal['carbs'] as num?)?.toDouble() ?? 0;
    fat += (meal['fat'] as num?)?.toDouble() ?? 0;
  }
  return DayFood(
    calories: calories.round(),
    protein: protein.round(),
    carbs: carbs.round(),
    fat: fat.round(),
    meals: count,
  );
}

class LoggedAverage {
  const LoggedAverage({required this.calories, required this.days});

  final int calories;
  final int days;
}

/// Average of days that actually have a meal, inside the last 7 days.
LoggedAverage? averageLoggedCalories(List<Map<String, dynamic>> meals, DateTime now) {
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final byDay = <String, double>{};
  for (final meal in meals) {
    final logged = DateTime.tryParse(meal['loggedAt']?.toString() ?? '');
    if (logged == null) continue;
    final day = DateTime(logged.year, logged.month, logged.day);
    if (day.isBefore(start)) continue;
    final key = '${day.year}-${day.month}-${day.day}';
    byDay[key] = (byDay[key] ?? 0) + ((meal['calories'] as num?)?.toDouble() ?? 0);
  }
  if (byDay.isEmpty) return null;
  final total = byDay.values.fold<double>(0, (sum, value) => sum + value);
  return LoggedAverage(calories: (total / byDay.length).round(), days: byDay.length);
}

/// Change between the two newest weigh-ins when they fall on different days.
String? weightChangeLine(List<Map<String, dynamic>> logs) {
  if (logs.length < 2) return null;
  final latestKg = (logs[0]['kg'] as num?)?.toDouble();
  final olderKg = (logs[1]['kg'] as num?)?.toDouble();
  final latestAt = DateTime.tryParse(logs[0]['at']?.toString() ?? '');
  final olderAt = DateTime.tryParse(logs[1]['at']?.toString() ?? '');
  if (latestKg == null || olderKg == null || latestAt == null || olderAt == null) return null;
  if (_sameDay(latestAt, olderAt)) {
    return 'Two weigh-ins are on the same day. A trend needs different days.';
  }
  final delta = latestKg - olderKg;
  final days = DateTime(latestAt.year, latestAt.month, latestAt.day)
      .difference(DateTime(olderAt.year, olderAt.month, olderAt.day))
      .inDays
      .abs();
  final sign = delta > 0 ? '+' : '';
  return '$sign${delta.toStringAsFixed(1)} kg across $days day${days == 1 ? '' : 's'}, from the weigh-ins you saved.';
}
