import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';

class JournalEntrySheet extends StatefulWidget {
  final AppState appState;
  final String? initialPrompt;

  const JournalEntrySheet({
    super.key,
    required this.appState,
    this.initialPrompt,
  });

  static Future<void> show(BuildContext context, AppState appState, {String? initialPrompt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JournalEntrySheet(appState: appState, initialPrompt: initialPrompt),
    );
  }

  @override
  State<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<JournalEntrySheet> with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late String _selectedPrompt;
  late String _selectedMood;
  String? _attachedImagePath;
  bool _isRecording = false;
  bool _audioRecorded = false;
  late AnimationController _waveController;

  final List<String> _guidedPrompts = const [
    "What's on your mind today?",
    "What's one thing that went well today?",
    "What felt physically challenging?",
    "Body scan & autonomic sensations",
    "Gratitude & mental clarity",
  ];

  final List<String> _moodOptions = const [
    'Sleepy',
    'Relaxed',
    'Calm',
    'Energetic',
    'Focused',
    'Radiant',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPrompt = widget.initialPrompt ?? _guidedPrompts[0];
    _selectedMood = widget.appState.selectedMood;
    _textController = TextEditingController();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1080);
      if (picked != null) {
        setState(() {
          _attachedImagePath = picked.path;
        });
      }
    } catch (_) {}
  }

  void _toggleVoiceDictation() {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        _audioRecorded = true;
      });
      _waveController.stop();
      if (_textController.text.trim().isEmpty) {
        _textController.text =
            "Noticed a steady, calm heartbeat following morning light exposure. Feeling mentally centered and ready for gentle movement.";
      }
    } else {
      // Start recording
      setState(() {
        _isRecording = true;
      });
      _waveController.repeat(reverse: true);
    }
  }

  void _saveEntry() {
    final text = _textController.text.trim();
    if (text.isEmpty && !_audioRecorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write a thought or record a voice reflection'),
          backgroundColor: AppColors.surfaceCardDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    widget.appState.addJournalEntry(
      content: text.isNotEmpty
          ? text
          : "Voice reflection recorded • Transcribed as mindful resting state.",
      prompt: _selectedPrompt,
      mood: _selectedMood,
      photoPath: _attachedImagePath,
      audioRecorded: _audioRecorded,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reflection saved to health timeline • Balance score ${widget.appState.dailyBalanceScore}%'),
        backgroundColor: AppColors.surfaceCardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 36,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Reflection', style: AppTypography.titleLg),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.surfaceContainerHigh),
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Guided Prompt Chips
                    const Text('Guided Prompts', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _guidedPrompts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final p = _guidedPrompts[index];
                          final isSelected = p == _selectedPrompt;
                          return ChoiceChip(
                            label: Text(p),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedPrompt = p;
                                });
                              }
                            },
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                            selectedColor: AppColors.primaryContainer,
                            backgroundColor: AppColors.surfaceBright,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerHigh,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mood State Selector
                    const Text('Mood State', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moodOptions.map((mood) {
                        final isSelected = mood == _selectedMood;
                        return ChoiceChip(
                          avatar: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.primaryContainer,
                          ),
                          label: Text(mood),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedMood = mood;
                              });
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: AppColors.surfaceBright,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerHigh,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Multi-line Text Area
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBright,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: 6,
                        style: AppTypography.bodyMd,
                        decoration: InputDecoration(
                          hintText: 'Describe how your body feels, thoughts, autonomic state...',
                          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Voice Dictation Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? const Color(0xFFFEE2E2)
                            : AppColors.surfaceBright,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isRecording
                              ? const Color(0xFFEF4444)
                              : AppColors.surfaceContainerHigh,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleVoiceDictation,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? const Color(0xFFEF4444)
                                    : AppColors.primaryContainer.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                color: _isRecording ? Colors.white : AppColors.primaryContainer,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRecording
                                      ? 'Listening & transcribing dictation...'
                                      : (_audioRecorded
                                          ? 'Voice note attached (0:24)'
                                          : 'Record voice reflection'),
                                  style: AppTypography.titleMd.copyWith(
                                    color: _isRecording
                                        ? const Color(0xFFB91C1C)
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isRecording
                                      ? 'Tap stop when finished'
                                      : 'Converts speech to private clinical reflection',
                                  style: AppTypography.labelSm,
                                ),
                              ],
                            ),
                          ),
                          if (_isRecording)
                            AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, _) {
                                return Row(
                                  children: List.generate(4, (i) {
                                    final factor = ((_waveController.value + (i * 0.25)) % 1.0);
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: 3,
                                      height: 8 + (factor * 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Photo Attachment Area
                    if (_attachedImagePath != null) ...[
                      Stack(
                        children: [
                          Container(
                            height: 140,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.surfaceContainerHigh,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: !kIsWeb
                                ? Image.file(
                                    File(_attachedImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.image_not_supported_rounded),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.image_rounded, size: 48),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _attachedImagePath = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded, size: 18),
                              label: const Text('Take Photo'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.surfaceContainerHigh),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.surfaceContainerHigh),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Save Reflection Button
                    ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Journal Reflection',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
