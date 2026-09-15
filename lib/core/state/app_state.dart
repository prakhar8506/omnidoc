import 'package:flutter/material.dart';
import '../models/vitals_data.dart';
import '../models/appointment.dart';
import '../models/biomarker_report.dart';
import '../models/triage_models.dart';
import '../models/family_member.dart';
import '../models/user_account.dart';
import '../models/prescription_document.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import '../services/report_interpreter_service.dart';
import '../theme/app_colors.dart';
import '../data/health_event.dart';
import '../data/event_store.dart';
import '../consent/consent_manager.dart';
import '../domains/baseline_engine.dart';
import '../domains/data_quality_service.dart';
import '../domains/recovery_model.dart';
import '../analytics/analytics_service.dart';
import '../network/supabase_repository.dart';
import '../data/supabase_sync_service.dart';
import '../../features/wearables/services/wearable_service.dart';

class AppState extends ChangeNotifier {
  final HealthBackendRepository supabaseRepository = SupabaseRepository();
  late final SupabaseSyncService supabaseSyncService = SupabaseSyncService(
    repository: supabaseRepository,
    eventStore: eventStore,
  );
  late final AuthService _auth = AuthService(backendRepository: supabaseRepository);
  final UserDataService _userData = UserDataService();

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;
  bool _isHydrating = true;
  bool get isHydrating => _isHydrating;

  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  String get userEmail => _currentUser?.email ?? '';
  String get userName => _currentUser?.fullName ?? 'Daria Jenkins';
  String get firstName {
    final parts = userName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Daria' : parts.first;
  }
  String get bloodType => _currentUser?.bloodType ?? 'O+';
  String get userAvatar => _currentUser?.avatarPath ?? '';
  String? get userId => _currentUser?.id;

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Daily Balance & Apple Reference Metrics
  int dailyBalanceScore = 78;
  String balanceStatus = 'Good balance';
  int stressHighest = 36;
  int stressLowest = 6;
  int stressAverage = 11;
  double stressPercentage = 0.0; // matching reference "0%"

  // Mood & Feeling Tracker (Matching Reference Screen 2)
  String selectedMood = 'Energetic';
  double moodProgress = 0.62; // angle along arc
  int feelingStep = 4;        // matching "4 of 8"
  final List<Map<String, dynamic>> feelingHistory = [];

  int unreadNotificationsCount = 0;
  int restingHeartRate = 72;
  int activeHeartRate = 114;
  int hrvMs = 58;
  String sleepDuration = '7h 10m';
  String deepSleep = '1h 45m';
  String remSleep = '2h 10m';
  String lightSleep = '3h 15m';
  double dailySteps = 8420;
  int bloodOxygen = 98;
  String bloodPressure = '118/76';
  bool isSyncingVitals = false;
  DateTime lastSyncedTime = DateTime.now().subtract(const Duration(minutes: 8));

  // --- Phase 0: Recovery OS Foundation ---
  final ConsentManager consentManager = ConsentManager();
  final EventStore eventStore = EventStore();
  final DataQualityService dataQualityService = DataQualityService();
  final AnalyticsService analytics = AnalyticsService();

  RecoveryScoreResult? recoveryResult;
  SleepScoreResult? sleepResult;
  LoadScoreResult? loadResult;
  StressScoreResult? stressResult;
  BaselineResult? hrvBaseline;
  BaselineResult? rhrBaseline;
  int historicalDaysCount = 14; // Default to mature baseline for Daria Jenkins demo

  // 1. Real Wearables State
  bool isWearableConnected = true;
  String wearableDeviceName = 'Apple Watch Series 9';
  String wearableSource = 'Apple HealthKit';
  bool isRealHardware = false;

  // 2. Nutrition & Hydration
  int dailyHydrationMl = 1850;
  int targetHydrationMl = 2500;
  final List<Map<String, dynamic>> loggedMeals = [
    {
      'id': 'meal-1',
      'title': 'Wild Salmon Bowl with Quinoa',
      'category': 'Lean Protein & Whole Grains',
      'time': '12:45 PM',
      'sodium': 'Moderate (420mg)',
      'insight': 'Anti-inflammatory omega-3 support for cardiovascular recovery.',
      'calories': '~540 kcal',
    },
    {
      'id': 'meal-2',
      'title': 'Greek Yogurt & Berries',
      'category': 'Fermented Dairy & Antioxidants',
      'time': '08:30 AM',
      'sodium': 'Low (90mg)',
      'insight': 'Gut microbiome diversity and cellular antioxidant load.',
      'calories': '~260 kcal',
    },
  ];

  // 3. Journal Reflections & Holistic Timeline (Part 2)
  final List<Map<String, dynamic>> journalEntries = [
    {
      'id': 'entry-1',
      'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
      'prompt': "What's on your mind today?",
      'content':
          'Morning sunlight walk and breathing exercises lowered my resting pulse to 64 bpm. Mind feels calm, clear, and energized for clinical work.',
      'mood': 'Calm',
      'audioRecorded': true,
      'photoPath': null,
      'tags': ['Mindfulness', 'Heart Rate', 'Morning'],
    },
    {
      'id': 'entry-2',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      'prompt': "What's one thing that went well today?",
      'content':
          'Completed 30 minutes of low-impact cycling. Rested well last night (7h 45m) and noticed no brain fog in the afternoon.',
      'mood': 'Energetic',
      'audioRecorded': false,
      'photoPath': null,
      'tags': ['Movement', 'Recovery', 'Sleep'],
    },
    {
      'id': 'entry-3',
      'timestamp': DateTime.now().subtract(const Duration(days: 3, hours: 6)),
      'prompt': 'Body scan & autonomic sensations',
      'content':
          'Felt slight neck tightness around 4 PM after long desk posture. Did 5 minutes of physiological sigh breathing which noticeably relaxed my shoulders.',
      'mood': 'Relaxed',
      'audioRecorded': false,
      'photoPath': null,
      'tags': ['Vagal Nerve', 'Posture'],
    },
  ];

