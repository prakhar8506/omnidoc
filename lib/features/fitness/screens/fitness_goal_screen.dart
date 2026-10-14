import 'package:flutter/material.dart';

import '../../../core/fitness/fitness_goal.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

class FitnessGoalScreen extends StatefulWidget {
  const FitnessGoalScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  late String _aim;
  late String _event;
  late int _hours;
  late String _activity;
  late String _sex;
  DateTime? _raceDate;
  DateTime? _dob;
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = widget.appState;
    _aim = state.fitnessAim;
    _event = state.fitnessEvent;
    _hours = state.weeklyTrainingHours;
    _activity = state.activityLevel;
    _sex = state.biologicalSex ?? '';
    _raceDate = DateTime.tryParse(state.raceDateIso ?? '');
    _dob = DateTime.tryParse(state.dateOfBirth ?? '');
    if (state.userHeightCm != null) _height.text = state.userHeightCm!.toStringAsFixed(0);
    if (state.userWeightKg != null) _weight.text = state.userWeightKg!.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool race}) async {
    final initial = race ? (_raceDate ?? DateTime.now().add(const Duration(days: 90))) : (_dob ?? DateTime(1995, 1, 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: race ? DateTime.now().subtract(const Duration(days: 1)) : DateTime(1920),
      lastDate: race ? DateTime.now().add(const Duration(days: 365 * 4)) : DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (race) {
        _raceDate = picked;
      } else {
        _dob = picked;
      }
    });
  }

  void _save() {
    if (_aim.isEmpty) {
      setState(() => _error = 'Choose a goal first.');
      return;
    }
    if (FitnessAim.raceAims.contains(_aim) && _aim != 'hyrox' && _event.isEmpty) {
      setState(() => _error = 'Choose the race distance.');
      return;
    }
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    if (_height.text.trim().isNotEmpty && (height == null || height < 120 || height > 230)) {
      setState(() => _error = 'Height needs to be between 120 and 230 cm, or left blank.');
      return;
    }
    if (_weight.text.trim().isNotEmpty && (weight == null || weight < 30 || weight > 300)) {
      setState(() => _error = 'Weight needs to be between 30 and 300 kg, or left blank.');
      return;
    }
    widget.appState.saveBodyProfile(
      heightCm: height,
      weightKg: weight,
      sex: _sex.isEmpty ? null : _sex,
      dobIso: _dob?.toIso8601String(),
    );
    widget.appState.saveFitnessGoal(
      aim: _aim,
      event: FitnessAim.raceAims.contains(_aim) ? _event : '',
      raceDateIso: FitnessAim.raceAims.contains(_aim) ? _raceDate?.toIso8601String() : null,
      weeklyHours: _hours,
      activity: _activity,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = ink.withValues(alpha: 0.7);
    final events = FitnessAim.eventsFor(_aim);

    return Scaffold(
      appBar: AppBar(title: Text('Training goal', style: TextStyle(color: ink, fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('What are you training for?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text(
            'Weight goals and race goals use the meals, body size, medicines, and watch readings already saved. Missing numbers stay blank.',
            style: TextStyle(height: 1.35, color: muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final aim in FitnessAim.aims)
                ChoiceChip(
                  label: Text(aim.label),
                  selected: _aim == aim.id,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(color: _aim == aim.id ? Colors.white : ink),
                  onSelected: (_) => setState(() {
                    _aim = aim.id;
                    _event = '';
                    _error = null;
                  }),
                ),
            ],
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Which one?', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 8),
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _choice(
                  ink,
                  event.label,
                  _event == event.id,
                  () => setState(() => _event = event.id),
                ),
              ),
            TextButton(
              onPressed: () => _pickDate(race: true),
              child: Text(_raceDate == null
                  ? 'Add a race date, if you have one'
                  : 'Race date ${_raceDate!.year}-${_raceDate!.month.toString().padLeft(2, '0')}-${_raceDate!.day.toString().padLeft(2, '0')}'),
            ),
          ],
          const SizedBox(height: 12),
          Text('Hours you can train in a week', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final hours in [3, 5, 8, 12])
                ChoiceChip(
                  label: Text('$hours h'),
                  selected: _hours == hours,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(color: _hours == hours ? Colors.white : ink),
                  onSelected: (_) => setState(() => _hours = hours),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('How active are most days?', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 4),
          Text('This changes the calorie estimate only after height, weight, sex, and date of birth are saved.', style: TextStyle(color: muted, height: 1.35)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [('sedentary', 'Mostly sitting'), ('light', 'Light'), ('moderate', 'Moderate'), ('very', 'Very active')])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: _activity == item.$1,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(color: _activity == item.$1 ? Colors.white : ink),
                  onSelected: (_) => setState(() => _activity = item.$1),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Body details used for BMI and calories', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)', hintText: 'Leave blank if you do not want to add it'),
          ),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: 'Leave blank if you do not want to add it'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final sex in ['Female', 'Male'])
                ChoiceChip(
                  label: Text(sex),
                  selected: _sex == sex,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(color: _sex == sex ? Colors.white : ink),
                  onSelected: (_) => setState(() => _sex = sex),
                ),
            ],
          ),
          TextButton(
            onPressed: () => _pickDate(race: false),
            child: Text(_dob == null
                ? 'Add date of birth'
                : 'Date of birth ${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Save goal')),
        ],
      ),
    );
  }

  Widget _choice(Color ink, String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.primaryContainer : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : ink, height: 1.3)),
        ),
      ),
    );
  }
}
