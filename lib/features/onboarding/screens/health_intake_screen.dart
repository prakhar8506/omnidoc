import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Questions asked once after sign-in, before the rest of the app.
class HealthIntakeScreen extends StatefulWidget {
  final AppState appState;

  const HealthIntakeScreen({super.key, required this.appState});

  @override
  State<HealthIntakeScreen> createState() => _HealthIntakeScreenState();
}

class _HealthIntakeScreenState extends State<HealthIntakeScreen> {
  int _step = 0;
  String? _glp1 = '';
  final Set<String> _meds = {};
  String? _meals = '';

  static const _glp1Options = [
    'Yes',
    'I have a prescription but haven’t started taking it yet',
    'I’m in the process of getting a prescription',
    'No',
    'I prefer not to say',
  ];

  static const _medOptions = [
    'Blood pressure medicine',
    'Thyroid medicine',
    'Insulin or another diabetes medicine',
    'Steroids',
    'A blood thinner',
    'None of these',
    'I prefer not to say',
  ];

  static const _mealOptions = [
    'Yes, definitely',
    'Open to trying',
    'No thanks',
  ];

  bool get _canContinue {
    if (_step == 0) return (_glp1 ?? '').isNotEmpty;
    if (_step == 1) return _meds.isNotEmpty;
    return (_meals ?? '').isNotEmpty;
  }

  void _toggleMed(String option) {
    setState(() {
      if (option == 'None of these' || option == 'I prefer not to say') {
        _meds
          ..clear()
          ..add(option);
        return;
      }
      _meds.remove('None of these');
      _meds.remove('I prefer not to say');
      if (!_meds.add(option)) _meds.remove(option);
    });
  }

  void _next() {
    if (!_canContinue) return;
    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }
    widget.appState.saveHealthIntake(
      glp1: _glp1!,
      medicines: _meds.toList(),
      mealPlans: _meals!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF12141C) : const Color(0xFFF7F5FA);
    final card = dark ? const Color(0xFF1C1E2A) : Colors.white;
    final ink = dark ? const Color(0xFFF4F2FA) : AppColors.textPrimary;
    final muted = dark ? const Color(0xFFB7B4C8) : AppColors.textSecondary;

    final title = switch (_step) {
      0 => 'Are you taking GLP-1 medications like Ozempic, Mounjaro, Wegovy, Zepbound, etc?',
      1 => 'Are you taking any of these medicines?',
      _ => 'Do you want us to help you build weekly meal plans?',
    };
    final subtitle = switch (_step) {
      0 => 'We’re here to support you. This stays on your account and is not a prescription check.',
      1 => 'Choose every group that applies. Cura uses this as context, not as medical advice.',
      _ => 'Your custom plan will be tailored to your lifestyle and goals.',
    };

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Goals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == 2 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: i <= _step ? const Color(0xFF3B82F6) : ink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: ink),
              ),
              const SizedBox(height: 10),
              Text(subtitle, style: TextStyle(fontSize: 14, height: 1.4, color: muted)),
              const SizedBox(height: 22),
              Expanded(
                child: ListView(
                  children: [
                    if (_step == 0)
                      for (final option in _glp1Options)
                        _optionCard(
                          label: option,
                          selected: _glp1 == option,
                          card: card,
                          ink: ink,
                          onTap: () => setState(() => _glp1 = option),
                        ),
                    if (_step == 1)
                      for (final option in _medOptions)
                        _optionCard(
                          label: option,
                          selected: _meds.contains(option),
                          card: card,
                          ink: ink,
                          onTap: () => _toggleMed(option),
                        ),
                    if (_step == 2)
                      for (final option in _mealOptions)
                        _optionCard(
                          label: option,
                          selected: _meals == option,
                          card: card,
                          ink: ink,
                          onTap: () => setState(() => _meals = option),
                        ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_step > 0)
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: card,
                        foregroundColor: ink,
                      ),
                      onPressed: () => setState(() => _step -= 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: _canContinue ? _next : null,
                      child: Text(_step == 2 ? 'Finish' : 'Next', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required String label,
    required bool selected,
    required Color card,
    required Color ink,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink)),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? const Color(0xFF3B82F6) : ink.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
