import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/mental/mood_check.dart';

MoodAnswer _a(int choice, int millis) => MoodAnswer(choice: choice, millis: millis);

void main() {
  test('steady answers stay below a doctor visit', () {
    final result = scoreMoodCheck(List.generate(8, (_) => _a(0, 4000)));
    expect(result.answerScore, 0);
    expect(result.seeDoctor, isFalse);
    expect(result.quality, 'Steady');
    expect(result.pace, 'Steady');
  });

  test('slow answers on low-mood items raise the check score', () {
    final result = scoreMoodCheck(List.generate(8, (i) => _a(i == 7 ? 0 : 2, 30000)));
    expect(result.answerScore, 14);
    expect(result.checkScore, greaterThan(result.answerScore));
    expect(result.pace, 'Slow');
    expect(result.seeDoctor, isTrue);
  });

  test('rushed answers lower trust and a safety answer asks for a doctor', () {
    final rushed = scoreMoodCheck(List.generate(8, (_) => _a(2, 500)));
    expect(rushed.pace, 'Rushed');
    expect(rushed.checkScore, lessThan(rushed.answerScore));

    final safety = scoreMoodCheck([
      ...List.generate(7, (_) => _a(0, 4000)),
      _a(2, 8000),
    ]);
    expect(safety.urgent, isTrue);
    expect(safety.seeDoctor, isTrue);
  });
}
