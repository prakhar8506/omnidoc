import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/clinic_doctor.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FindCareScreen extends StatefulWidget {
  final AppState appState;
  final String? specialty;
  final CareDomain? domain;

  const FindCareScreen({
    super.key,
    required this.appState,
    this.specialty,
    this.domain,
  });

  @override
  State<FindCareScreen> createState() => _FindCareScreenState();
}

class _FindCareScreenState extends State<FindCareScreen> {
  late final TextEditingController _city;
  late String _specialty;

  static const _options = <String>[
    'general physician',
    'cardiologist',
    'dermatologist',
    'orthopedist',
    'psychiatrist',
    'gynecologist',
    'endocrinologist',
    'pulmonologist',
    'pediatrician',
    'dentist',
    'ophthalmologist',
  ];

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.appState.homeCity);
    _specialty = _fromDomain(widget.domain) ?? _clean(widget.specialty) ?? 'general physician';
    if (!_options.contains(_specialty)) _specialty = 'general physician';
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  String? _fromDomain(CareDomain? domain) {
    switch (domain) {
      case CareDomain.general:
        return 'general physician';
      case CareDomain.heart:
        return 'cardiologist';
      case CareDomain.liver:
        return 'general physician';
      case CareDomain.hormones:
        return 'endocrinologist';
      case CareDomain.skin:
        return 'dermatologist';
      case CareDomain.bones:
        return 'orthopedist';
      case CareDomain.mind:
        return 'psychiatrist';
      case CareDomain.women:
        return 'gynecologist';
      case CareDomain.lungs:
        return 'pulmonologist';
      case CareDomain.eyes:
        return 'ophthalmologist';
      case CareDomain.dental:
        return 'dentist';
      case CareDomain.child:
        return 'pediatrician';
      case null:
        return null;
    }
  }

  String? _clean(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.toLowerCase();
    if (text.contains('cardio') || text.contains('heart')) return 'cardiologist';
    if (text.contains('skin') || text.contains('derma')) return 'dermatologist';
    if (text.contains('psych') || text.contains('mind')) return 'psychiatrist';
    if (text.contains('gyn') || text.contains('women') || text.contains('obstet')) return 'gynecologist';
    if (text.contains('ortho') || text.contains('bone')) return 'orthopedist';
    if (text.contains('lung') || text.contains('pulmon')) return 'pulmonologist';
    if (text.contains('child') || text.contains('pediat')) return 'pediatrician';
    if (text.contains('dent')) return 'dentist';
    if (text.contains('eye') || text.contains('opth') || text.contains('optom')) return 'ophthalmologist';
    if (text.contains('endo') || text.contains('hormone')) return 'endocrinologist';
    return 'general physician';
  }

  Future<void> _openListings() async {
    final city = _city.text.trim();
    if (city.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the city you want doctors in.')),
      );
      return;
    }
    widget.appState.setHomeCity(city);
    final query = '$_specialty in $city';
    final maps = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final opened = await launchUrl(maps, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps for that city.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = _city.text.trim();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Find a doctor', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Doctors in your city', style: AppTypography.titleLg),
          const SizedBox(height: 8),
          const Text(
            'Cura opens live Google Maps listings for the specialty and city you choose. Those are clinics people can actually find, not a sample list.',
            style: TextStyle(height: 1.4, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'e.g. Indore',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: widget.appState.setHomeCity,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in _options)
                ChoiceChip(
                  label: Text(option),
                  selected: _specialty == option,
                  onSelected: (_) => setState(() => _specialty = option),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openListings,
            icon: const Icon(Icons.map_rounded),
            label: Text(city.isEmpty ? 'See doctors' : 'See $_specialty in $city'),
          ),
        ],
      ),
    );
  }
}
