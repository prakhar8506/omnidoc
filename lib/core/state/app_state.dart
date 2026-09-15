import 'package:flutter/material.dart';
import '../models/vitals_data.dart';
import '../models/appointment.dart';
import '../models/biomarker_report.dart';
import '../models/triage_models.dart';
import '../models/family_member.dart';

class AppState extends ChangeNotifier {
  // Authentication State
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;
  String _userEmail = '';
  String get userEmail => _userEmail;

  void signIn(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    _userEmail = email;
    _isSignedIn = true;
    notifyListeners();
  }

  void signOut() {
    _isSignedIn = false;
    _userEmail = '';
    _currentTabIndex = 0;
    notifyListeners();
  }

  // Navigation State
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  // Profile Info
  final String userName = "Sarah Jenkins";
  final String bloodType = "A+";
  final String userAvatar = "https://lh3.googleusercontent.com/aida-public/AB6AXuBcoFHSis1XxVDmBl7hk56dd97bAqbvjiUvgqTv-5VhElxMp5YTqFocH2FvUl1bFmczGheAUOzcO3J6uNoBlxZkKLV1r56lQQvltvQknCtArDW05V6QXwUuhhb8YwBWEQ15XuDOWTEqnoKrxn4qvz8IDy1IUtmHu-T63BgMxCT86f99QS2h_TzD9SKQN-8rkht_Ds2OZdOU3dByEVnNpdY_ye6OGTddpRR00wpGovZYFiXV5XcU3sbsHg";
  int unreadNotificationsCount = 2;

  // Vitals State
  int restingHeartRate = 72;
  String sleepDuration = "7h 45m";
  double dailySteps = 8420;
  int bloodOxygen = 98;
  String bloodPressure = "118/76";
  bool isSyncingVitals = false;
  DateTime lastSyncedTime = DateTime.now().subtract(const Duration(minutes: 12));

