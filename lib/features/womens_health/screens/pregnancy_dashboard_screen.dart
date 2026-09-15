import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/bouncing_tap.dart';
import '../../../core/widgets/holographic_background.dart';
import '../../../core/state/app_state.dart';

class PregnancyDashboardScreen extends StatefulWidget {
  final AppState appState;

  const PregnancyDashboardScreen({super.key, required this.appState});

  @override
  State<PregnancyDashboardScreen> createState() => _PregnancyDashboardScreenState();
}

class _PregnancyDashboardScreenState extends State<PregnancyDashboardScreen> {
  // Kick Counter State
  int _currentSessionKicks = 0;
  bool _isKickSessionActive = false;
  DateTime? _kickSessionStart;

  void _recordKick() {
    if (!_isKickSessionActive) {
      setState(() {
        _isKickSessionActive = true;
        _kickSessionStart = DateTime.now();
        _currentSessionKicks = 1;
      });
    } else {
      setState(() {
        _currentSessionKicks++;
      });
      if (_currentSessionKicks >= 10) {
        final duration = DateTime.now().difference(_kickSessionStart!).inMinutes.clamp(1, 120);
        widget.appState.logKickSession(kicks: _currentSessionKicks, durationMinutes: duration);
        setState(() {
          _isKickSessionActive = false;
          _currentSessionKicks = 0;
          _kickSessionStart = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session complete: 10 fetal kicks recorded in $duration minutes!'),
            backgroundColor: AppColors.surfaceCardDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showLogWeightDialog() {
    final controller = TextEditingController(text: widget.appState.currentPregnancyWeightKg.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log Pregnancy Weight', style: AppTypography.titleMd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consistent tracking ensures healthy maternal and fetal metabolic progression.',
              style: AppTypography.labelSm,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                widget.appState.logPregnancyWeight(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddScanDialog() {
    final titleCtrl = TextEditingController(text: 'Second Trimester Anatomy Scan');
    final weekCtrl = TextEditingController(text: 'Week 20');
    final findingsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Prenatal Scan', style: AppTypography.titleMd),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Scan Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weekCtrl,
                decoration: InputDecoration(
                  labelText: 'Gestational Week',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: findingsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Clinical Findings / Summary',
                  hintText: 'e.g. Normal fetal anatomy, amniotic fluid index optimal...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                widget.appState.addPrenatalScan(
                  title: titleCtrl.text.trim(),
                  gestationalWeek: weekCtrl.text.trim(),
                  findings: findingsCtrl.text.trim().isNotEmpty
                      ? findingsCtrl.text.trim()
                      : 'Ultrasound reviewed. Normal biometric parameters for gestational age.',
                  doctorName: 'Dr. Elena Rostova, OB-GYN',
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Scan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.appState;
    final weeks = state.gestationalWeeks;
    final days = state.gestationalDaysRemainder;
    final trimester = state.pregnancyTrimester;
    final babyDev = state.currentBabyDevelopment;
    final daysRemaining = state.pregnancyDueDate.difference(DateTime.now()).inDays.clamp(0, 300);

    return Scaffold(
      body: HolographicBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Navigation Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                      const Text('Pregnancy Companion', style: AppTypography.titleLg),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFF472B6)),
                        ),
                        child: const Text(
                          'Active Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDB2777),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. Gestational Age Hero Card
                    _buildGestationalHeroCard(weeks, days, trimester, daysRemaining),
                    const SizedBox(height: 18),

                    // 2. Baby Milestone Development Card
                    _buildBabyDevelopmentCard(babyDev, weeks),
                    const SizedBox(height: 18),

                    // 3. Fetal Kick Counter Tool
                    _buildKickCounterCard(),
                    const SizedBox(height: 18),

                    // 4. Pregnancy Weight Tracking Card
                    _buildWeightTrackingCard(state),
                    const SizedBox(height: 18),

                    // 5. Prenatal Scan Vault & Checklist
                    _buildScanVaultCard(state),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestationalHeroCard(int weeks, int days, String trimester, int daysRemaining) {
    final progress = (weeks / 40.0).clamp(0.05, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: 28,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        trimester.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Week $weeks',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    '+ $days days • $daysRemaining days to due date',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Circular progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFFFCE7F3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'term',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0x1A1C1A27)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricBadge('Due Date', '${widget.appState.pregnancyDueDate.day}/${widget.appState.pregnancyDueDate.month}/${widget.appState.pregnancyDueDate.year}'),
              _metricBadge('Trimester', trimester),
              _metricBadge('Fetal Heart Rate', '154 bpm (Normal)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBabyDevelopmentCard(Map<String, dynamic> babyDev, int weeks) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Baby Development', style: AppTypography.titleMd),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  babyDev['sizeComparison'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBE185D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            babyDev['milestone'] as String,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBright,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryContainer, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    babyDev['careAdvice'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickCounterCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fetal Kick Counter', style: AppTypography.titleMd),
                  SizedBox(height: 2),
                  Text('Clinical target: 10 movements in under 2 hours', style: AppTypography.labelSm),
                ],
              ),
              if (_isKickSessionActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Session Active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _recordKick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '$_currentSessionKicks / 10',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Tap for kick',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Past kick history
          if (widget.appState.kickCounterLogs.isNotEmpty) ...[
            const Text('Recent Kick Sessions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.appState.kickCounterLogs.take(2).map((k) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                        const SizedBox(width: 6),
                        Text('${k['kicks']} kicks in ${k['durationMinutes']} mins', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(k['status'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightTrackingCard(AppState state) {
    final gain = (state.currentPregnancyWeightKg - state.prePregnancyWeightKg);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maternal Weight Gain', style: AppTypography.titleMd),
                  const SizedBox(height: 2),
                  Text('Pre-pregnancy: ${state.prePregnancyWeightKg} kg', style: AppTypography.labelSm),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showLogWeightDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Weight', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${state.currentPregnancyWeightKg} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Gain', style: TextStyle(fontSize: 11, color: Color(0xFFDB2777))),
                      const SizedBox(height: 4),
                      Text('+${gain.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFDB2777))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Target recommended gain for 1st trimester: 1.0 – 2.0 kg • On Track (ACOG guidelines)',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildScanVaultCard(AppState state) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prenatal Scan Vault', style: AppTypography.titleMd),
                  SizedBox(height: 2),
                  Text('Verified imaging & clinical summaries', style: AppTypography.labelSm),
                ],
              ),
              IconButton(
                onPressed: _showAddScanDialog,
                icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...state.prenatalScans.map((scan) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        scan['gestationalWeek'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      Text(
                        scan['doctorName'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan['title'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan['findings'] as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
