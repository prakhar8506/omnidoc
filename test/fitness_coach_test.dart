import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/fitness/coach_program.dart';
import 'package:health_companion/core/fitness/fitness_goal.dart';

void main() {
  test('BMI stays empty without a measured height and weight', () {
    expect(bmiReading(heightCm: null, weightKg: 70), isNull);
    expect(bmiReading(heightCm: 170, weightKg: null), isNull);
  });

  test('BMI uses the measurements given and not a stand-in body', () {
    final reading = bmiReading(heightCm: 180, weightKg: 80, dobIso: '1990-01-01');
    expect(reading, isNotNull);
    expect(reading!.value, 24.7);
    expect(reading.label, 'Healthy range');
  });

  test('Adult BMI is hidden when the date of birth is under 18', () {
    final year = DateTime.now().year - 16;
    expect(bmiReading(heightCm: 170, weightKg: 60, dobIso: '$year-01-01'), isNull);
  });

  test('A weekly average ignores days with no meal', () {
    final now = DateTime(2026, 10, 14, 12);
    final average = averageLoggedCalories([
      {'loggedAt': '2026-10-14T08:00:00', 'calories': 500},
      {'loggedAt': '2026-10-12T08:00:00', 'calories': 700},
    ], now);
    expect(average!.days, 2);
    expect(average.calories, 600);
  });

  test('Ironman week names swim, bike, and run and does not invent a pace', () {
    final program = buildCoachProgram(
      aim: 'ironman',
      event: '70.3',
      raceDateIso: '2027-06-01',
      startedIso: '2026-10-01',
      weeklyHours: 8,
      readiness: null,
      gentle: false,
      bloodPressureMedicine: false,
      hasHeartRateZones: false,
      hasBodySize: false,
      hasSleep: false,
      now: DateTime(2026, 10, 14),
    );
    final text = program.sessions.map((s) => '${s.title} ${s.detail}').join(' ');
    expect(text, contains('Swim'));
    expect(text, contains('Bike'));
    expect(text, contains('Run'));
    expect(text.toLowerCase(), isNot(contains('pace of')));
    expect(program.guardrails.join(' '), contains('calorie goal stays off'));
  });

  test('A rest day does not prescribe hard HYROX work', () {
    final program = buildCoachProgram(
      aim: 'hyrox',
      event: 'open',
      raceDateIso: null,
      startedIso: null,
      weeklyHours: 5,
      readiness: 'Rest',
      gentle: true,
      bloodPressureMedicine: false,
      hasHeartRateZones: false,
      hasBodySize: true,
      hasSleep: true,
      now: DateTime(2026, 10, 14),
    );
    final text = program.sessions.map((s) => s.detail).join(' ').toLowerCase();
    expect(text, contains('easy'));
    expect(program.guardrails.join(' '), contains('easy day'));
  });
}
