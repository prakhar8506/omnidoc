import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../state/app_state.dart';
import 'avatar_image.dart';
import '../../features/family/screens/family_connect_screen.dart';
import '../../features/ai_assistant/widgets/ai_chat_sheet.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_of_use_screen.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final AppState appState;

  /// Optional override for Delete Account. Defaults to [AppState.deleteAccount].
  final Future<void> Function()? onDeleteAccount;

  const GlassAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.appState,
    this.onDeleteAccount,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final nowFormatted = DateFormat('EEE, dd MMM').format(DateTime.now());

    return Container(
      padding: EdgeInsets.only(
        top: topPad + 4,
        left: 20,
        right: 20,
        bottom: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(30, 20, 50, 0.03),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showProfileDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryContainer.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: AvatarImage(
                      imageUrl: appState.userAvatar,
                      initials: initialsFromName(appState.userName),
                      radius: 17,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        appState.setSelectedDateIndex(DateTime.now().weekday - 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                appState.currentTabIndex == 0
                                    ? 'Today, $nowFormatted'
                                    : appState.currentTabIndex == 1
                                        ? "${appState.firstName}'s Journal"
                                        : subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryContainer,
                    size: 20,
                  ),
                  tooltip: 'Omni AI Copilot',
                  onPressed: () => AiChatSheet.show(context, appState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AvatarImage(
                    imageUrl: appState.userAvatar,
                    initials: initialsFromName(appState.userName),
                    radius: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(appState.userName, style: AppTypography.editorialSm),
                  const SizedBox(height: 4),
                  if (appState.userEmail.isNotEmpty)
                    Text(appState.userEmail, style: AppTypography.labelSm),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      appState.isWearableConnected
                          ? 'Wearable linked • ${appState.bloodType.isEmpty ? 'Blood type unset' : 'ID ${appState.bloodType}'}'
                          : (appState.bloodType.isEmpty
                              ? 'Profile'
                              : 'Blood type ${appState.bloodType}'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.surfaceContainerHigh),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.people_outline_rounded, color: AppColors.primaryContainer),
                    title: const Text('Family Connectivity', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${appState.familyMembers.length} members connected',
                      style: AppTypography.labelSm,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FamilyConnectScreen(appState: appState),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryContainer),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined, color: AppColors.primaryContainer),
                    title: const Text('Terms of Use', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.delete_forever_outlined, color: AppColors.accentCoral),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accentCoral),
                    ),
                    subtitle: const Text(
                      'Permanently remove your account',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _confirmDeleteAccount(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentCoral,
                        side: BorderSide(color: AppColors.accentCoral.withValues(alpha: 0.3)),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete account?', style: AppTypography.titleMd),
        content: const Text(
          'This will permanently delete your Cura account and local health data on this device. This action cannot be undone.',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentCoral),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (onDeleteAccount != null) {
        await onDeleteAccount!();
      } else {
        await appState.deleteAccount();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your account has been deleted.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceCardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete account: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceCardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
