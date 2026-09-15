import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../widgets/book_appointment_modal.dart';
import '../widgets/family_member_modal.dart';

class AppointmentsScreen extends StatelessWidget {
  final AppState appState;

  const AppointmentsScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isAppointmentsTab = appState.appointmentSegmentIndex == 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segment Pill Switcher
              _buildSegmentPillSwitcher(),
              const SizedBox(height: 18),

              if (isAppointmentsTab) ...[
                // SECTION 1: APPOINTMENTS VIEW
                _buildDateStripSelector(),
                const SizedBox(height: 18),
                _buildUpcomingConsultationBanner(context),
                const SizedBox(height: 22),
                _buildScheduledVisitsHeader(context),
                const SizedBox(height: 14),
                _buildAppointmentCards(context),
              ] else ...[
                // SECTION 2: FAMILY SHARING VIEW
                _buildFamilySharingSection(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentPillSwitcher() {
    final currentIndex = appState.appointmentSegmentIndex;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => appState.setAppointmentSegment(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: currentIndex == 0 ? AppColors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: currentIndex == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: currentIndex == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Upcoming Visits',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: currentIndex == 0 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => appState.setAppointmentSegment(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: currentIndex == 1 ? AppColors.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: currentIndex == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: currentIndex == 1 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Family Sharing',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: currentIndex == 1 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStripSelector() {
    final days = [
      {'day': 'Mon', 'date': '21'},
      {'day': 'Tue', 'date': '22'},
      {'day': 'Wed', 'date': '23'},
      {'day': 'Thu', 'date': '24'},
      {'day': 'Fri', 'date': '25'},
      {'day': 'Sat', 'date': '26'},
      {'day': 'Sun', 'date': '27'},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('October 2024', style: AppTypography.titleMd),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(days.length, (index) {
            final item = days[index];
            final isSelected = appState.selectedDateIndex == index;

            return GestureDetector(
              onTap: () => appState.setSelectedDateIndex(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      item['day']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['date']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUpcomingConsultationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consultation Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Dr. Sharma at Metro Center Clinic • 10:30 AM', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'In 2h',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledVisitsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('Scheduled Visits', style: AppTypography.titleLg),
            const SizedBox(width: 8),
            Text('(${appState.appointments.length} confirmed)', style: AppTypography.labelSm),
          ],
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryContainer,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
          label: const Text('Book Visit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          onPressed: () => BookAppointmentModal.show(context, appState),
        ),
      ],
    );
  }

  Widget _buildAppointmentCards(BuildContext context) {
    return Column(
      children: appState.appointments.map((appt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(appt.avatarUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.doctorName, style: AppTypography.titleMd),
                        const SizedBox(height: 2),
                        Text(appt.doctorTitle, style: AppTypography.labelSm),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appt.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      appt.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: appt.themeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location / Consultation Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          appt.isVideoConsult ? Icons.videocam_rounded : Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appt.clinicName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appt.preparationNote,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Actions Row
              Row(
                children: [
                  if (appt.isVideoConsult) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Join Video Call', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Launching telehealth video consultation with ${appt.doctorName}...'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.surfaceCardDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Opening navigation to Metro Center Health Pavilion...'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.surfaceCardDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rescheduling request submitted for ${appt.doctorName}.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.surfaceCardDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: const Text('Reschedule', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFamilySharingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Family Health Sharing', style: AppTypography.titleLg),
                SizedBox(height: 2),
                Text('Encrypted caregiver and dependent access', style: AppTypography.labelSm),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Invite', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              onPressed: () => FamilyMemberModal.show(context, appState),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Emergency SOS Broadcast Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentCoral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sos_rounded, color: AppColors.accentCoral, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Broadcast Enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentCoral)),
                    SizedBox(height: 2),
                    Text('In case of critical vitals alert, 3 family contacts will receive immediate SMS & GPS location.', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Family Members List
        ...appState.familyMembers.map((member) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(member.avatarUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(member.name, style: AppTypography.titleMd),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(member.relation, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryContainer)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${member.ageAndGender} • ${member.accessLevel}', style: AppTypography.labelSm),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.surfaceContainerHigh),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPermissionChip('Vitals', member.shareVitals),
                    _buildPermissionChip('Lab Reports', member.shareLabReports),
                    _buildPermissionChip('Prescriptions', member.sharePrescriptions),
                    _buildPermissionChip('Emergency SOS', member.emergencySosEnabled, isSos: true),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPermissionChip(String label, bool isEnabled, {bool isSos = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled
            ? (isSos ? AppColors.accentCoral.withValues(alpha: 0.15) : AppColors.accentTeal.withValues(alpha: 0.15))
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: isEnabled
                ? (isSos ? AppColors.accentCoral : const Color(0xFF0D9488))
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? (isSos ? AppColors.accentCoral : const Color(0xFF0F766E))
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
