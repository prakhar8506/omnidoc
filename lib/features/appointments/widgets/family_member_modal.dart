import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/models/family_member.dart';
import '../../../core/state/app_state.dart';

class FamilyMemberModal extends StatefulWidget {
  final AppState appState;

  const FamilyMemberModal({super.key, required this.appState});

  static void show(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FamilyMemberModal(appState: appState),
    );
  }

  @override
  State<FamilyMemberModal> createState() => _FamilyMemberModalState();
}

class _FamilyMemberModalState extends State<FamilyMemberModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool _shareVitals = true;
  bool _shareLabs = true;
  bool _shareRx = true;
  bool _emergencySos = true;

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _addMember() {
    if (_nameController.text.trim().isEmpty) return;

    final newMember = FamilyMember(
      id: 'fam-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      relation: _relationController.text.isNotEmpty ? _relationController.text.trim() : 'Family',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCl5FbkrOKPHatJB-X_71ApBPCglKe_3i3GLe2QSUwJIWat2UrqfdLnT8bh1XFO_yIun2RsQrihSZd9zFDRXuRFYcUDLlsw0RUkFoq2jn4D-xZnFRX4J2oRUCKVRSqsCUnpfgBkWJFC6mOHMpRG29Whs6nasoasUm1KMFUXskhivppe3PqwgXRK2epMLhjR-B6hL0PlQPfXHKtSrzmRDB1KDgCMF5xhEaM3nbeqgqbHnx1JzL1GxwU4Q',
      accessLevel: 'Custom Permitted Access',
      ageAndGender: _ageController.text.isNotEmpty ? _ageController.text.trim() : 'Active Member',
      shareVitals: _shareVitals,
      shareLabReports: _shareLabs,
      sharePrescriptions: _shareRx,
      emergencySosEnabled: _emergencySos,
    );

    widget.appState.addFamilyMember(newMember);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newMember.name} added to Family Sharing.'),
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
      height: MediaQuery.of(context).size.height * 0.8,
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
                const Text('Invite Family Member', style: AppTypography.titleLg),
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
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Liam Jenkins',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _relationController,
                        decoration: InputDecoration(
                          labelText: 'Relationship',
                          hintText: 'e.g. Brother / Son',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Age / Note',
                          hintText: 'e.g. 29 yrs',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Sharing Permissions', style: AppTypography.titleMd),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Share Live Vitals & Apple Health', style: AppTypography.bodyMd),
                  value: _shareVitals,
                  activeThumbColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _shareVitals = v),
                ),
                SwitchListTile(
                  title: const Text('Share Diagnostic Lab Reports', style: AppTypography.bodyMd),
                  value: _shareLabs,
                  activeThumbColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _shareLabs = v),
                ),
                SwitchListTile(
                  title: const Text('Share Prescriptions & Supplements', style: AppTypography.bodyMd),
                  value: _shareRx,
                  activeThumbColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _shareRx = v),
                ),
                SwitchListTile(
                  title: const Text('Enable Emergency SOS Alerts', style: AppTypography.bodyMd),
                  value: _emergencySos,
                  activeThumbColor: AppColors.accentCoral,
                  onChanged: (v) => setState(() => _emergencySos = v),
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
                  onPressed: _addMember,
                  child: const Text('Send Encrypted Family Invite', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