  void syncVitals() async {
    isSyncingVitals = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 900));
    restingHeartRate = 71;
    dailySteps += 140;
    lastSyncedTime = DateTime.now();
    isSyncingVitals = false;
    notifyListeners();
  }

  // Medications
  final List<MedicationItem> medications = [
    MedicationItem(
      id: 'm1',
      name: 'Omega-3 EPA/DHA',
      dosage: '1,000 mg • 1 Softgel',
      scheduleTime: '8:00 AM (With Breakfast)',
      instruction: 'Take with healthy dietary fats for peak absorption.',
      isTaken: true,
    ),
    MedicationItem(
      id: 'm2',
      name: 'Vitamin D3 + K2',
      dosage: '2,000 IU • 1 Drop',
      scheduleTime: '1:00 PM (Lunch)',
      instruction: 'Supports bone density and calcium homeostasis.',
      isTaken: false,
    ),
    MedicationItem(
      id: 'm3',
      name: 'Magnesium Glycinate',
      dosage: '200 mg • 2 Capsules',
      scheduleTime: '9:30 PM (Pre-Sleep)',
      instruction: 'Promotes restorative sleep and muscle recovery.',
      isTaken: false,
    ),
  ];

  void toggleMedication(String id) {
    final med = medications.firstWhere((m) => m.id == id);
    med.isTaken = !med.isTaken;
    notifyListeners();
  }

  // Appointments
  int selectedDateIndex = 3; // Thu 24 by default
  int appointmentSegmentIndex = 0; // 0: Upcoming Visits, 1: Family Sharing

  void setAppointmentSegment(int index) {
    appointmentSegmentIndex = index;
    notifyListeners();
  }

  void setSelectedDateIndex(int index) {
    selectedDateIndex = index;
    notifyListeners();
  }

  final List<Appointment> appointments = [
    Appointment(
      id: 'apt-1',
      doctorName: 'Dr. Priya Sharma, MD',
      doctorTitle: 'Internal Medicine & Hepatology',
      specialty: 'Internal Medicine',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjYVUUFq-37pCqIkprzJW0Wx_HCEqZi_pojgtYHuNHCYORqQMkpq8kx73AXEQ4l2Ged06kqgnqvs1taHv0aOPp-Gx7Gi130wBUpJemTaMAdsSUQ1NhsZ-aKRql8JPedBEWE6r_vOGJXbJl6cCyIpS1DejAmz7zR7WJT2BEeTKFUktIDXG03Iu4fjF288S7lbkm_u0OAaGC9S-vss257hKUs-rGM5jAwtvQ2cEg0tXSTo_OaF4W8AbUXg',
      dateTime: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
      clinicName: 'Metro Center Health Pavilion • Suite 402',
      roomOrType: 'In-Person Consultation',
      isVideoConsult: false,
      status: 'In 2h',
      preparationNote: 'Bring CMP Lab Results & list of current supplements.',
      themeColor: const Color(0xFF2E5BFF),
    ),
    Appointment(
      id: 'apt-2',
      doctorName: 'Dr. Marcus Vance, FACC',
      doctorTitle: 'Cardiovascular Health Specialist',
      specialty: 'Cardiology',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDFqT3K0T9U8xJz3h8m-aV3fP3X9X1gK3X1_71ApBPCglKe_3i3GLe2QSUwJIWat2UrqfdLnT8bh1XFO_yIun2RsQrihSZd9zFDRXuRFYcUDLlsw0RUkFoq2jn4D-xZnFRX4J2oRUCKVRSqsCUnpfgBkWJFC6mOHMpRG29Whs6nasoasUm1KMFUXskhivppe3PqwgXRK2epMLhjR-B6hL0PlQPfXHKtSrzmRDB1KDgCMF5xhEaM3nbeqgqbHnx1JzL1GxwU4Q',
      dateTime: DateTime.now().add(const Duration(days: 6, hours: 4)),
      clinicName: 'Telehealth Virtual Video Room',
      roomOrType: 'HD Video Call • Link Ready',
      isVideoConsult: true,
      status: 'Confirmed',
      preparationNote: '7-day resting heart rate sync will auto-transmit.',
      themeColor: const Color(0xFF4FD1C5),
    ),
  ];

  void addAppointment(Appointment appt) {
    appointments.add(appt);
    notifyListeners();
  }

  void cancelAppointment(String id) {
    appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // Family Members
  final List<FamilyMember> familyMembers = [
    FamilyMember(
      id: 'fam-1',
      name: 'David Jenkins',
      relation: 'Spouse',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCCl5FbkrOKPHatJB-X_71ApBPCglKe_3i3GLe2QSUwJIWat2UrqfdLnT8bh1XFO_yIun2RsQrihSZd9zFDRXuRFYcUDLlsw0RUkFoq2jn4D-xZnFRX4J2oRUCKVRSqsCUnpfgBkWJFC6mOHMpRG29Whs6nasoasUm1KMFUXskhivppe3PqwgXRK2epMLhjR-B6hL0PlQPfXHKtSrzmRDB1KDgCMF5xhEaM3nbeqgqbHnx1JzL1GxwU4Q',
      accessLevel: 'Full Caregiver Access',
      ageAndGender: '35 yrs • Male',
      shareVitals: true,
      shareLabReports: true,
      sharePrescriptions: true,
      emergencySosEnabled: true,
    ),
    FamilyMember(
      id: 'fam-2',
      name: 'Maya Jenkins',
      relation: 'Daughter',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBcoFHSis1XxVDmBl7hk56dd97bAqbvjiUvgqTv-5VhElxMp5YTqFocH2FvUl1bFmczGheAUOzcO3J6uNoBlxZkKLV1r56lQQvltvQknCtArDW05V6QXwUuhhb8YwBWEQ15XuDOWTEqnoKrxn4qvz8IDy1IUtmHu-T63BgMxCT86f99QS2h_TzD9SKQN-8rkht_Ds2OZdOU3dByEVnNpdY_ye6OGTddpRR00wpGovZYFiXV5XcU3sbsHg',
      accessLevel: 'Dependent Profile',
      ageAndGender: '7 yrs • Female',
      shareVitals: true,
      shareLabReports: true,
      sharePrescriptions: true,
      emergencySosEnabled: false,
    ),
    FamilyMember(
      id: 'fam-3',
      name: 'Eleanor Jenkins',
      relation: 'Mother',
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDjYVUUFq-37pCqIkprzJW0Wx_HCEqZi_pojgtYHuNHCYORqQMkpq8kx73AXEQ4l2Ged06kqgnqvs1taHv0aOPp-Gx7Gi130wBUpJemTaMAdsSUQ1NhsZ-aKRql8JPedBEWE6r_vOGJXbJl6cCyIpS1DejAmz7zR7WJT2BEeTKFUktIDXG03Iu4fjF288S7lbkm_u0OAaGC9S-vss257hKUs-rGM5jAwtvQ2cEg0tXSTo_OaF4W8AbUXg',
      accessLevel: 'Emergency Contact Only',
      ageAndGender: '68 yrs • Female',
      shareVitals: true,
      shareLabReports: false,
      sharePrescriptions: false,
      emergencySosEnabled: true,
    ),
  ];

  void addFamilyMember(FamilyMember member) {
    familyMembers.add(member);
    notifyListeners();
  }

  void removeFamilyMember(String id) {
    familyMembers.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void updateFamilyPermission(String memberId, String permission, bool value) {
    final member = familyMembers.firstWhere((m) => m.id == memberId);
    switch (permission) {
      case 'vitals':
        member.shareVitals = value;
      case 'labs':
        member.shareLabReports = value;
      case 'prescriptions':
        member.sharePrescriptions = value;
      case 'sos':
        member.emergencySosEnabled = value;
    }
    notifyListeners();
  }

  // Diagnostic Reports
  late DiagnosticReport activeReport;

  AppState() {
    activeReport = DiagnosticReport(
      id: 'rep-cmp-1024',
      title: 'Comprehensive Metabolic Panel (CMP)',
      laboratory: 'Quest Diagnostics • Clinical Reference Lab',
      verifiedDoctor: 'Dr. Robert Chen, MD (Pathologist)',
      date: DateTime.now().subtract(const Duration(days: 2)),
      totalTested: 14,
      outOfRangeCount: 1,
      confidencePercentage: 99,
      overallSynthesis: 'ALT is mildly elevated at 65 U/L (Reference 7–56 U/L). All other 13 metabolic biomarkers (Electrolytes, Kidney Function, Fasting Glucose, Protein Synthesis) remain well within physiological baseline.',
      biomarkers: [
        const Biomarker(
          code: 'ALT',
          name: 'Alanine Aminotransferase',
          fullCategory: 'Liver Enzyme / Metabolic Activity',
          value: '65',
          unit: 'U/L',
          referenceRange: '7–56 U/L',
          status: BiomarkerStatus.elevated,
          isAttentionFlagged: true,
          trendText: '+12% since July test',
          plainSummary: 'This enzyme is primarily located in hepatocytes (liver cells). A mild elevation is commonly associated with recent intense strength training, metabolic clearance of medications, or temporary hepatic strain. It is not an immediate alarm but warrants routine follow-up with your physician.',
          clinicalContext: 'Mild isolated transaminitis. AST and Alkaline Phosphatase remain strictly normal, indicating absence of acute parenchymal injury.',
          historyTrend: [44.0, 48.0, 52.0, 58.0, 65.0],
        ),
        const Biomarker(
          code: 'GLU',
          name: 'Fasting Blood Glucose',
          fullCategory: 'Glycemic Regulation',
          value: '92',
          unit: 'mg/dL',
          referenceRange: '70–99 mg/dL',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Optimal baseline stability',
          plainSummary: 'Your fasting blood sugar is in the ideal healthy reference window, indicating excellent insulin sensitivity and stable glucose metabolism.',
          clinicalContext: 'Euglycemic fasting state without evidence of pre-diabetes or impaired fasting glucose.',
          historyTrend: [95.0, 94.0, 91.0, 93.0, 92.0],
        ),
        const Biomarker(
          code: 'CREAT',
          name: 'Serum Creatinine',
          fullCategory: 'Renal / Kidney Clearance',
          value: '0.88',
          unit: 'mg/dL',
          referenceRange: '0.50–1.10 mg/dL',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Stable renal clearance',
          plainSummary: 'Creatinine is a natural byproduct of muscle contraction filtered exclusively by the kidneys. Your level demonstrates pristine kidney filtration (eGFR > 90).',
          clinicalContext: 'Normal GFR estimation and intact nephron functional capacity.',
          historyTrend: [0.85, 0.86, 0.89, 0.87, 0.88],
        ),
        const Biomarker(
          code: 'eGFR',
          name: 'Estimated Glomerular Filtration',
          fullCategory: 'Renal Filtration Rate',
          value: '> 90',
          unit: 'mL/min/1.73m²',
          referenceRange: '> 60 mL/min',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Grade 1 Optimal',
          plainSummary: 'Your kidney filtration rate is functioning at maximum healthy capacity.',
          clinicalContext: 'No chronic kidney disease markers detected.',
          historyTrend: [94.0, 95.0, 93.0, 96.0, 95.0],
        ),
        const Biomarker(
          code: 'NA',
          name: 'Sodium Electrolyte',
          fullCategory: 'Fluid Balance & Homeostasis',
          value: '140',
          unit: 'mEq/L',
          referenceRange: '135–145 mEq/L',
          status: BiomarkerStatus.optimal,
          isAttentionFlagged: false,
          trendText: 'Balanced hydration',
          plainSummary: 'Sodium levels reflect balanced total body water distribution and proper nervous system signaling.',
          clinicalContext: 'Normonatremic status with adequate osmotic regulation.',
          historyTrend: [139.0, 141.0, 140.0, 139.0, 140.0],
        ),
      ],
      recommendedDoctorQuestions: [
        'Could my recent high-intensity strength training or supplements explain this mild ALT elevation?',
        'Do you recommend rechecking liver function enzymes in 8 to 12 weeks?',
        'Are there any specific dietary adjustments or hydration protocols you recommend in the interim?',
        'Should we check an ultrasound or additional lipid markers if ALT remains mildly high?',
      ],
    );

    activeTriage = TriageAssessment(
      id: 'tri-headache-01',
      userQuery: '“I\'ve had a dull headache behind my eyes since yesterday morning and mild neck stiffness after working on my laptop.”',
      timestamp: DateTime.fromMillisecondsSinceEpoch(1729760000000),
      urgency: TriageUrgency.moderate,
      urgencyBadge: 'SEE DOCTOR SOON',
      timeframeWindow: 'Window: 24–48 hrs',
      clinicalRationale: 'Moderate attention recommended within 24–48 hours if neck stiffness persists. Symptoms suggest potential postural tension strain or screen fatigue, but clinical evaluation is advised to rule out cervicogenic tension.',
      selfCareItems: [
        SelfCareGuidance(
          icon: Icons.water_drop_rounded,
          title: 'Hydration & Electrolytes',
          description: 'Drink 2.5L of mineral water and balanced electrolyte fluids throughout the day to prevent dehydrated vascular tension.',
        ),
        SelfCareGuidance(
          icon: Icons.screen_rotation_alt_rounded,
          title: 'Screen Micro-Breaks (20-20-20 Rule)',
          description: 'Every 20 minutes, look at an object 20 feet away for 20 seconds. Ensure monitor top edge aligns with eye height.',
        ),
        SelfCareGuidance(
          icon: Icons.ac_unit_rounded,
          title: 'Cold / Warm Neck Compress',
          description: 'Apply a soothing cold compress to forehead and gentle warm compress to cervical neck muscles for 15 minutes.',
        ),
        SelfCareGuidance(
          icon: Icons.self_improvement_rounded,
          title: 'Suboccipital Gentle Stretches',
          description: 'Gently tuck chin towards chest and hold for 10 seconds to decompress cervical spine compression.',
        ),
      ],
      redFlagAlerts: [
        'Sudden "thunderclap" headache reaching maximum intensity in seconds.',
        'High fever accompanied by inability to bend chin to chest.',
        'Sudden vision changes, confusion, weakness, or slurred speech.',
      ],
      recommendedSpecialty: 'Internal Medicine / Neurological Assessment',
      audioNarrationTranscript: 'Your symptoms show moderate signs of screen fatigue and neck postural tension. While non-emergency, schedule an evaluation within 48 hours if discomfort continues.',
    );
  }

  // Triage State
  late TriageAssessment activeTriage;
  bool isAudioPlaying = false;
  bool isListeningVoice = false;

  void toggleAudioPlayback() {
    isAudioPlaying = !isAudioPlaying;
    notifyListeners();
  }

  void setListeningVoice(bool listening) {
    isListeningVoice = listening;
    notifyListeners();
  }

  void submitNewSymptomTriage(String query) {
    // Generate new interactive triage assessment
    activeTriage = TriageAssessment(
      id: 'tri-${DateTime.now().millisecondsSinceEpoch}',
      userQuery: '“$query”',
      timestamp: DateTime.now(),
      urgency: query.toLowerCase().contains('chest') || query.toLowerCase().contains('breath')
          ? TriageUrgency.urgent
          : TriageUrgency.moderate,
      urgencyBadge: query.toLowerCase().contains('chest') || query.toLowerCase().contains('breath')
          ? 'URGENT EVALUATION'
          : 'MONITOR & CONSULT',
      timeframeWindow: query.toLowerCase().contains('chest') ? 'Immediate / Same Day' : 'Window: 24–48 hrs',
      clinicalRationale: 'Based on reported symptoms: "$query", automated clinical guidance recommends monitoring symptom evolution. No acute high-risk markers confirmed, but professional consultation provides highest safety assurance.',
      selfCareItems: [
        const SelfCareGuidance(
          icon: Icons.spa_rounded,
          title: 'Rest in Low-Stimulus Room',
          description: 'Rest comfortably in a dim, quiet room with optimal airflow and elevated head posture.',
        ),
        const SelfCareGuidance(
          icon: Icons.water_drop_rounded,
          title: 'Fluid & Nutrient Support',
          description: 'Sip warm herbal teas (chamomile or peppermint) and maintain balanced hydration.',
        ),
      ],
      redFlagAlerts: [
        'Difficulty breathing or sudden chest pressure.',
        'Uncontrollable vomiting or severe dizziness.',
        'Loss of consciousness or severe disorientation.',
      ],
      recommendedSpecialty: 'General Practice / Telehealth',
      audioNarrationTranscript: 'Assessment complete for your reported symptoms. Please review guidance and contact your physician if discomfort worsens.',
    );
    notifyListeners();
  }
}
