import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/care/visit_record.dart';

void main() {
  test('A sick week and an everyday dose stay in different sections of the same note', () {
    final blocks = buildVisitBlocks(
      patientName: 'Asha',
      allergies: const ['Penicillin'],
      conditions: const [],
      profileMedicines: const [],
      doseLogs: const [
        {'name': 'Vitamin D', 'amount': '1 capsule', 'note': '', 'takenAt': '2026-10-10T08:00:00'},
      ],
      sickPeriods: const [
        {
          'id': 's1',
          'label': 'Cold',
          'startedAt': '2026-10-12T09:00:00',
          'endedAt': '',
          'noteForDoctor': 'Worse at night',
        },
      ],
      sickDays: const [
        {
          'periodId': 's1',
          'day': '2026-10-13',
          'feeling': 'Sore throat',
          'temperatureC': 38.2,
          'question': 'Do I need a swab?',
          'items': [
            {'kind': 'medicine', 'name': 'Paracetamol', 'amount': '500 mg'},
            {'kind': 'other', 'name': 'ORS', 'amount': '1 glass'},
          ],
        },
      ],
    );
    final everyday = blocks.firstWhere((block) => block.title == 'Everyday doses').lines.join('\n');
    final sick = blocks.firstWhere((block) => block.title.contains('Cold')).lines.join('\n');
    expect(everyday, contains('Vitamin D'));
    expect(everyday, isNot(contains('Paracetamol')));
    expect(sick, contains('Paracetamol'));
    expect(sick, contains('ORS'));
    expect(sick, contains('38.2'));
    expect(sick, contains('Worse at night'));
  });

  test('Temperature is omitted when none was entered', () {
    final blocks = buildVisitBlocks(
      patientName: 'Asha',
      allergies: const [],
      conditions: const [],
      profileMedicines: const [],
      doseLogs: const [],
      sickPeriods: const [
        {'id': 's1', 'label': 'Upset stomach', 'startedAt': '2026-10-01T00:00:00', 'endedAt': '2026-10-03T00:00:00'},
      ],
      sickDays: const [
        {
          'periodId': 's1',
          'day': '2026-10-02',
          'feeling': 'Nausea',
          'temperatureC': null,
          'items': [
            {'kind': 'medicine', 'name': 'Ondansetron', 'amount': ''},
          ],
        },
      ],
    );
    final text = blocks.map((block) => block.lines.join(' ')).join(' ');
    expect(text, contains('Ondansetron'));
    expect(text, isNot(contains('°C')));
  });

  test('A temperature outside a measured body range is rejected', () {
    expect(parseTemperature(''), isNull);
    expect(parseTemperature('0'), isNull);
    expect(parseTemperature('38.4'), 38.4);
  });
}
