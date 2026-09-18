import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/watch_face_tile.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';

class ChronicCareScreen extends StatefulWidget {
  final AppState appState;
  final int initialTabIndex; // 0 for Diabetes, 1 for Hypertension

  const ChronicCareScreen({
    super.key,
    required this.appState,
    this.initialTabIndex = 0,
  });

  @override
  State<ChronicCareScreen> createState() => _ChronicCareScreenState();
}

class _ChronicCareScreenState extends State<ChronicCareScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Scaffold(
          body: HolographicBackground(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BouncingTap(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            ),
                          ),
                          Text('Chronic Condition Companion', style: AppTypography.editorialSm),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),

                  // Segmented Switcher (Diabetes vs Hypertension)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentItem(0, 'Blood Glucose (Diabetes)'),
                            _buildSegmentItem(1, 'Blood Pressure (Hypertension)'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content Body
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_selectedTab == 0) ..._buildDiabetesView(context) else ..._buildHypertensionView(context),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentItem(int index, String title) {
    final isSel = _selectedTab == index;
    return Expanded(
      child: BouncingTap(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSel ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDiabetesView(BuildContext context) {
    return [
      // Watch Face Tile for Glucose
      WatchFaceTile(
        title: 'Blood Glucose',
        value: '${widget.appState.bloodGlucoseMgDl}',
        unit: 'mg/dL',
        subtitle: widget.appState.fastingStatus,
        icon: Icons.bloodtype_rounded,
        glowColor: AppColors.watchGlucose,
        trailingBadge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentTeal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Target Range',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentTeal),
          ),
        ),
      ),
      const SizedBox(height: 18),

      // Doctor Discussion Prep Card
      _buildDoctorPrepCard(
        context: context,
        title: 'Doctor Discussion Prep • Endocrine Care',
        questions: [
          'Review whether fasting glucose (102 mg/dL) aligns with 3-month HbA1c goals.',
          'Discuss glycemic curve response following whole grain lunches vs evening meals.',
          'Determine if current exercise timing optimizes peripheral insulin sensitivity.',
        ],
      ),
      const SizedBox(height: 18),

      // Non-prescriptive Safety Notice
      _buildClinicalSafetyNotice(
        'For logging and clinician collaboration only. Cura never calculates, recommends, or adjusts insulin dosing or prescription medications.',
      ),
      const SizedBox(height: 18),

      // Log New Reading Button
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recent Glucose History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          BouncingTap(
            onTap: () => _showLogGlucoseDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Log Value',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      ...widget.appState.glucoseHistory.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.watchGlucose,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['val']} mg/dL',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(item['status'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Text(item['time'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _buildHypertensionView(BuildContext context) {
    return [
      // Watch Face Tile for BP
      WatchFaceTile(
        title: 'Blood Pressure',
        value: widget.appState.bloodPressure,
        unit: 'mmHg',
        subtitle: 'Optimal • American Heart Association Guideline',
        icon: Icons.monitor_heart_rounded,
        glowColor: AppColors.accentTeal,
        trailingBadge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.accentTeal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '< 120/80',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentTeal),
          ),
        ),
      ),
      const SizedBox(height: 18),

      // Doctor Discussion Prep Card
      _buildDoctorPrepCard(
        context: context,
        title: 'Doctor Discussion Prep • Cardiovascular Care',
        questions: [
          'Confirm whether morning resting readings reflect steady state vascular resistance.',
          'Discuss impact of sleep duration (7h 10m) on diurnal blood pressure dipping.',
          'Review dietary sodium correlation trends logged this month.',
        ],
      ),
      const SizedBox(height: 18),

      _buildClinicalSafetyNotice(
        'Blood pressure readings are informational and intended to facilitate dialogue with your attending physician. Do not alter antihypertensive regimens without direct medical counsel.',
      ),
      const SizedBox(height: 18),

      // Log New Reading Button
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recent BP Readings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          BouncingTap(
            onTap: () => _showLogBpDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Log BP',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      ...widget.appState.bpHistory.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['sys']}/${item['dia']} mmHg',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(item['category'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Text(item['time'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildDoctorPrepCard({required BuildContext context, required String title, required List<String> questions}) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: Colors.white.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...questions.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        q,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textSecondary.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildClinicalSafetyNotice(String notice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice,
              style: const TextStyle(fontSize: 11.5, height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogGlucoseDialog(BuildContext context) {
    final controller = TextEditingController(text: '105');
    String status = 'Fasting (Morning)';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Blood Glucose', style: AppTypography.editorialSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Glucose Level (mg/dL)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: ['Fasting (Morning)', 'Pre-Meal', '2h Post-Prandial', 'Bedtime']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) {
                if (val != null) status = val;
              },
              decoration: InputDecoration(
                labelText: 'Measurement Context',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 100;
              widget.appState.logGlucose(val, status);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save Entry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogBpDialog(BuildContext context) {
    final sysController = TextEditingController(text: '120');
    final diaController = TextEditingController(text: '80');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Blood Pressure', style: AppTypography.editorialSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Systolic (mmHg)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: diaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Diastolic (mmHg)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              final sys = int.tryParse(sysController.text) ?? 120;
              final dia = int.tryParse(diaController.text) ?? 80;
              widget.appState.logBloodPressure(sys, dia);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save Entry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
