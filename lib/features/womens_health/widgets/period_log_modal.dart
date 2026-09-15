import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';

class PeriodLogModal extends StatefulWidget {
  final AppState appState;

  const PeriodLogModal({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PeriodLogModal(appState: appState),
    );
  }

  @override
  State<PeriodLogModal> createState() => _PeriodLogModalState();
}

class _PeriodLogModalState extends State<PeriodLogModal> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFlow = 'Medium';
  final List<String> _selectedSymptoms = [];
  final TextEditingController _notesController = TextEditingController();

  final List<String> _flowOptions = const ['Spotting', 'Light', 'Medium', 'Heavy'];

  final List<String> _symptomOptions = const [
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Backache',
    'High Energy',
    'Clear Mind',
    'Mood Swings',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveLog() {
    widget.appState.logPeriodDay(
      date: _selectedDate,
      flow: _selectedFlow,
      symptoms: _selectedSymptoms,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Logged $_selectedFlow flow for ${_selectedDate.day}/${_selectedDate.month} • Cycle Day 1 reset',
        ),
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Log Period & Flow', style: AppTypography.titleLg),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.surfaceContainerHigh),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date Selector
                    const Text('Date of Period', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBright,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceContainerHigh),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: AppColors.accentRose, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                                  style: AppTypography.titleMd,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 60)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: const BorderSide(color: AppColors.surfaceContainerHigh),
                          ),
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Flow Intensity
                    const Text('Flow Intensity', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    Row(
                      children: _flowOptions.map((flow) {
                        final isSel = flow == _selectedFlow;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFlow = flow),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.accentRose
                                    : AppColors.surfaceBright,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.accentRose
                                      : AppColors.surfaceContainerHigh,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.water_drop_rounded,
                                    size: 18,
                                    color: isSel ? Colors.white : AppColors.accentRose,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    flow,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSel ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Associated Symptoms
                    const Text('Associated Symptoms', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptomOptions.map((sym) {
                        final isSel = _selectedSymptoms.contains(sym);
                        return FilterChip(
                          label: Text(sym),
                          selected: isSel,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedSymptoms.add(sym);
                              } else {
                                _selectedSymptoms.remove(sym);
                              }
                            });
                          },
                          selectedColor: AppColors.accentRose.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.accentRose,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.accentRose : AppColors.textPrimary,
                          ),
                          backgroundColor: AppColors.surfaceBright,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.accentRose
                                  : AppColors.surfaceContainerHigh,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    const Text('Clinical Notes / Observations', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBright,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: AppTypography.bodyMd,
                        decoration: InputDecoration(
                          hintText: 'Any changes in energy, hydration, or cycle regularity...',
                          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRose,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Period Entry',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  String _getMonthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }
}
