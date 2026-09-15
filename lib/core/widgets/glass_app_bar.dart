import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import '../../features/family/screens/family_connect_screen.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final AppState appState;

  const GlassAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.appState,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(20, 20, 40, 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left brand logo + title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Health Companion',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),

          // Right action buttons
          Row(
            children: [
              // Notification Bell
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('2 Unread updates: Lab report verified & Appointment in 2h.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.surfaceCardDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                  if (appState.unreadNotificationsCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Profile Avatar
              GestureDetector(
                onTap: () {
                  _showProfileDialog(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.network(
                      appState.userAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Text('SJ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(appState.userAvatar),
            ),
            const SizedBox(height: 12),
            Text(appState.userName, style: AppTypography.titleLg),
            const SizedBox(height: 4),
            if (appState.userEmail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(appState.userEmail, style: AppTypography.labelSm),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Emergency Blood ID: ${appState.bloodType}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.surfaceContainerHigh),
            ListTile(
              dense: true,
              leading: const Icon(Icons.people_outline_rounded, color: AppColors.primaryContainer),
              title: const Text('Family Connectivity', style: AppTypography.bodyMd),
              subtitle: Text('${appState.familyMembers.length} members connected', style: AppTypography.labelSm),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
              onTap: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FamilyConnectScreen(appState: appState)),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.shield_outlined, color: AppColors.primaryContainer),
              title: const Text('HIPAA & Data Encryption', style: AppTypography.bodyMd),
              subtitle: const Text('Active • End-to-End Encrypted', style: AppTypography.labelSm),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.emergency_outlined, color: AppColors.primaryContainer),
              title: const Text('Emergency SOS Contact', style: AppTypography.bodyMd),
              subtitle: const Text('David Jenkins (Spouse)', style: AppTypography.labelSm),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentCoral,
                  side: BorderSide(color: AppColors.accentCoral.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  appState.signOut();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryContainer)),
          ),
        ],
      ),
    );
  }
}
