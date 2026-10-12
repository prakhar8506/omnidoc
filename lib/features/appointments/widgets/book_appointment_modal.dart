import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/appointment.dart';
import '../../../core/state/app_state.dart';
import '../screens/find_care_screen.dart';

/// Saves a personal reminder for a visit the user arranged themselves.
/// Cura does not book appointments, so every field is the user's own entry.
class BookAppointmentModal extends StatefulWidget {
  final AppState appState;

  const BookAppointmentModal({super.key, required this.appState});

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookAppointmentModal(appState: appState),
    );
  }

  @override
  State<BookAppointmentModal> createState() => _BookAppointmentModalState();
}

class _BookAppointmentModalState extends State<BookAppointmentModal> {
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isVideo = false;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 30);
  String? _error;

  @override
  void dispose() {
    _doctorController.dispose();
    _clinicController.dispose();
    _specialtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _saveReminder() {
    final doctor = _doctorController.text.trim();
    if (doctor.isEmpty) {
      setState(() => _error = 'Enter the doctor or clinic you are seeing.');
      return;
    }

    final specialty = _specialtyController.text.trim();
    final clinic = _clinicController.text.trim();
    final when = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    widget.appState.addAppointment(
      Appointment(
        id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
        doctorName: doctor,
        doctorTitle: specialty,
        specialty: specialty,
        avatarUrl: '',
        dateTime: when,
        clinicName: clinic,
        roomOrType: _isVideo ? 'Video visit' : 'In-person visit',
        isVideoConsult: _isVideo,
        status: 'Reminder',
        preparationNote: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : 'Your own reminder. Cura does not contact the clinic.',
        themeColor: _isVideo ? AppColors.accentTeal : AppColors.primaryContainer,
      ),
    );

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Reminder saved for ${DateFormat('EEE d MMM, h:mm a').format(when)}.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.labelSm,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2C3A)
            : AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final ink = Theme.of(context).colorScheme.onSurface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text('Add visit reminder', style: AppTypography.titleLg.copyWith(color: ink)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset > 0 ? bottomInset + 12 : 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF2A2C3A) : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'This saves a reminder on your phone. Book the visit with the clinic yourself.',
                          style: TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Doctor or clinic', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: _doctorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _field('e.g. Dr. Rao'),
                ),
                const SizedBox(height: 12),
                Text('Hospital or clinic name (optional)', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: _clinicController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _field('e.g. City Care Clinic'),
                ),
                const SizedBox(height: 12),
                Text('Specialty (optional)', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: _specialtyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _field('e.g. Cardiology'),
                ),
                const SizedBox(height: 16),
                Text('When', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(
                          DateFormat('EEE d MMM').format(_date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_rounded, size: 16),
                        label: Text(
                          _time.format(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Visit format', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_hospital_outlined, size: 15),
                              SizedBox(width: 4),
                              Text('In-Clinic'),
                            ],
                          ),
                        ),
                        selected: !_isVideo,
                        onSelected: (_) => setState(() => _isVideo = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_outlined, size: 15),
                              SizedBox(width: 4),
                              Text('Telehealth'),
                            ],
                          ),
                        ),
                        selected: _isVideo,
                        onSelected: (_) => setState(() => _isVideo = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Reason for visit / symptoms', style: AppTypography.labelMd.copyWith(color: ink)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: _field('e.g. Follow up on my latest lab results'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentCoral,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: _saveReminder,
                  child: const Text('Save reminder',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => FindCareScreen(appState: widget.appState),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Find a doctor near me'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
