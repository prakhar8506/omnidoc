class VisitBlock {
  const VisitBlock(this.title, this.lines);

  final String title;
  final List<String> lines;
}

const visitDisclaimer =
    'This note is what the person typed into Cura. It is not a diagnosis, a prescription, or a recommendation to start or stop a medicine.';

/// Doctor-facing blocks. Blank measurements are left out.
List<VisitBlock> buildVisitBlocks({
  required String patientName,
  required List<String> allergies,
  required List<String> conditions,
  required List<Map<String, dynamic>> profileMedicines,
  required List<Map<String, dynamic>> doseLogs,
  required List<Map<String, dynamic>> sickPeriods,
  required List<Map<String, dynamic>> sickDays,
}) {
  final blocks = <VisitBlock>[
    VisitBlock('Patient', [patientName.isEmpty ? 'Name not saved' : patientName]),
    VisitBlock(
      'Allergies on the profile',
      allergies.isEmpty ? const ['None saved'] : allergies,
    ),
    VisitBlock(
      'Conditions on the profile',
      conditions.isEmpty ? const ['None saved'] : conditions,
    ),
    VisitBlock(
      'Medicines saved on the profile',
      profileMedicines.isEmpty
          ? const ['None saved. This list is separate from doses logged on a particular day.']
          : [
              for (final med in profileMedicines)
                [
                  med['name'],
                  if ((med['dosage'] ?? '').toString().trim().isNotEmpty) med['dosage'],
                  if ((med['scheduleTime'] ?? '').toString().trim().isNotEmpty) med['scheduleTime'],
                ].join(' · '),
            ],
    ),
    VisitBlock('Everyday doses', _doseLines(doseLogs)),
  ];

  if (sickPeriods.isEmpty) {
    blocks.add(const VisitBlock('Sick weeks', ['No sick week has been saved.']));
    return blocks;
  }

  final ordered = [...sickPeriods]..sort((a, b) {
      final aStart = DateTime.tryParse(a['startedAt']?.toString() ?? '') ?? DateTime(1970);
      final bStart = DateTime.tryParse(b['startedAt']?.toString() ?? '') ?? DateTime(1970);
      return bStart.compareTo(aStart);
    });

  for (final period in ordered) {
    final id = period['id']?.toString() ?? '';
    final label = (period['label']?.toString().trim().isNotEmpty ?? false)
        ? period['label'].toString().trim()
        : 'Sick week';
    final start = DateTime.tryParse(period['startedAt']?.toString() ?? '');
    final end = DateTime.tryParse(period['endedAt']?.toString() ?? '');
    final note = period['noteForDoctor']?.toString().trim() ?? '';
    final days = sickDays.where((day) => day['periodId'] == id).toList()
      ..sort((a, b) => (a['day']?.toString() ?? '').compareTo(b['day']?.toString() ?? ''));
    final lines = <String>[
      end == null
          ? 'Open since ${start == null ? 'an unsaved date' : _date(start)}.'
          : '${start == null ? 'Start not saved' : _date(start)} to ${_date(end)}.',
      if (note.isNotEmpty) 'Note for the doctor: $note',
      if (days.isEmpty) 'No day was filled in for this period.',
    ];
    for (final day in days) {
      lines.add(_dayLine(day));
      final items = (day['items'] as List?) ?? const [];
      if (items.isEmpty) {
        lines.add('  Nothing consumed was written for this day.');
      }
      for (final raw in items) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final kind = item['kind'] == 'medicine' ? 'Medicine' : 'Other intake';
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final amount = item['amount']?.toString().trim() ?? '';
        lines.add('  $kind: $name${amount.isEmpty ? '' : ' · $amount'}');
      }
      final question = day['question']?.toString().trim() ?? '';
      if (question.isNotEmpty) lines.add('  Question for the visit: $question');
    }
    blocks.add(VisitBlock('Sick week · $label', lines));
  }
  return blocks;
}

List<String> _doseLines(List<Map<String, dynamic>> doseLogs) {
  if (doseLogs.isEmpty) {
    return const ['No everyday dose has been logged. Sick-week medicines are listed with that sick week.'];
  }
  final ordered = [...doseLogs]..sort((a, b) {
      final aAt = DateTime.tryParse(a['takenAt']?.toString() ?? '') ?? DateTime(1970);
      final bAt = DateTime.tryParse(b['takenAt']?.toString() ?? '') ?? DateTime(1970);
      return bAt.compareTo(aAt);
    });
  return [
    for (final dose in ordered)
      [
        _when(DateTime.tryParse(dose['takenAt']?.toString() ?? '')),
        dose['name']?.toString().trim() ?? '',
        if ((dose['amount'] ?? '').toString().trim().isNotEmpty) dose['amount'],
        if ((dose['note'] ?? '').toString().trim().isNotEmpty) dose['note'],
      ].where((part) => part.toString().trim().isNotEmpty).join(' · '),
  ];
}

String _dayLine(Map<String, dynamic> day) {
  final feeling = day['feeling']?.toString().trim() ?? '';
  final temperature = day['temperatureC'];
  final parsedDay = DateTime.tryParse(day['day']?.toString() ?? '');
  final parts = <String>[parsedDay == null ? 'Date not saved' : _date(parsedDay)];
  if (feeling.isNotEmpty) parts.add(feeling);
  if (temperature is num) parts.add('${temperature.toString()} °C, as entered');
  return parts.join(' · ');
}

String _when(DateTime? time) {
  if (time == null) return 'Time not saved';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '${_date(time)} $hour:$minute';
}

String _date(DateTime time) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${time.day} ${months[time.month - 1]} ${time.year}';
}

/// Accepts a measured temperature the person typed. Anything else is rejected.
double? parseTemperature(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value < 34 || value > 43) return null;
  return double.parse(value.toStringAsFixed(1));
}