  // 4. Women's Health & Menstrual Cycle Tracking (Part 3)
  bool isMenstrualTrackingEnabled = true;
  int cycleDay = 14;
  String cyclePhase = 'Ovulatory Phase';
  int averageCycleLength = 28;
  int averagePeriodDuration = 5;
  DateTime lastPeriodStartDate = DateTime.now().subtract(const Duration(days: 14));
  final List<String> cycleSymptoms = ['Mild Cramps', 'High Energy', 'Good Mood'];
  final List<Map<String, dynamic>> menstrualCycleLogs = [
    {
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'flow': 'Heavy',
      'symptoms': ['Cramps', 'Fatigue'],
      'notes': 'Day 1 of cycle',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 13)),
      'flow': 'Medium',
      'symptoms': ['Mild Cramps'],
      'notes': 'Restorative tea helped',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'flow': 'Light',
      'symptoms': ['High Energy'],
      'notes': 'Energy returning',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 11)),
      'flow': 'Spotting',
      'symptoms': ['Clear Mind'],
      'notes': 'Cycle ending',
    },
  ];

  // 5. Pregnancy Mode (Part 4)
  bool isPregnancyMode = false;
  DateTime pregnancyDueDate = DateTime.now().add(const Duration(days: 196)); // ~12 weeks in
  double prePregnancyWeightKg = 62.0;
  double currentPregnancyWeightKg = 64.8;
  final List<Map<String, dynamic>> pregnancyWeightLogs = [
    {
      'date': DateTime.now().subtract(const Duration(days: 28)),
      'weightKg': 62.5,
      'week': 8,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'weightKg': 63.8,
      'week': 10,
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'weightKg': 64.8,
      'week': 12,
    },
  ];
  final List<Map<String, dynamic>> kickCounterLogs = [
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'kicks': 10,
      'durationMinutes': 18,
      'status': 'Healthy active pattern',
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      'kicks': 10,
      'durationMinutes': 22,
      'status': 'Healthy active pattern',
    },
  ];
  final List<Map<String, dynamic>> prenatalScans = [
    {
      'id': 'scan-1',
      'title': 'First Trimester Dating & Viability Scan',
      'gestationalWeek': 'Week 8',
      'date': DateTime.now().subtract(const Duration(days: 28)),
      'findings': 'Single intrauterine gestational sac with fetal heart rate 158 bpm. Crown-rump length matches dates.',
      'doctorName': 'Dr. Elena Rostova, OB-GYN',
      'imagePath': null,
    },
    {
      'id': 'scan-2',
      'title': 'Nuchal Translucency & Early Anatomy',
      'gestationalWeek': 'Week 12',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'findings': 'Normal nuchal translucency (1.4 mm). Normal nasal bone present. Low risk profile.',
      'doctorName': 'Dr. Elena Rostova, OB-GYN',
      'imagePath': null,
    },
  ];

  // 6. Universal Smartwatch Recovery Engine (Part 6)
  int recoveryScore = 84; // 0-100%
  String recoveryStatus = 'Primed for Movement';
  double dailyStrainScore = 9.8; // 0-21 scale
  int sleepPerformanceScore = 88; // 0-100%

  // 7. Today's Movement & Fitness (Part 5)
  final List<Map<String, dynamic>> completedWorkouts = [
    {
      'id': 'wo-1',
      'title': 'Zone 2 Aerobic Jog',
      'category': 'Cardio',
      'duration': '32 min',
      'caloriesBurned': 240,
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'avgHr': 132,
    },
    {
      'id': 'wo-2',
      'title': 'Parasympathetic Yoga & Mobility',
      'category': 'Recovery',
      'duration': '20 min',
      'caloriesBurned': 65,
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'avgHr': 78,
    },
  ];

  final List<Map<String, dynamic>> curatedExerciseLibrary = const [
    {
      'id': 'ex-1',
      'title': 'Brisk Incline Walking',
      'category': 'Low Impact Cardio',
      'intensity': 'Moderate',
      'duration': '30-45 min',
      'targetHr': '115-130 bpm',
      'benefit': 'Promotes mitochondrial density without excessive central nervous fatigue.',
      'medicalWarning': null,
    },
    {
      'id': 'ex-2',
      'title': 'Functional Bodyweight Circuit',
      'category': 'Strength & Core',
      'intensity': 'Moderate-High',
      'duration': '25-35 min',
      'targetHr': '125-145 bpm',
      'benefit': 'Improves muscular endurance and stabilizes fasting glucose absorption.',
      'medicalWarning': 'Avoid heavy valsalva maneuvers if resting BP is elevated.',
    },
    {
      'id': 'ex-3',
      'title': 'Restorative Yin Yoga & Deep Breathing',
      'category': 'Autonomic Restoration',
      'intensity': 'Gentle',
      'duration': '20-30 min',
      'targetHr': '65-85 bpm',
      'benefit': 'Downregulates sympathetic nervous tone and elevates heart rate variability (HRV).',
      'medicalWarning': null,
    },
    {
      'id': 'ex-4',
      'title': 'Zone 2 Cycling Cadence',
      'category': 'Cardiovascular Base',
      'intensity': 'Moderate',
      'duration': '40 min',
      'targetHr': '120-135 bpm',
      'benefit': 'Builds capillary density and enhances lactate clearance efficiency.',
      'medicalWarning': null,
    },
  ];

  // 8. Onboarding Baseline Data (Part 7)
  double? userHeightCm = 170.0;
  double? userWeightKg = 63.5;
  String? baselineProgressPhotoPath;
  bool isOnboardingBaselineCompleted = true;

  // 4. Chronic Condition Companion (Diabetes & Hypertension)
  int bloodGlucoseMgDl = 102;
  String fastingStatus = 'Fasting (Morning)';
  final List<Map<String, dynamic>> glucoseHistory = [
    {'time': 'Today, 07:30 AM', 'val': 102, 'status': 'Fasting (Normal)'},
    {'time': 'Yesterday, 08:00 PM', 'val': 124, 'status': '2h Post-Prandial'},
    {'time': 'Yesterday, 07:45 AM', 'val': 98, 'status': 'Fasting (Normal)'},
  ];
  int systolicBp = 118;
  int diastolicBp = 76;
  final List<Map<String, dynamic>> bpHistory = [
    {'time': 'Today, 08:00 AM', 'sys': 118, 'dia': 76, 'category': 'Optimal (AHA)'},
    {'time': 'Yesterday, 06:30 PM', 'sys': 122, 'dia': 78, 'category': 'Normal (AHA)'},
    {'time': '2 days ago', 'sys': 116, 'dia': 74, 'category': 'Optimal (AHA)'},
  ];

  // 5. Preventive Care Engine
  final List<Map<String, dynamic>> preventiveReminders = [
    {
      'id': 'prev-1',
      'title': 'Comprehensive Metabolic Panel (CMP)',
      'due': 'Due in 2 weeks',
      'status': 'Scheduled with Dr. Priya Sharma',
      'guideline': 'USPSTF Hepatic & Lipid Guideline',
      'isDismissed': false,
    },
    {
      'id': 'prev-2',
      'title': 'Annual Influenza Vaccine',
      'due': 'Recommended Autumn 2026',
      'status': 'Eligible at local pharmacy',
      'guideline': 'CDC Immunization Schedule',
      'isDismissed': false,
    },
  ];

  // 6. Community & Neutral Health Gamification
  int medicationStreakDays = 18;
  int loggingStreakDays = 12;
  int stepStreakDays = 7;
  final List<Map<String, dynamic>> activeChallenges = [
    {
      'id': 'chal-1',
      'title': '7-Day Mindful Hydration',
      'metric': 'Daily 2,000ml logged',
      'progress': 0.85,
      'daysLeft': '2 days left',
      'participants': 'Daria, Elena, Jordan',
    },
    {
      'id': 'chal-2',
      'title': 'Weekend 10k Steps Walk',
      'metric': 'Total 20,000 weekend steps',
      'progress': 0.65,
      'daysLeft': 'Saturday start',
      'participants': 'Family Care Circle',
    },
  ];

  // 7. Insurance & Claims Tracking
  final List<Map<String, dynamic>> claims = [
    {
      'id': 'CLM-88410',
      'provider': 'BlueCross Platinum Health',
      'date': '02 Jan 2026',
      'service': 'Liver Panel & Hepatic Biomarkers',
      'billed': '\$380.00',
      'covered': '\$345.00',
      'patientPaid': '\$35.00',
      'status': 'Approved',
    },
    {
      'id': 'CLM-79124',
      'provider': 'BlueCross Platinum Health',
      'date': '18 Dec 2025',
      'service': 'Specialist Consultation (Dr. Priya Sharma)',
      'billed': '\$260.00',
      'covered': '\$240.00',
      'patientPaid': '\$20.00',
      'status': 'Processed',
    },
  ];

  // 8. Emergency Safety & Medical ID
  final List<String> allergies = ['Penicillin (Hives)', 'Sulfa Drugs'];
  final List<String> chronicConditions = ['Mild Hepatic Elevation (Under Observation)'];
  final List<String> emergencyMedications = ['CoQ10 100mg', 'Vitamin D3 2000 IU'];
  bool isFallDetectionActive = true;

  // 9. Multi-Language & Accessibility
  Locale currentLocale = const Locale('en');
  bool isLargeTextMode = false;

  final List<MedicationItem> medications = [];
  final List<Appointment> appointments = [];
  final List<FamilyMember> familyMembers = [];
  final List<PrescriptionDocument> prescriptions = [];

  int selectedDateIndex = DateTime.now().weekday - 1;
  int appointmentSegmentIndex = 0;

  DiagnosticReport? activeReport;
  late TriageAssessment activeTriage;
  bool isAudioPlaying = false;
  bool isListeningVoice = false;

  AppState() {
    activeTriage = _defaultTriage();
    seedDemoEvents(days: 14);
  }

  Future<void> hydrate() async {
    try {
      await supabaseRepository.initialize();
      await eventStore.initialize();
      final user = await _auth.getSessionUser();
      if (user != null) {
        await _bindUser(user);
        _isSignedIn = true;
        supabaseSyncService.syncPendingEvents(user.id);
      } else {
        _isSignedIn = false;
        _currentUser = null;
      }
    } catch (_) {
      _isSignedIn = false;
      _currentUser = null;
    } finally {
      _isHydrating = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String bloodType = 'O+',
  }) async {
    final user = await _auth.register(
      fullName: fullName,
      email: email,
      password: password,
      bloodType: bloodType,
    );
    await _bindUser(user, isNew: true);
    _isSignedIn = true;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final user = await _auth.signIn(email: email, password: password);
    await _bindUser(user);
    _isSignedIn = true;
    notifyListeners();
  }

  /// Instant One-Tap Demo Access with Daria Jenkins (matching reference mockups)
  Future<void> signInDemoAccount() async {
    _isHydrating = true;
    notifyListeners();

    final existing = await _auth.findByEmail('daria.jenkins@icloud.com');
    UserAccount demoUser;
    if (existing != null) {
      demoUser = existing;
    } else {
      try {
        demoUser = await _auth.register(
          fullName: 'Daria Jenkins',
          email: 'daria.jenkins@icloud.com',
          password: 'password123',
          bloodType: 'O+',
        );
      } catch (_) {
        demoUser = (await _auth.findByEmail('daria.jenkins@icloud.com'))!;
      }
    }

    await _bindUser(demoUser);
    _ensureRichSeedData();
    await _persistCurrentUserData();

    _isSignedIn = true;
    _isHydrating = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _persistCurrentUserData();
    await _auth.signOut();
    _isSignedIn = false;
    _currentUser = null;
    _currentTabIndex = 0;
    _resetInMemoryProfile();
    notifyListeners();
  }

  Future<void> _bindUser(UserAccount user, {bool isNew = false}) async {
    _currentUser = user;
    _resetInMemoryProfile();
    activeTriage = _defaultTriage();

    if (isNew) {
      if (user.email == 'daria.jenkins@icloud.com') {
        _ensureRichSeedData();
      }
      await _persistCurrentUserData();
      return;
    }

    final data = await _userData.load(user.id);
    restingHeartRate = data['restingHeartRate'] as int? ?? 72;
    sleepDuration = data['sleepDuration'] as String? ?? '7h 10m';
    dailySteps = (data['dailySteps'] as num?)?.toDouble() ?? 8420;
    bloodOxygen = data['bloodOxygen'] as int? ?? 98;
    bloodPressure = data['bloodPressure'] as String? ?? '118/76';
    dailyBalanceScore = data['dailyBalanceScore'] as int? ?? 78;
    selectedMood = data['selectedMood'] as String? ?? 'Energetic';
    moodProgress = (data['moodProgress'] as num?)?.toDouble() ?? 0.62;
    feelingStep = data['feelingStep'] as int? ?? 4;
    lastSyncedTime =
        DateTime.tryParse(data['lastSyncedTime'] as String? ?? '') ?? DateTime.now().subtract(const Duration(minutes: 8));
    unreadNotificationsCount = data['unreadNotificationsCount'] as int? ?? 0;

    medications
      ..clear()
      ..addAll(UserDataService.medicationsFromJson(data['medications'] as List<dynamic>?));

    appointments
      ..clear()
      ..addAll(
        (data['appointments'] as List<dynamic>? ?? [])
            .map((e) => Appointment.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    familyMembers
      ..clear()
      ..addAll(
        (data['familyMembers'] as List<dynamic>? ?? [])
            .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e as Map))),
      );

    prescriptions
      ..clear()
      ..addAll(UserDataService.prescriptionsFromJson(data['prescriptions'] as List<dynamic>?));

    if (prescriptions.isNotEmpty) {
      activeReport =
          ReportInterpreterService.labReportFromPrescription(prescriptions.first);
    } else {
      activeReport = null;
    }

    if (user.email == 'daria.jenkins@icloud.com' && appointments.isEmpty && prescriptions.isEmpty) {
      _ensureRichSeedData();
    }
  }

  void _ensureRichSeedData() {
    if (appointments.isEmpty) {
      appointments.add(
        Appointment(
          id: 'apt-seed-1',
          doctorName: 'Dr. Priya Sharma, MD',
          doctorTitle: 'Internal Medicine & Hepatology',
          specialty: 'Internal Medicine',
          avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
          dateTime: DateTime.now().add(const Duration(days: 1, hours: 4)),
          clinicName: 'Metro Health Pavilion • Suite 300',
          roomOrType: 'In-Person Consultation',
          isVideoConsult: false,
          status: 'Confirmed',
          preparationNote: 'Follow-up regarding hepatic panel and supplement regime.',
          themeColor: AppColors.primaryContainer,
        ),
      );
    }

    if (medications.isEmpty) {
      medications.addAll([
        MedicationItem(
          id: 'med-1',
          name: 'CoQ10 Ubiquinol',
          dosage: '100mg',
          scheduleTime: '08:00 AM with food',
          instruction: 'Cellular energy and cardiac recovery',
          isTaken: true,
        ),
        MedicationItem(
          id: 'med-2',
          name: 'Magnesium Glycinate',
          dosage: '200mg',
          scheduleTime: '09:30 PM before sleep',
          instruction: 'Muscle recovery & deep REM sleep support',
          isTaken: false,
        ),
      ]);
    }

    if (familyMembers.isEmpty) {
      familyMembers.addAll([
        FamilyMember(
          id: 'fam-1',
          name: 'Elena Jenkins',
          relation: 'Sister',
          avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=300',
          accessLevel: 'Full Access',
          ageAndGender: '28, Female',
          shareVitals: true,
          shareLabReports: true,
          sharePrescriptions: false,
          emergencySosEnabled: true,
        ),
        FamilyMember(
          id: 'fam-2',
          name: 'Robert Jenkins',
          relation: 'Father',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=300',
          accessLevel: 'Emergency Contact',
          ageAndGender: '62, Male',
          shareVitals: true,
          shareLabReports: false,
          sharePrescriptions: false,
          emergencySosEnabled: true,
        ),
      ]);
    }

    if (prescriptions.isEmpty) {
      final doc = PrescriptionDocument(
        id: 'doc-seed-1',
        fileName: 'Comprehensive_Metabolic_Panel.pdf',
        localPath: '',
        source: PrescriptionSource.files,
        docType: PrescriptionDocType.labReport,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        plainLanguageSummary:
            'Liver ALT is slightly elevated at 48 U/L (ref: 7–35 U/L). Hydration, reducing NSAIDs, and discussing with Dr. Priya Sharma is advised.',
        detailedExplanation:
            'Alanine Aminotransferase (ALT) is an enzyme primarily found in liver cells. An elevated value indicates mild liver cell stress or inflammation, often related to strenuous training, medications, or metabolic factors.',
        keyFindings: const [
          'ALT: 48 U/L (Elevated above standard 35 U/L cutoff)',
          'Fasting Glucose: 92 mg/dL (Normal)',
          'Serum Creatinine: 0.9 mg/dL (Optimal renal clearance)',
        ],
        doctorQuestions: const [
          'Could intense weightlifting or running explain this mild elevation?',
          'Should I temporarily discontinue fat-soluble supplements?',
          'Do we need a follow-up hepatic re-test in 4 to 6 weeks?',
        ],
        isImage: false,
      );
      prescriptions.add(doc);
      activeReport = ReportInterpreterService.labReportFromPrescription(doc);
    }
  }

  void _resetInMemoryProfile() {
    unreadNotificationsCount = 0;
    restingHeartRate = 72;
    sleepDuration = '7h 10m';
    dailySteps = 8420;
    bloodOxygen = 98;
    bloodPressure = '118/76';
    dailyBalanceScore = 78;
    selectedMood = 'Energetic';
    moodProgress = 0.62;
    feelingStep = 4;
    lastSyncedTime = DateTime.now().subtract(const Duration(minutes: 8));
    medications.clear();
    appointments.clear();
    familyMembers.clear();
    prescriptions.clear();
    activeReport = null;
    appointmentSegmentIndex = 0;
    selectedDateIndex = DateTime.now().weekday - 1;
  }

  Future<void> _persistCurrentUserData() async {
    final id = _currentUser?.id;
    if (id == null) return;
    await _userData.save(id, {
      'restingHeartRate': restingHeartRate,
      'sleepDuration': sleepDuration,
      'dailySteps': dailySteps,
      'bloodOxygen': bloodOxygen,
      'bloodPressure': bloodPressure,
      'dailyBalanceScore': dailyBalanceScore,
      'selectedMood': selectedMood,
      'moodProgress': moodProgress,
      'feelingStep': feelingStep,
      'lastSyncedTime': lastSyncedTime.toIso8601String(),
      'unreadNotificationsCount': unreadNotificationsCount,
      'medications': UserDataService.medicationsToJson(medications),
      'appointments': appointments.map((a) => a.toJson()).toList(),
      'familyMembers': familyMembers.map((f) => f.toJson()).toList(),
      'prescriptions': UserDataService.prescriptionsToJson(prescriptions),
      'hasActiveReport': activeReport != null,
    });
  }

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void setMood(String mood, double progress) {
    selectedMood = mood;
    moodProgress = progress;
    _recalculateBalance();
    _persistCurrentUserData();
    notifyListeners();
  }

  void logFeeling({required String mood, required int step}) {
    selectedMood = mood;
    feelingStep = step;
    feelingHistory.insert(0, {
      'timestamp': DateTime.now(),
      'mood': mood,
      'step': step,
    });
    _recalculateBalance();
    _persistCurrentUserData();
    notifyListeners();
  }

  // --- PART 2: Journal Methods & Holistic Correlations ---
  void addJournalEntry({
    required String content,
    String? prompt,
    String? mood,
    String? photoPath,
    bool audioRecorded = false,
    List<String>? tags,
  }) {
    final entry = {
      'id': 'entry-${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now(),
      'prompt': prompt ?? "What's on your mind today?",
      'content': content,
      'mood': mood ?? selectedMood,
      'photoPath': photoPath,
      'audioRecorded': audioRecorded,
      'tags': tags ?? ['Reflection', mood ?? selectedMood],
    };
    journalEntries.insert(0, entry);
    if (mood != null) {
      selectedMood = mood;
    }
    _recalculateBalance();
    _persistCurrentUserData();
    notifyListeners();
  }

  void deleteJournalEntry(String id) {
    journalEntries.removeWhere((e) => e['id'] == id);
    notifyListeners();
  }

  List<Map<String, dynamic>> getJournalCorrelations() {
    return [
      {
        'title': 'Sleep & Mood Harmony',
        'metric': '7h 45m Restful Sleep',
        'insight':
            'When sleep duration exceeds 7.5 hours, your daily mood score averages "Energetic" with optimal HRV (58ms).',
        'icon': Icons.bedtime_rounded,
        'color': const Color(0xFF818CF8),
      },
      {
        'title': 'Autonomic Stability',
        'metric': '64 bpm Resting Pulse',
        'insight':
            'Days logged as "Calm" or "Relaxed" show a 5 bpm lower resting heart rate and stable cardiovascular load.',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF38BDF8),
      },
      {
        'title': 'Cycle Phase Vitality',
        'metric': 'Ovulatory Phase (Day 14)',
        'insight':
            'Peak estrogen levels correlate with high cognitive clarity and increased natural physical endurance.',
        'icon': Icons.flare_rounded,
        'color': const Color(0xFFFB7185),
      },
    ];
  }

  // --- PART 3: Menstrual Cycle Tracking Methods ---
  void toggleMenstrualTracking(bool enabled) {
    isMenstrualTrackingEnabled = enabled;
    notifyListeners();
  }

  DateTime get predictedNextPeriod =>
      lastPeriodStartDate.add(Duration(days: averageCycleLength));

  DateTime get predictedOvulationDate =>
      lastPeriodStartDate.add(Duration(days: (averageCycleLength / 2).round()));

  void logPeriodDay({
    required DateTime date,
    required String flow,
    List<String> symptoms = const [],
    String notes = '',
  }) {
    menstrualCycleLogs.insert(0, {
      'date': date,
      'flow': flow,
      'symptoms': symptoms,
      'notes': notes,
    });
    lastPeriodStartDate = date;
    cycleDay = 1;
    cyclePhase = 'Menstrual Phase';
    notifyListeners();
  }

  // --- PART 4: Pregnancy Mode Methods ---
  void setPregnancyMode(bool enabled) {
    isPregnancyMode = enabled;
    _persistCurrentUserData();
    notifyListeners();
  }

  void setPregnancyDueDate(DateTime date) {
    pregnancyDueDate = date;
    notifyListeners();
  }

  int get gestationalWeeks {
    final conceptionEst = pregnancyDueDate.subtract(const Duration(days: 280));
    final daysPassed = DateTime.now().difference(conceptionEst).inDays;
    return (daysPassed / 7).floor().clamp(1, 42);
  }

  int get gestationalDaysRemainder {
    final conceptionEst = pregnancyDueDate.subtract(const Duration(days: 280));
    final daysPassed = DateTime.now().difference(conceptionEst).inDays;
    return (daysPassed % 7).clamp(0, 6);
  }

  String get pregnancyTrimester {
    final weeks = gestationalWeeks;
    if (weeks <= 13) return '1st Trimester';
    if (weeks <= 26) return '2nd Trimester';
    return '3rd Trimester';
  }

  Map<String, dynamic> get currentBabyDevelopment {
    final week = gestationalWeeks;
    if (week <= 8) {
      return {
        'sizeComparison': 'Raspberry (~1.6 cm)',
        'milestone': 'Baby is forming tiny fingers and toes. The heart is beating at around 150 bpm.',
        'careAdvice': 'Continue prenatal vitamins with folate. Stay hydrated to mitigate mild nausea.',
      };
    } else if (week <= 14) {
      return {
        'sizeComparison': 'Lime (~5.4 cm)',
        'milestone': "Baby's vocal cords and reflexes are developing. Fingers can curl and toes can wiggle.",
        'careAdvice': 'Energy typically improves heading into the second trimester. Great time for gentle walking.',
      };
    } else if (week <= 20) {
      return {
        'sizeComparison': 'Banana (~16.4 cm)',
        'milestone': 'Baby can hear muffled sounds from the outside world. Sleep and wake cycles are beginning.',
        'careAdvice': 'Anatomy ultrasound scan is scheduled around week 20 to review organ development.',
      };
    } else {
      return {
        'sizeComparison': 'Eggplant (~28 cm)',
        'milestone': 'Lungs and brain are maturing rapidly. Baby is active with perceptible kick routines.',
        'careAdvice': 'Track daily kick counts when resting on your side.',
      };
    }
  }

  void logPregnancyWeight(double weightKg) {
    currentPregnancyWeightKg = weightKg;
    pregnancyWeightLogs.insert(0, {
      'date': DateTime.now(),
      'weightKg': weightKg,
      'week': gestationalWeeks,
    });
    notifyListeners();
  }

  void logKickSession({required int kicks, required int durationMinutes}) {
    kickCounterLogs.insert(0, {
      'timestamp': DateTime.now(),
      'kicks': kicks,
      'durationMinutes': durationMinutes,
      'status': kicks >= 10 ? 'Optimal active movement' : 'Continue observation',
    });
    notifyListeners();
  }

  void addPrenatalScan({
    required String title,
    required String gestationalWeek,
    required String findings,
    required String doctorName,
    String? imagePath,
  }) {
    prenatalScans.insert(0, {
      'id': 'scan-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'gestationalWeek': gestationalWeek,
      'date': DateTime.now(),
      'findings': findings,
      'doctorName': doctorName,
      'imagePath': imagePath,
    });
    notifyListeners();
  }

  // --- Phase 0: Recovery OS Scoring & Baseline Engine ---
  void recalculateRecoveryEngine() {
    // 1. Compute Baselines from stored HealthEvents
    final hrvEvents = eventStore.getEventsForMetric('heart_rate_variability');
    final rhrEvents = eventStore.getEventsForMetric('resting_heart_rate');

    hrvBaseline = BaselineEngine.computeBaseline('heart_rate_variability', hrvEvents);
    rhrBaseline = BaselineEngine.computeBaseline('resting_heart_rate', rhrEvents);

    // 2. Evaluate Data Quality & Sensor Coverage
    final qualityResult = dataQualityService.computeDataQuality(
      consentManager,
      recentEvents: eventStore.getAllEvents(),
      totalHistoricalDays: historicalDaysCount,
    );

    // Parse sleep duration into hours
    double sleepHours = 7.17; // default 7h 10m
    try {
      final parts = sleepDuration.split(' ');
      final h = double.tryParse(parts[0].replaceAll('h', '')) ?? 7.0;
      final m = parts.length > 1 ? (double.tryParse(parts[1].replaceAll('m', '')) ?? 10.0) : 0.0;
      sleepHours = h + (m / 60.0);
    } catch (_) {}

    // 3. Compute Recovery v0 Score
    recoveryResult = RecoveryModel.computeRecovery(
      todayHrv: consentManager.isCategoryEnabled(PermissionCategory.hrv) ? hrvMs.toDouble() : null,
      todayRestingHr: consentManager.isCategoryEnabled(PermissionCategory.heartRate) ? restingHeartRate.toDouble() : null,
      todaySleepHours: consentManager.isCategoryEnabled(PermissionCategory.sleep) ? sleepHours : null,
      todayRespiratoryRate: consentManager.isCategoryEnabled(PermissionCategory.respiratoryRate) ? 14.5 : null,
      subjectiveFeeling: selectedMood,
      hrvBaseline: hrvBaseline!,
      rhrBaseline: rhrBaseline!,
      totalHistoricalDays: historicalDaysCount,
      baselineConfidence: qualityResult.confidence,
    );

    // 4. Compute Sleep Score
    sleepResult = RecoveryModel.computeSleep(
      sleepHours: consentManager.isCategoryEnabled(PermissionCategory.sleep) ? sleepHours : null,
      consistencyPercentage: 88.0,
      validNightsCount: historicalDaysCount,
    );

    // 5. Compute Adaptive Load Target
    dailyStrainScore = (dailySteps / 900).clamp(3.0, 18.5);
    loadResult = RecoveryModel.computeLoadTarget(
      recoveryScore: recoveryResult!.score,
      currentStrain: dailyStrainScore,
    );

    // 6. Compute Physiological Stress
    stressResult = RecoveryModel.computeStress(
      hrvZScore: hrvBaseline?.computeZScore(hrvMs.toDouble()),
      rhrZScore: rhrBaseline?.computeZScore(restingHeartRate.toDouble()),
      hasSensorCoverage: consentManager.isCategoryEnabled(PermissionCategory.hrv),
    );

    // Synchronize legacy variables for backward-compatibility
    recoveryScore = recoveryResult!.score;
    recoveryStatus = recoveryResult!.readinessState;
    dailyBalanceScore = recoveryScore;
    balanceStatus = recoveryResult!.readinessState;

    analytics.logScoreViewed(
      scoreType: 'recovery',
      confidence: recoveryResult!.confidence.name,
    );

    notifyListeners();
  }

  void onPermissionToggled(PermissionCategory category, bool isEnabled) {
    analytics.logPermissionToggled(category: category.name, isEnabled: isEnabled);
    recalculateRecoveryEngine();
    notifyListeners();
  }

  void seedDemoEvents({int days = 14}) {
    historicalDaysCount = days;
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i + 1));
      eventStore.recordEvent(HealthEvent(
        metric: 'heart_rate_variability',
        value: 58.0 + (i % 5) * 2.0 - (i % 3) * 1.5,
        unit: 'ms',
        start: day,
        end: day.add(const Duration(hours: 8)),
        source: 'healthkit',
        sourceRecordId: 'demo-hrv-$i',
        quality: 0.95,
      ));
      eventStore.recordEvent(HealthEvent(
        metric: 'resting_heart_rate',
        value: 58.0 + (i % 4) * 1.5 - (i % 2) * 2.0,
        unit: 'bpm',
        start: day,
        end: day.add(const Duration(hours: 8)),
        source: 'healthkit',
        sourceRecordId: 'demo-rhr-$i',
        quality: 0.95,
      ));
    }
    recalculateRecoveryEngine();
  }

  Map<String, dynamic> getTodaysMovementSuggestion() {
    if (recoveryScore >= 75) {
      return {
        'title': 'Zone 2 Cardio & Steady State',
        'subtitle': 'Optimal for Endurance & Mitochondria',
        'recommendedDuration': '35-45 min',
        'intensity': 'Moderate Aerobic (HR 120-135 bpm)',
        'reasoning':
            'Your Recovery Score is high ($recoveryScore%) with an elevated HRV ($hrvMs ms) and resting pulse of $restingHeartRate bpm. Your autonomic system is primed for aerobic adaptation without overtraining risk.',
        'exerciseId': 'ex-1',
        'caution': null,
      };
    } else if (recoveryScore >= 55) {
      return {
        'title': 'Brisk Walking & Mobility Flow',
        'subtitle': 'Active Recovery & Circulation',
        'recommendedDuration': '25-30 min',
        'intensity': 'Low Impact (HR 100-115 bpm)',
        'reasoning':
            'Moderate recovery ($recoveryScore%). A low-intensity walk supports venous blood flow, lymphatic drainage, and gentle stress relief without taxing glycogen reserves.',
        'exerciseId': 'ex-1',
        'caution': null,
      };
    } else {
      return {
        'title': 'Restorative Yoga & Breathwork',
        'subtitle': 'Parasympathetic Nervous Recharge',
        'recommendedDuration': '15-20 min',
        'intensity': 'Gentle / Restorative',
        'reasoning':
            'Recovery Score is lower ($recoveryScore%). Prioritizing parasympathetic tone with diaphragmatic breathing and gentle yoga will restore neuromuscular readiness.',
        'exerciseId': 'ex-3',
        'caution': 'Avoid high-intensity sprints or heavy loading today.',
      };
    }
  }

  void logWorkout({
    required String title,
    required String category,
    required String duration,
    required int caloriesBurned,
    int? avgHr,
  }) {
    completedWorkouts.insert(0, {
      'id': 'wo-${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'category': category,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'timestamp': DateTime.now(),
      'avgHr': avgHr ?? activeHeartRate,
    });
    recalculateRecoveryEngine();
    _recalculateBalance();
    notifyListeners();
  }

  // --- PART 7: Onboarding Baseline Data ---
  void saveBaselineData({
    double? heightCm,
    double? weightKg,
    String? photoPath,
  }) {
    if (heightCm != null) userHeightCm = heightCm;
    if (weightKg != null) userWeightKg = weightKg;
    if (photoPath != null) baselineProgressPhotoPath = photoPath;
    isOnboardingBaselineCompleted = true;
    notifyListeners();
  }

  void _recalculateBalance() {
    recalculateRecoveryEngine();
  }

  void clearNotifications() {
    unreadNotificationsCount = 0;
    _persistCurrentUserData();
    notifyListeners();
  }

  Future<void> syncVitals() async {
    isSyncingVitals = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));

    final events = await WearableService.ingestEvents(consentManager: consentManager);
    await eventStore.recordEvents(events);
    if (userId != null) {
      supabaseSyncService.syncPendingEvents(userId!);
    }

    restingHeartRate = 70 + (dailySteps.toInt() % 4);
    dailySteps += 350;
    sleepDuration = '7h 45m';
    bloodPressure = '116/74';
    lastSyncedTime = DateTime.now();
    isSyncingVitals = false;
    recalculateRecoveryEngine();
    await _persistCurrentUserData();
    notifyListeners();
  }

  void toggleMedication(String id) {
    final med = medications.firstWhere((m) => m.id == id);
    med.isTaken = !med.isTaken;
    _persistCurrentUserData();
    notifyListeners();
  }

  void setAppointmentSegment(int index) {
    appointmentSegmentIndex = index;
    notifyListeners();
  }

  void setSelectedDateIndex(int index) {
    selectedDateIndex = index;
    notifyListeners();
  }

  void addAppointment(Appointment appt) {
    appointments.insert(0, appt);
    unreadNotificationsCount += 1;
    _persistCurrentUserData();
    notifyListeners();
  }

  void cancelAppointment(String id) {
    appointments.removeWhere((a) => a.id == id);
    _persistCurrentUserData();
    notifyListeners();
  }

  void addFamilyMember(FamilyMember member) {
    familyMembers.add(member);
    _persistCurrentUserData();
    notifyListeners();
  }

  void removeFamilyMember(String id) {
    familyMembers.removeWhere((m) => m.id == id);
    _persistCurrentUserData();
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
    _persistCurrentUserData();
    notifyListeners();
  }

  Future<PrescriptionDocument> uploadHealthDocument({
    required String sourcePath,
    required String originalName,
    required PrescriptionSource source,
    required bool isImage,
  }) async {
    final id = userId;
    if (id == null) {
      throw StateError('You must be signed in to upload documents.');
    }

    final localPath = await ReportInterpreterService.persistPickedFile(
      userId: id,
      sourcePath: sourcePath,
      originalName: originalName,
    );

    final doc = ReportInterpreterService.interpretUpload(
      fileName: originalName,
      localPath: localPath,
      source: source,
      isImage: isImage,
    );

    prescriptions.insert(0, doc);
    activeReport = ReportInterpreterService.labReportFromPrescription(doc);
    unreadNotificationsCount += 1;
    await _persistCurrentUserData();
    notifyListeners();
    return doc;
  }

  void toggleAudioPlayback() {
    isAudioPlaying = !isAudioPlaying;
    notifyListeners();
  }

  void setListeningVoice(bool listening) {
    isListeningVoice = listening;
    notifyListeners();
  }

  void submitNewSymptomTriage(String query) {
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
      timeframeWindow:
          query.toLowerCase().contains('chest') ? 'Immediate / Same Day' : 'Window: 24–48 hrs',
      clinicalRationale:
          'Based on reported symptoms: "$query", automated clinical guidance recommends monitoring symptom evolution. No acute high-risk markers confirmed, but professional consultation provides highest safety assurance.',
      selfCareItems: const [
        SelfCareGuidance(
          icon: Icons.spa_rounded,
          title: 'Rest in Low-Stimulus Room',
          description:
              'Rest comfortably in a dim, quiet room with optimal airflow and elevated head posture.',
        ),
        SelfCareGuidance(
          icon: Icons.water_drop_rounded,
          title: 'Fluid & Nutrient Support',
          description: 'Sip warm herbal teas (chamomile or peppermint) and maintain balanced hydration.',
        ),
      ],
      redFlagAlerts: const [
        'Difficulty breathing or sudden chest pressure.',
        'Uncontrollable vomiting or severe dizziness.',
        'Loss of consciousness or severe disorientation.',
      ],
      recommendedSpecialty: 'General Practice / Telehealth',
      audioNarrationTranscript:
          'Assessment complete for your reported symptoms. Please review guidance and contact your physician if discomfort worsens.',
    );
    notifyListeners();
  }

  TriageAssessment _defaultTriage() {
    return TriageAssessment(
      id: 'tri-welcome',
      userQuery: '“Describe how you feel to get personalized self-care guidance.”',
      timestamp: DateTime.now(),
      urgency: TriageUrgency.low,
      urgencyBadge: 'READY WHEN YOU ARE',
      timeframeWindow: 'On demand',
      clinicalRationale:
          'No active triage yet. Enter symptoms below for guidance. This is not a substitute for emergency care.',
      selfCareItems: const [
        SelfCareGuidance(
          icon: Icons.favorite_outline_rounded,
          title: 'Start with how you feel',
          description: 'Use plain language — headache, fever, cough, dizziness, etc.',
        ),
      ],
      redFlagAlerts: const [
        'Call emergency services for chest pain, severe breathing trouble, or sudden weakness.',
      ],
      recommendedSpecialty: 'General Practice',
      audioNarrationTranscript: 'Welcome. Describe your symptoms to begin triage.',
    );
  }

  // 1. Wearables Actions
  void connectWearable(String deviceName, String source) {
    isWearableConnected = true;
    wearableDeviceName = deviceName;
    wearableSource = source;
    lastSyncedTime = DateTime.now();
    _persistCurrentUserData();
    notifyListeners();
  }

  void disconnectWearable() {
    isWearableConnected = false;
    _persistCurrentUserData();
    notifyListeners();
  }

  // 2. Nutrition & Hydration Actions
  void addHydration(int ml) {
    dailyHydrationMl = (dailyHydrationMl + ml).clamp(0, 5000);
    _persistCurrentUserData();
    notifyListeners();
  }

  void addMeal(Map<String, dynamic> meal) {
    loggedMeals.insert(0, meal);
    _persistCurrentUserData();
    notifyListeners();
  }

  // 3. Women's Health Actions
  void logCycleSymptom(String symptom) {
    if (!cycleSymptoms.contains(symptom)) {
      cycleSymptoms.add(symptom);
    } else {
      cycleSymptoms.remove(symptom);
    }
    _persistCurrentUserData();
    notifyListeners();
  }

  void togglePregnancyMode() {
    isPregnancyMode = !isPregnancyMode;
    _persistCurrentUserData();
    notifyListeners();
  }

  // 4. Chronic Care Actions
  void logGlucose(int mgDl, String status) {
    bloodGlucoseMgDl = mgDl;
    fastingStatus = status;
    glucoseHistory.insert(0, {
      'time': 'Just now',
      'val': mgDl,
      'status': status,
    });
    _persistCurrentUserData();
    notifyListeners();
  }

  void logBloodPressure(int sys, int dia) {
    systolicBp = sys;
    diastolicBp = dia;
    bloodPressure = '$sys/$dia';
    bpHistory.insert(0, {
      'time': 'Just now',
      'sys': sys,
      'dia': dia,
      'category': sys < 120 && dia < 80 ? 'Optimal (AHA)' : 'Elevated (AHA)',
    });
    _persistCurrentUserData();
    notifyListeners();
  }

  // 5. Preventive Care Actions
  void dismissPreventiveReminder(String id) {
    final idx = preventiveReminders.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      preventiveReminders[idx]['isDismissed'] = true;
      _persistCurrentUserData();
      notifyListeners();
    }
  }

  // 6. Community Actions
  void joinChallenge(String id) {
    notifyListeners();
  }

  // 7. Insurance Claims Actions
  void submitClaim(Map<String, dynamic> claim) {
    claims.insert(0, claim);
    _persistCurrentUserData();
    notifyListeners();
  }

  // 8. Emergency Safety Actions
  void toggleFallDetection() {
    isFallDetectionActive = !isFallDetectionActive;
    _persistCurrentUserData();
    notifyListeners();
  }

  // 9. Accessibility & Localization Actions
  void toggleLocale() {
    currentLocale = currentLocale.languageCode == 'en' ? const Locale('hi') : const Locale('en');
    notifyListeners();
  }

  void toggleLargeTextMode() {
    isLargeTextMode = !isLargeTextMode;
    notifyListeners();
  }
}
