import 'dart:io';

import 'package:flutter/material.dart';
import '../../../core/charts/charts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/care/visit_record.dart';
import '../../../core/services/visit_summary_pdf.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

class SickWeekScreen extends StatelessWidget {
  const SickWeekScreen({super.key, required this.appState});

  final AppState appState;

  List<int> _logCounts() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 34));
    final counts = List<int>.filled(35, 0);
    void bump(String? raw) {
      final at = DateTime.tryParse(raw ?? '');
      if (at == null) return;
      final day = DateTime(at.year, at.month, at.day);
      final index = day.difference(start).inDays;
      if (index >= 0 && index < 35) counts[index]++;
    }

    for (final dose in appState.doseLogs) {
      bump(dose['takenAt']?.toString());
    }
    for (final day in appState.sickDays) {
      bump(day['day']?.toString());
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final ink = Theme.of(context).colorScheme.onSurface;
        final muted = ink.withValues(alpha: 0.7);
        final open = appState.openSickPeriod;
        final past = appState.sickPeriods.where((period) => period['id'] != open?['id']).toList();

        final dark = Theme.of(context).brightness == Brightness.dark;
        final card = Theme.of(context).colorScheme.surface;
        return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 156),
            children: [
              Row(
                children: [
                  _iconBadge(Icons.sick_outlined, const Color(0xFF0F766E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Mark a sick week', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You do not need to know in advance. Mark the days after you have been unwell, then write what you took.',
                style: TextStyle(color: muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Text('Days with a log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 8),
              ConsistencyHeatmap(counts: _logCounts()),
              const SizedBox(height: 14),
              if (open == null)
                _actionTile(
                  context,
                  icon: Icons.event_available_rounded,
                  tint: const Color(0xFF0F766E),
                  title: 'Mark a sick week',
                  subtitle: 'Name it in your own words, such as a cold.',
                  onTap: () => _startPeriod(context),
                )
              else
                _periodCard(context, open, ink, muted, current: true),
              for (final period in past) ...[
                const SizedBox(height: 10),
                _periodCard(context, period, ink, muted, current: false),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  _iconBadge(Icons.medication_rounded, const Color(0xFF6E5DF6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Everyday doses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'A dose on an ordinary day stays separate from a sick week. Both are written into the visit PDF.',
                style: TextStyle(color: muted, height: 1.4),
              ),
              const SizedBox(height: 10),
              _actionTile(
                context,
                icon: Icons.add_rounded,
                tint: const Color(0xFF6E5DF6),
                title: 'Log a dose',
                subtitle: 'It appears here, and in the PDF you share.',
                onTap: () => showDoseLogSheet(context, appState),
              ),
              const SizedBox(height: 10),
              if (appState.doseLogs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF2A2C3A) : card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('No dose logged yet.', style: TextStyle(color: muted)),
                )
              else
                for (final dose in appState.doseLogs.take(12))
                  _doseCard(context, dose, ink, muted),
              const SizedBox(height: 16),
              _actionTile(
                context,
                icon: Icons.picture_as_pdf_rounded,
                tint: const Color(0xFFB45309),
                title: 'Share visit summary',
                subtitle: 'A PDF with the sick week and every dose saved on this phone.',
                onTap: () => _share(context),
              ),
            ],
        );
      },
    );
  }

  Widget _periodCard(
    BuildContext context,
    Map<String, dynamic> period,
    Color ink,
    Color muted, {
    required bool current,
  }) {
    final id = period['id']?.toString() ?? '';
    final days = appState.sickDays.where((day) => day['periodId'] == id).toList()
      ..sort((a, b) => (b['day']?.toString() ?? '').compareTo(a['day']?.toString() ?? ''));
    final label = (period['label']?.toString().trim().isNotEmpty ?? false) ? period['label'].toString() : 'Sick week';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(current ? '$label · open' : label, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text(
            current
                ? 'Started ${_stamp(period['startedAt']?.toString())}. Add each day you want the doctor to see.'
                : 'Closed ${_stamp(period['endedAt']?.toString())}.',
            style: TextStyle(color: muted, height: 1.35),
          ),
          if ((period['noteForDoctor'] ?? '').toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(period['noteForDoctor'].toString(), style: TextStyle(color: ink, height: 1.35)),
            ),
          const SizedBox(height: 8),
          if (days.isEmpty)
            Text('No day written yet.', style: TextStyle(color: muted))
          else
            for (final day in days) _dayTile(context, day, ink, muted),
          if (current) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => _editDay(context, periodId: id),
                  child: const Text('Add today'),
                ),
                OutlinedButton(
                  onPressed: () => _editDay(context, periodId: id, pickDate: true),
                  child: const Text('Add another day'),
                ),
                OutlinedButton(
                  onPressed: () => _note(context, id, period['noteForDoctor']?.toString() ?? ''),
                  child: const Text('Note for the doctor'),
                ),
                TextButton(
                  onPressed: () => appState.endSickPeriod(id),
                  child: const Text('Close this sick week'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayTile(BuildContext context, Map<String, dynamic> day, Color ink, Color muted) {
    final items = (day['items'] as List?) ?? const [];
    final names = items.whereType<Map>().map((item) => item['name']?.toString() ?? '').where((name) => name.isNotEmpty);
    final temperature = day['temperatureC'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day['day']?.toString() ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          if ((day['feeling'] ?? '').toString().trim().isNotEmpty)
            Text(day['feeling'].toString(), style: TextStyle(color: ink, height: 1.3)),
          if (temperature is num) Text('$temperature °C, as entered', style: TextStyle(color: muted)),
          Text(
            names.isEmpty ? 'Nothing consumed written for this day.' : names.join(', '),
            style: TextStyle(color: muted, height: 1.3),
          ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color tint) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: tint, size: 22),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF1C1E2A) : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _iconBadge(icon, tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: ink.withValues(alpha: 0.7), height: 1.3, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doseCard(BuildContext context, Map<String, dynamic> dose, Color ink, Color muted) {
    final amount = (dose['amount'] ?? '').toString().trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2C3A) : const Color(0xFFF4F1FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _iconBadge(Icons.medication_liquid_rounded, const Color(0xFF6E5DF6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dose['name']?.toString() ?? 'Medicine', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
                Text(
                  [if (amount.isNotEmpty) amount, _stamp(dose['takenAt']?.toString())].join(' · '),
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => appState.deleteDose(dose['id']?.toString() ?? ''),
            icon: Icon(Icons.close_rounded, color: muted, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _startPeriod(BuildContext context) async {
    final label = await _askText(context, title: 'Mark a sick week', hint: 'For example, cold or stomach upset');
    if (label == null || !context.mounted) return;
    final error = appState.startSickPeriod(label);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _note(BuildContext context, String id, String current) async {
    final note = await _askText(context, title: 'Note for the doctor', hint: 'Anything you want them to read first', initial: current);
    if (note == null) return;
    appState.setSickPeriodNote(id, note);
  }

  Future<void> _editDay(BuildContext context, {required String periodId, bool pickDate = false}) async {
    var day = DateTime.now();
    if (pickDate) {
      final picked = await showDatePicker(
        context: context,
        initialDate: day,
        firstDate: DateTime.now().subtract(const Duration(days: 60)),
        lastDate: DateTime.now(),
      );
      if (picked == null || !context.mounted) return;
      day = picked;
    }
    final existing = appState.sickDays.cast<Map<String, dynamic>?>().firstWhere(
          (entry) => entry?['periodId'] == periodId && entry?['day'] == _dayKey(day),
          orElse: () => null,
        );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => _DaySheet(
        appState: appState,
        periodId: periodId,
        day: day,
        existing: existing,
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      final bytes = await buildVisitSummaryPdf(
        patientName: appState.userName,
        allergies: appState.allergies,
        conditions: appState.chronicConditions,
        profileMedicines: [
          for (final med in appState.medications)
            {'name': med.name, 'dosage': med.dosage, 'scheduleTime': med.scheduleTime},
        ],
        doseLogs: appState.doseLogs,
        sickPeriods: appState.sickPeriods,
        sickDays: appState.sickDays,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cura-visit-summary.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: 'Cura visit summary.pdf')],
          subject: 'Cura visit summary',
          text: visitDisclaimer,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The visit summary could not be shared. Try again.')),
        );
      }
    }
  }
}

void showDoseLogSheet(BuildContext context, AppState appState) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (ctx) => _DoseSheet(appState: appState),
  );
}

class _DoseSheet extends StatefulWidget {
  const _DoseSheet({required this.appState});

  final AppState appState;

  @override
  State<_DoseSheet> createState() => _DoseSheetState();
}

class _DoseSheetState extends State<_DoseSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Everyday dose', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Medicine name')),
          TextField(controller: _amount, decoration: const InputDecoration(labelText: 'Amount you took')),
          TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note, if you want one')),
          TextButton(
            onPressed: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
              if (time == null) return;
              setState(() {
                _when = DateTime(_when.year, _when.month, _when.day, time.hour, time.minute);
              });
            },
            child: Text('Time ${_when.hour.toString().padLeft(2, '0')}:${_when.minute.toString().padLeft(2, '0')}'),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final error = widget.appState.logDose(
                name: _name.text,
                amount: _amount.text,
                note: _note.text,
                takenAt: _when,
              );
              if (error != null) {
                setState(() => _error = error);
                return;
              }
              final savedName = _name.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(content: Text('$savedName is saved on this phone.')),
              );
            },
            child: const Text('Save dose'),
          ),
        ],
      ),
    );
  }
}

