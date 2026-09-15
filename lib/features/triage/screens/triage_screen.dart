import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/avatar_image.dart';

class TriageScreen extends StatefulWidget {
  final AppState appState;

  const TriageScreen({
    super.key,
    required this.appState,
  });

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final TextEditingController _symptomInputController = TextEditingController();
  bool _showRedFlags = false;

  @override
  void dispose() {
    _symptomInputController.dispose();
    super.dispose();
  }

  void _submitSymptom(String text) {
    if (text.trim().isEmpty) return;
    widget.appState.submitNewSymptomTriage(text.trim());
    _symptomInputController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New clinical assessment computed successfully.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceCardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final triage = widget.appState.activeTriage;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinical AI Assistant Ambient Header
              _buildHeader(),
              const SizedBox(height: 20),

              // User Query Interaction Bubble
              _buildUserQueryBubble(triage.userQuery),
              const SizedBox(height: 24),

              // Structured AI Triage Response Card
              _buildTriageResponseCard(triage),
              const SizedBox(height: 24),

              // Safe Home Self-Care Guidance
              _buildSelfCareGuidance(triage),
              const SizedBox(height: 24),

              // Red Flags Emergency Warning
              _buildRedFlagsSection(triage),
              const SizedBox(height: 24),

              // Interactive New Symptom Input
              _buildNewSymptomInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.primaryContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CLINICAL AI ASSISTANT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryContainer,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: AppColors.primaryContainer),
                  SizedBox(width: 6),
                  Text(
                    'Active Session',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Symptom Triage Assistant',
          style: AppTypography.headlineLgMobile,
        ),
        const SizedBox(height: 4),
        const Text(
          'Describe what you are feeling in plain words',
          style: AppTypography.bodyMd,
        ),
      ],
    );
  }

  Widget _buildUserQueryBubble(String query) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'You • 10:42 AM',
                style: AppTypography.labelSm,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(46, 91, 255, 0.25),
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  query,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: AppColors.accentTeal),
                  SizedBox(width: 4),
                  Text(
                    'Captured via secure encrypted audio/text',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AvatarImage(
          imageUrl: widget.appState.userAvatar,
          initials: initialsFromName(widget.appState.userName),
          radius: 16,
        ),
      ],
    );
  }

  Widget _buildTriageResponseCard(dynamic triage) {
    final isAudioPlaying = widget.appState.isAudioPlaying;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Audio toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clinical Triage Assessment', style: AppTypography.titleMd),
                      Text('Protocol v4.2 • Safe Lifestyle Scope', style: AppTypography.labelSm),
                    ],
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: isAudioPlaying ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                  foregroundColor: isAudioPlaying ? Colors.white : AppColors.textPrimary,
                ),
                icon: Icon(isAudioPlaying ? Icons.pause_rounded : Icons.volume_up_rounded, size: 20),
                tooltip: 'Listen to AI Audio Summary',
                onPressed: () => widget.appState.toggleAudioPlayback(),
              ),
            ],
          ),

          if (isAudioPlaying) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, color: AppColors.primaryContainer, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Playing medical audio narration...',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Urgency signal box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            triage.urgencyBadge,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      triage.timeframeWindow,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  triage.clinicalRationale,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Consultation button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(
                'Schedule Consultation (${triage.recommendedSpecialty.split('/').first.trim()})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                widget.appState.setTabIndex(2);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCareGuidance(dynamic triage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa_rounded, color: AppColors.accentTeal, size: 20),
              SizedBox(width: 8),
              Text('Safe Home Self-Care Guidance', style: AppTypography.titleMd),
            ],
          ),
          const SizedBox(height: 14),
          ...triage.selfCareItems.map<Widget>((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: AppColors.primaryContainer, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRedFlagsSection(dynamic triage) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.accentCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentCoral.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showRedFlags = !_showRedFlags;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.crisis_alert_rounded, color: AppColors.accentCoral, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Emergency Red Flag Signs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentCoral,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _showRedFlags ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.accentCoral,
                ),
              ],
            ),
          ),
          if (_showRedFlags) ...[
            const SizedBox(height: 12),
            ...triage.redFlagAlerts.map<Widget>((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        alert,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'If any red flags occur, call 911 or visit your nearest Emergency Department immediately.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentCoral),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewSymptomInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evaluate New Symptoms', style: AppTypography.titleMd),
          const SizedBox(height: 10),
          TextField(
            controller: _symptomInputController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g. Sharp pain in lower back after lifting, mild dizziness when standing...',
              hintStyle: AppTypography.labelSm,
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Run Clinical Assessment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: () => _submitSymptom(_symptomInputController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
