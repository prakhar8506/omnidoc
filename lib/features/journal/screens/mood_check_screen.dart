import 'package:flutter/material.dart';
import '../../../core/mental/mood_check.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../appointments/screens/find_care_screen.dart';

class MoodCheckScreen extends StatefulWidget {
  final AppState appState;

  const MoodCheckScreen({super.key, required this.appState});

  @override
  State<MoodCheckScreen> createState() => _MoodCheckScreenState();
}

class _MoodCheckScreenState extends State<MoodCheckScreen> {
  int _index = 0;
  final List<MoodAnswer> _answers = [];
  DateTime _shownAt = DateTime.now();
  MoodCheckResult? _result;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
  }

  void _choose(int choice) {
    final millis = DateTime.now().difference(_shownAt).inMilliseconds;
    _answers.add(MoodAnswer(choice: choice, millis: millis));
    if (_index >= moodQuestions.length - 1) {
      final result = scoreMoodCheck(_answers);
      widget.appState.saveMoodCheck(result);
      setState(() => _result = result);
      return;
    }
    setState(() {
      _index++;
      _shownAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Mood check', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: result == null ? _question() : _done(result),
      ),
    );
  }

  Widget _question() {
    final question = moodQuestions[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Text(
          'Question ${_index + 1} of ${moodQuestions.length}',
          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'This is a wellness screening, not a diagnosis of depression. Answer for the last two weeks. The time you take is part of the score.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 22),
        Text(question.prompt, style: AppTypography.titleLg),
        const SizedBox(height: 18),
        for (var i = 0; i < moodChoices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _choose(i),
                child: Text(moodChoices[i], style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _done(MoodCheckResult result) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        Text(result.quality, style: AppTypography.editorialMd),
        const SizedBox(height: 8),
        Text(
          'Check score ${result.checkScore} · answers ${result.answerScore}/24 · pace ${result.pace}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(result.summary, style: const TextStyle(height: 1.45, fontSize: 15)),
        const SizedBox(height: 16),
        const Text(
          'If you might hurt yourself, contact local emergency services now — 112 in India, or 911 / 988 in the US. AASRA +91 9820466726 and iCall 9152987821 are crisis lines. This screen cannot diagnose depression.',
          style: TextStyle(height: 1.4, color: AppColors.textSecondary),
        ),
        if (result.seeDoctor) ...[
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FindCareScreen(
                  appState: widget.appState,
                  specialty: 'psychiatrist',
                ),
              ),
            ),
            child: Text(result.urgent ? 'Find a doctor in your city today' : 'Find a doctor in your city'),
          ),
        ],
      ],
    );
  }
}
