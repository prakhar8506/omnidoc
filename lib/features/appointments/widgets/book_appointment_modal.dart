import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/appointment.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/avatar_image.dart';

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
  int _selectedSpecialtyIndex = 0;
  int _selectedSlotIndex = 0;
  bool _isVideo = false;
  final TextEditingController _reasonController = TextEditingController();

  final List<Map<String, dynamic>> _doctors = [
    {
      'name': 'Dr. Priya Sharma, MD',
      'specialty': 'Internal Medicine & Hepatology',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjYVUUFq-37pCqIkprzJW0Wx_HCEqZi_pojgtYHuNHCYORqQMkpq8kx73AXEQ4l2Ged06kqgnqvs1taHv0aOPp-Gx7Gi130wBUpJemTaMAdsSUQ1NhsZ-aKRql8JPedBEWE6r_vOGJXbJl6cCyIpS1DejAmz7zR7WJT2BEeTKFUktIDXG03Iu4fjF288S7lbkm_u0OAaGC9S-vss257hKUs-rGM5jAwtvQ2cEg0tXSTo_OaF4W8AbUXg',
      'clinic': 'Metro Center Health Pavilion',
    },
    {
      'name': 'Dr. Marcus Vance, FACC',
      'specialty': 'Cardiovascular Health',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDFqT3K0T9U8xJz3h8m-aV3fP3X9X1gK3X1_71ApBPCglKe_3i3GLe2QSUwJIWat2UrqfdLnT8bh1XFO_yIun2RsQrihSZd9zFDRXuRFYcUDLlsw0RUkFoq2jn4D-xZnFRX4J2oRUCKVRSqsCUnpfgBkWJFC6mOHMpRG29Whs6nasoasUm1KMFUXskhivppe3PqwgXRK2epMLhjR-B6hL0PlQPfXHKtSrzmRDB1KDgCMF5xhEaM3nbeqgqbHnx1JzL1GxwU4Q',
      'clinic': 'Virtual Cardiology Telehealth',
    },
    {
      'name': 'Dr. Elena Rostova, MD',
      'specialty': 'Endocrinology & Metabolism',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBcoFHSis1XxVDmBl7hk56dd97bAqbvjiUvgqTv-5VhElxMp5YTqFocH2FvUl1bFmczGheAUOzcO3J6uNoBlxZkKLV1r56lQQvltvQknCtArDW05V6QXwUuhhb8YwBWEQ15XuDOWTEqnoKrxn4qvz8IDy1IUtmHu-T63BgMxCT86f99QS2h_TzD9SKQN-8rkht_Ds2OZdOU3dByEVnNpdY_ye6OGTddpRR00wpGovZYFiXV5XcU3sbsHg',
      'clinic': 'Endocrine Metabolic Institute',
    },
  ];

  final List<String> _slots = [
    'Tomorrow, 09:30 AM',
    'Tomorrow, 02:00 PM',
    'Friday, 11:15 AM',
    'Friday, 04:30 PM',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirmBooking() {
    final doc = _doctors[_selectedSpecialtyIndex];
    final appt = Appointment(
      id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
      doctorName: doc['name'] as String,
      doctorTitle: doc['specialty'] as String,
      specialty: (doc['specialty'] as String).split('&').first.trim(),
      avatarUrl: doc['avatar'] as String,
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 3)),
      clinicName: doc['clinic'] as String,
      roomOrType: _isVideo ? 'HD Telehealth Video Call' : 'In-Person Consultation • Suite 300',
      isVideoConsult: _isVideo,
      status: 'Confirmed',
      preparationNote: _reasonController.text.isNotEmpty
          ? _reasonController.text
          : 'Consultation notes uploaded. Lab records synchronized.',
      themeColor: _isVideo ? AppColors.accentTeal : AppColors.primaryContainer,
    );

    widget.appState.addAppointment(appt);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment confirmed with ${doc['name']}!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Schedule Medical Visit', style: AppTypography.titleLg),
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
                const Text('Select Specialist', style: AppTypography.labelMd),
                const SizedBox(height: 10),
                ...List.generate(_doctors.length, (index) {
                  final doc = _doctors[index];
                  final isSelected = _selectedSpecialtyIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedSpecialtyIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.surfaceCard : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? AppColors.cardShadow : null,
                      ),
                      child: Row(
                        children: [
                          AvatarImage(
                            imageUrl: doc['avatar'] as String,
                            initials: initialsFromName(doc['name'] as String),
                            radius: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(doc['specialty'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primaryContainer, size: 22),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('Consultation Format', style: AppTypography.labelMd),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('In-Clinic Visit'),
                          ],
                        ),
                        selected: !_isVideo,
                        onSelected: (val) => setState(() => _isVideo = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Telehealth HD'),
                          ],
                        ),
                        selected: _isVideo,
                        onSelected: (val) => setState(() => _isVideo = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Available Time Slots', style: AppTypography.labelMd),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_slots.length, (index) {
                    final slot = _slots[index];
                    final isSelected = _selectedSlotIndex == index;
                    return ActionChip(
                      backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.surfaceCard,
                      side: BorderSide(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                      ),
                      label: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      onPressed: () => setState(() => _selectedSlotIndex = index),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Reason for Visit / Symptoms', style: AppTypography.labelMd),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Discuss elevated ALT lab results and headache follow-up...',
                    hintStyle: AppTypography.labelSm,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: _confirmBooking,
                  child: const Text('Confirm & Book Appointment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
