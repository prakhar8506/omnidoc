class MacroTargets {
  const MacroTargets({
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.bmi,
    required this.bmiLabel,
    required this.waterMl,
    required this.goalLabel,
    required this.note,
  });

  final int bmr;
  final int tdee;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final double bmi;
  final String bmiLabel;
  final int waterMl;
  final String goalLabel;
  final String note;
}

class NutritionInputs {
  const NutritionInputs({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.sex,
    required this.goal,
    required this.activity,
  });

  final double? heightCm;
  final double? weightKg;
  final int age;
  final String? sex;
  final String goal;
  final String activity;
}

MacroTargets computeTargets(NutritionInputs input) {
  final height = (input.heightCm ?? 170).clamp(120, 230);
  final weight = (input.weightKg ?? 70).clamp(35, 250);
  final age = input.age.clamp(13, 100);
  final sex = (input.sex ?? '').toLowerCase();
  final female = sex.contains('female') || sex.contains('woman');
  final bmr = (10 * weight) + (6.25 * height) - (5 * age) + (female ? -161 : 5);
  const multipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'very': 1.725,
  };
  final tdee = bmr * (multipliers[input.activity] ?? 1.55);
  final factor = switch (input.goal) {
    'deficit' => 0.80,
    'surplus' => 1.15,
    'recomp' => 0.92,
    _ => 1.0,
  };
  final calories = (tdee * factor).round();
  final proteinPerKg = switch (input.goal) {
    'deficit' => 1.8,
    'surplus' => 1.8,
    'recomp' => 2.0,
    _ => 1.4,
  };
  final protein = (weight * proteinPerKg).round();
  final fatCalories = calories * 0.27;
  final fat = (fatCalories / 9).round();
  final carbCalories = calories - (protein * 4) - (fat * 9);
  final carbs = (carbCalories / 4).round().clamp(40, 800);
  final meters = height / 100;
  final bmi = weight / (meters * meters);
  final bmiLabel = bmi < 18.5
      ? 'Underweight'
      : bmi < 25
          ? 'Healthy range'
          : bmi < 30
              ? 'Overweight'
              : 'Obese range';
  final goalLabel = switch (input.goal) {
    'deficit' => 'Calorie deficit',
    'surplus' => 'Calorie surplus',
    'recomp' => 'Body recomposition',
    _ => 'Maintain',
  };
  final note = switch (input.goal) {
    'deficit' => 'About 20% under maintenance, with higher protein so muscle is easier to keep.',
    'surplus' => 'About 15% over maintenance to support training. Expect slow weight gain.',
    'recomp' => 'Slightly under maintenance with high protein. Useful when you want fat down and strength up together.',
    _ => 'Eat near maintenance and adjust if your weekly weight trend drifts.',
  };
  return MacroTargets(
    bmr: bmr.round(),
    tdee: tdee.round(),
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    fiber: 30,
    bmi: double.parse(bmi.toStringAsFixed(1)),
    bmiLabel: bmiLabel,
    waterMl: (weight * 33).round(),
    goalLabel: goalLabel,
    note: note,
  );
}

/// Short diet focus lines from logged conditions and lab names already on the phone.
List<String> dietFocus({
  required List<String> conditions,
  required List<String> allergies,
  required List<Map<String, dynamic>> labTests,
}) {
  final blob = [
    ...conditions,
    ...labTests.map((t) => '${t['name'] ?? ''} ${t['flag'] ?? ''} ${t['severity'] ?? ''}'),
  ].join(' ').toLowerCase();
  final lines = <String>[];
  if (blob.contains('diabet') || blob.contains('hba1c') || blob.contains('glucose')) {
    lines.add('Prefer dal, oats, millets, and vegetables. Keep sweets, sugary drinks, and large portions of white rice smaller.');
  }
  if (blob.contains('cholesterol') || blob.contains('ldl') || blob.contains('triglycer')) {
    lines.add('Use oats, beans, fruit, and nuts. Keep ghee, fried snacks, and fatty red meat smaller.');
  }
  if (blob.contains('anemia') || blob.contains('hemoglobin') || blob.contains('haemoglobin') || blob.contains('ferritin')) {
    lines.add('Add dal, leafy greens, and a vitamin C food (orange or lemon) with those meals. Leave tea and coffee for an hour away from them.');
  }
  if (blob.contains('pressure') || blob.contains('hypertension') || blob.contains('bp')) {
    lines.add('Cook with less salt. Skip pickles and packaged namkeen most days.');
  }
  if (blob.contains('thyroid') || blob.contains('tsh')) {
    lines.add('Keep iodine from iodized salt, and include eggs, dairy, or dal for selenium and zinc if those foods are safe for you.');
  }
  if (blob.contains('pcos')) {
    lines.add('Build meals around protein, vegetables, and slower carbs such as oats, dal, and quinoa.');
  }
  if (allergies.isNotEmpty) {
    lines.add('Left out foods that match your allergies: ${allergies.join(', ')}.');
  }
  if (lines.isEmpty) {
    lines.add('No condition-specific limits were found. The plan follows your goal, weight, and allergies.');
  }
  return lines;
}