class _DaySheet extends StatefulWidget {
  const _DaySheet({
    required this.appState,
    required this.periodId,
    required this.day,
    required this.existing,
  });

  final AppState appState;
  final String periodId;
  final DateTime day;
  final Map<String, dynamic>? existing;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late final TextEditingController _feeling;
  late final TextEditingController _temperature;
  late final TextEditingController _question;
  late final List<_IntakeRow> _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _feeling = TextEditingController(text: existing?['feeling']?.toString() ?? '');
    _temperature = TextEditingController(
      text: existing?['temperatureC'] is num ? existing!['temperatureC'].toString() : '',
    );
    _question = TextEditingController(text: existing?['question']?.toString() ?? '');
    final items = (existing?['items'] as List?) ?? const [];
    _rows = [
      for (final raw in items.whereType<Map>())
        _IntakeRow(
          kind: raw['kind']?.toString() == 'other' ? 'other' : 'medicine',
          name: TextEditingController(text: raw['name']?.toString() ?? ''),
          amount: TextEditingController(text: raw['amount']?.toString() ?? ''),
        ),
    ];
    if (_rows.isEmpty) _rows.add(_IntakeRow.blank());
  }

  @override
  void dispose() {
    _feeling.dispose();
    _temperature.dispose();
    _question.dispose();
    for (final row in _rows) {
      row.name.dispose();
      row.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What you consumed on ${_dayKey(widget.day)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 8),
            TextField(controller: _feeling, decoration: const InputDecoration(labelText: 'How the day felt, in your words')),
            TextField(
              controller: _temperature,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Temperature °C, only if you measured it'),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _rows.length; i++) _rowEditor(ink, i),
            TextButton(
              onPressed: () => setState(() => _rows.add(_IntakeRow.blank())),
              child: const Text('Add another thing you consumed'),
            ),
            TextField(controller: _question, decoration: const InputDecoration(labelText: 'Question for the doctor')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('Save this day'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowEditor(Color ink, int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Medicine'),
                selected: row.kind == 'medicine',
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(color: row.kind == 'medicine' ? Colors.white : ink),
                onSelected: (_) => setState(() => row.kind = 'medicine'),
              ),
              ChoiceChip(
                label: const Text('Food or drink'),
                selected: row.kind == 'other',
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(color: row.kind == 'other' ? Colors.white : ink),
                onSelected: (_) => setState(() => row.kind = 'other'),
              ),
            ],
          ),
          TextField(controller: row.name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: row.amount, decoration: const InputDecoration(labelText: 'Amount')),
        ],
      ),
    );
  }

  void _save() {
    if (_temperature.text.trim().isNotEmpty && parseTemperature(_temperature.text) == null) {
      setState(() => _error = 'Leave temperature blank, or enter a reading between 34 and 43 °C.');
      return;
    }
    final items = [
      for (final row in _rows)
        if (row.name.text.trim().isNotEmpty)
          {'kind': row.kind, 'name': row.name.text.trim(), 'amount': row.amount.text.trim()},
    ];
    widget.appState.saveSickDay(
      periodId: widget.periodId,
      day: widget.day,
      feeling: _feeling.text,
      temperatureC: parseTemperature(_temperature.text),
      question: _question.text,
      items: items,
    );
    Navigator.pop(context);
  }
}

class _IntakeRow {
  _IntakeRow({required this.kind, required this.name, required this.amount});

  factory _IntakeRow.blank() => _IntakeRow(kind: 'medicine', name: TextEditingController(), amount: TextEditingController());

  String kind;
  final TextEditingController name;
  final TextEditingController amount;
}

Future<String?> _askText(BuildContext context, {required String title, required String hint, String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _LabelDialog(title: title, hint: hint, initial: initial),
  );
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.title, required this.hint, required this.initial});

  final String title;
  final String hint;
  final String initial;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(widget.title, style: TextStyle(color: ink)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: ink),
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

String _dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

String _stamp(String? iso) {
  final time = DateTime.tryParse(iso ?? '');
  if (time == null) return 'date not saved';
  return '${time.day} ${time.month} ${time.year}';
}
