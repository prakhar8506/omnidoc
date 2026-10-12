import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/nutrition/meal_parser.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class LogMealSheet extends StatefulWidget {
  const LogMealSheet({super.key, required this.appState, this.initialMealType = 'Breakfast'});

  final AppState appState;
  final String initialMealType;

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  final _text = TextEditingController();
  final _speech = SpeechToText();
  final _picker = ImagePicker();
  late String _mealType;
  String? _photoPath;
  bool _listening = false;
  String? _error;
  ParsedMeal _parsed = parseMealText('');

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
  }

  @override
  void dispose() {
    _text.dispose();
    _speech.stop();
    super.dispose();
  }

  void _reparse(String value) {
    setState(() {
      _parsed = parseMealText(value);
      _error = null;
    });
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ready = await _speech.initialize(
      onError: (err) {
        if (mounted) {
          setState(() {
            _listening = false;
            _error = 'Voice input stopped. Type the foods instead.';
          });
        }
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!ready) {
      if (mounted) {
        setState(() => _error = 'Microphone permission is needed for voice logging.');
      }
      return;
    }
    if (mounted) setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(listenMode: ListenMode.dictation, partialResults: true),
      onResult: (result) {
        _text.text = result.recognizedWords;
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
        _reparse(_text.text);
      },
    );
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file == null || !mounted) return;
    setState(() => _photoPath = file.path);
  }

  void _save() {
    if (_parsed.isEmpty) {
      setState(() => _error = 'Say or type foods with a number, such as “3 eggs and 2 roti”.');
      return;
    }
    widget.appState.addMeal({
      'title': _text.text.trim(),
      'category': _mealType,
      'time': _mealType,
      'calories': _parsed.calories.round(),
      'protein': _parsed.protein,
      'carbs': _parsed.carbs,
      'fat': _parsed.fat,
      'fiber': _parsed.fiber,
      'items': _parsed.lines.map((l) => l.toJson()).toList(),
      'photoPath': _photoPath ?? '',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Log a meal', style: AppTypography.editorialSm),
              const SizedBox(height: 4),
              Text(
                'Type or speak what you ate. “3 eggs” uses the average for three large eggs.',
                style: AppTypography.labelSm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _mealType == type,
                    onSelected: (_) => setState(() => _mealType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Ingredients',
                  hintText: '3 eggs, 2 roti, 1 bowl dal',
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: _reparse,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleVoice,
                      icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
                      label: Text(_listening ? 'Stop' : 'Voice'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Photo'),
                    ),
                  ),
                ],
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photoPath!), height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              if (_parsed.lines.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  '${_parsed.calories.round()} kcal  ·  ${_parsed.protein.round()}g protein  ·  ${_parsed.carbs.round()}g carbs  ·  ${_parsed.fat.round()}g fat',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                ..._parsed.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${line.label} · ${line.calories.round()} kcal · ${line.protein.toStringAsFixed(1)}g protein',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
              if (_parsed.unmatched.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Not matched yet: ${_parsed.unmatched.join(', ')}. Add a number, like “1 bowl”.',
                    style: const TextStyle(fontSize: 12, color: AppColors.accentCoral),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Add to today'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
