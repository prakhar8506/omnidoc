import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
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
import '../env/app_env.dart';
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
  String get userName => _currentUser?.fullName ?? '';
  String get firstName {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'there';
    return parts.first;
  }
  String get bloodType => _currentUser?.bloodType ?? 'Unknown';
  String get userAvatar => _currentUser?.avatarPath ?? '';
  String? get userId => _currentUser?.id;
  bool get hasVitalsData =>
      isWearableConnected && (restingHeartRate > 0 || dailySteps > 0 || hrvMs > 0);

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  // Daily Balance — empty until real wearable / user data exists
  int dailyBalanceScore = 0;
  String balanceStatus = 'Connect a wearable to begin';
  int stressHighest = 0;
  int stressLowest = 0;
  int stressAverage = 0;
  double stressPercentage = 0.0;

  // Mood & Feeling Tracker
  String selectedMood = '';
  double moodProgress = 0.0;
  int feelingStep = 1;
  final List<Map<String, dynamic>> feelingHistory = [];

  int unreadNotificationsCount = 0;
  int restingHeartRate = 0;
  int activeHeartRate = 0;
  int hrvMs = 0;
  String sleepDuration = '—';
  String deepSleep = '—';
  String remSleep = '—';
  String lightSleep = '—';
  double dailySteps = 0;
  int bloodOxygen = 0;
  String bloodPressure = '—';
  bool isSyncingVitals = false;
  DateTime? lastSyncedTime;
  String lastSyncMessage = '';

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
  int historicalDaysCount = 0;

  // 1. Wearables — disconnected until user grants Health permissions
  bool isWearableConnected = false;
  String wearableDeviceName = '';
  String wearableSource = '';
  bool isRealHardware = false;

  // 2. Nutrition & Hydration
  int dailyHydrationMl = 0;
  int targetHydrationMl = 2500;
  final List<Map<String, dynamic>> loggedMeals = [];

  // 3. Journal
  final List<Map<String, dynamic>> journalEntries = [];

  // 4. Women's Health
  bool isMenstrualTrackingEnabled = false;
  int cycleDay = 0;
  String cyclePhase = 'Not tracking';
  int averageCycleLength = 28;
  int averagePeriodDuration = 5;
  DateTime lastPeriodStartDate = DateTime.now();
  final List<String> cycleSymptoms = [];
  final List<Map<String, dynamic>> menstrualCycleLogs = [];

  // 5. Pregnancy Mode
  bool isPregnancyMode = false;
  DateTime? pregnancyDueDate;
  double prePregnancyWeightKg = 0;
  double currentPregnancyWeightKg = 0;
  final List<Map<String, dynamic>> pregnancyWeightLogs = [];
  final List<Map<String, dynamic>> kickCounterLogs = [];
  final List<Map<String, dynamic>> prenatalScans = [];

  // 6. Recovery Engine
  int recoveryScore = 0;
  String recoveryStatus = 'Insufficient data';
  double dailyStrainScore = 0;
  int sleepPerformanceScore = 0;

  // 7. Workouts (user-logged only). Exercise catalog is static content, not clinical data.
  final List<Map<String, dynamic>> completedWorkouts = [];

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

  // 8. Onboarding
  double? userHeightCm;
  double? userWeightKg;
  String? baselineProgressPhotoPath;
  bool isOnboardingBaselineCompleted = false;
  String? biologicalSex;
  String? dateOfBirth;
  final List<String> healthGoals = [];

  // Chronic care — empty until user logs
  int bloodGlucoseMgDl = 0;
  String fastingStatus = '';
  final List<Map<String, dynamic>> glucoseHistory = [];
  int systolicBp = 0;
  int diastolicBp = 0;
  final List<Map<String, dynamic>> bpHistory = [];

  // Preventive care — user-created only in v1
  final List<Map<String, dynamic>> preventiveReminders = [];

  // Community / Insurance deferred for v1 store — empty lists, entry points hidden in UI
  int medicationStreakDays = 0;
  int loggingStreakDays = 0;
  int stepStreakDays = 0;
  final List<Map<String, dynamic>> activeChallenges = [];
  final List<Map<String, dynamic>> claims = [];

  // Emergency Medical ID — empty until user enters
  final List<String> allergies = [];
  final List<String> chronicConditions = [];
  final List<String> emergencyMedications = [];
  bool isFallDetectionActive = false;

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
  }

  Future<void> hydrate() async {
    try {
      await supabaseRepository.initialize();
      await eventStore.initialize();
      await consentManager.initialize();
      historicalDaysCount = _computeHistoricalDays();
      final user = await _auth.getSessionUser();
      if (user != null) {
        await _bindUser(user);
        _isSignedIn = true;
        if (userId != null) {
          await supabaseSyncService.pullRemoteEvents(userId!);
          historicalDaysCount = _computeHistoricalDays();
          recalculateRecoveryEngine();
          supabaseSyncService.syncPendingEvents(userId!);
        }
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

  int _computeHistoricalDays() {
    final events = eventStore.getAllEvents();
    if (events.isEmpty) return 0;
    final days = events
        .map((e) => DateTime(e.start.year, e.start.month, e.start.day))
        .toSet();
    return days.length;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String bloodType = 'Unknown',
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

  /// Debug-only demo. Disabled in release and unless ENABLE_DEMO=true.
  Future<void> signInDemoAccount() async {
    if (!AppEnv.enableDemo) {
      throw AuthException('Demo mode is disabled in this build.');
    }
    _isHydrating = true;
    notifyListeners();
    try {
      final demoUser = await _auth.register(
        fullName: 'Demo User',
        email: 'demo+${DateTime.now().millisecondsSinceEpoch}@healthcompanion.local',
        password: 'demo-only-${DateTime.now().millisecondsSinceEpoch}',
        bloodType: 'Unknown',
      );
      await _bindUser(demoUser, isNew: true);
      _isSignedIn = true;
    } finally {
      _isHydrating = false;
      notifyListeners();
    }
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

  /// Deletes cloud account via Edge Function, then clears local session.
  Future<void> deleteAccount() async {
    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty || !AppEnv.isSupabaseConfigured) {
      throw StateError('Account deletion requires a configured backend.');
    }

    String? accessToken;
    try {
      accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      accessToken = null;
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('You must be signed in to delete your account.');
    }

    final response = await http
        .post(
          Uri.parse('$base/delete-account'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
            'apikey': AppEnv.supabaseAnonKey,
          },
          body: '{}',
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Delete failed (${response.statusCode}): ${response.body}');
    }

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
      isOnboardingBaselineCompleted = false;
      await _persistCurrentUserData();
      recalculateRecoveryEngine();
      return;
    }

    final data = await _userData.load(user.id);
    restingHeartRate = data['restingHeartRate'] as int? ?? 0;
    sleepDuration = data['sleepDuration'] as String? ?? '—';
    dailySteps = (data['dailySteps'] as num?)?.toDouble() ?? 0;
    bloodOxygen = data['bloodOxygen'] as int? ?? 0;
    bloodPressure = data['bloodPressure'] as String? ?? '—';
    hrvMs = data['hrvMs'] as int? ?? 0;
    dailyBalanceScore = data['dailyBalanceScore'] as int? ?? 0;
    selectedMood = data['selectedMood'] as String? ?? '';
    moodProgress = (data['moodProgress'] as num?)?.toDouble() ?? 0;
    feelingStep = data['feelingStep'] as int? ?? 1;
    lastSyncedTime = DateTime.tryParse(data['lastSyncedTime'] as String? ?? '');
    unreadNotificationsCount = data['unreadNotificationsCount'] as int? ?? 0;
    isWearableConnected = data['isWearableConnected'] as bool? ?? false;
    wearableDeviceName = data['wearableDeviceName'] as String? ?? '';
    wearableSource = data['wearableSource'] as String? ?? '';
    isRealHardware = data['isRealHardware'] as bool? ?? false;
    dailyHydrationMl = data['dailyHydrationMl'] as int? ?? 0;
    isOnboardingBaselineCompleted =
        data['isOnboardingBaselineCompleted'] as bool? ?? false;
    userHeightCm = (data['userHeightCm'] as num?)?.toDouble();
    userWeightKg = (data['userWeightKg'] as num?)?.toDouble();
    isMenstrualTrackingEnabled =
        data['isMenstrualTrackingEnabled'] as bool? ?? false;
    isPregnancyMode = data['isPregnancyMode'] as bool? ?? false;
    isFallDetectionActive = data['isFallDetectionActive'] as bool? ?? false;

    journalEntries
      ..clear()
      ..addAll(_decodeMapList(data['journalEntries']));
    loggedMeals
      ..clear()
      ..addAll(_decodeMapList(data['loggedMeals']));
    menstrualCycleLogs
      ..clear()
      ..addAll(_decodeMapList(data['menstrualCycleLogs']));
    pregnancyWeightLogs
      ..clear()
      ..addAll(_decodeMapList(data['pregnancyWeightLogs']));
    kickCounterLogs
      ..clear()
      ..addAll(_decodeMapList(data['kickCounterLogs']));
    prenatalScans
      ..clear()
      ..addAll(_decodeMapList(data['prenatalScans']));
    completedWorkouts
      ..clear()
      ..addAll(_decodeMapList(data['completedWorkouts']));
    glucoseHistory
      ..clear()
      ..addAll(_decodeMapList(data['glucoseHistory']));
    bpHistory
      ..clear()
      ..addAll(_decodeMapList(data['bpHistory']));
    preventiveReminders
      ..clear()
      ..addAll(_decodeMapList(data['preventiveReminders']));
    allergies
      ..clear()
      ..addAll(List<String>.from(data['allergies'] as List? ?? const []));
    chronicConditions
      ..clear()
      ..addAll(List<String>.from(data['chronicConditions'] as List? ?? const []));
    emergencyMedications
      ..clear()
      ..addAll(
          List<String>.from(data['emergencyMedications'] as List? ?? const []));

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

    historicalDaysCount = _computeHistoricalDays();
    recalculateRecoveryEngine();
  }

  List<Map<String, dynamic>> _decodeMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      for (final key in ['timestamp', 'date', 'logged_at']) {
        final v = m[key];
        if (v is String) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) m[key] = parsed;
        }
      }
      return m;
    }).toList();
  }

  List<Map<String, dynamic>> _encodeMapList(List<Map<String, dynamic>> list) {
    return list.map((e) {
      final m = Map<String, dynamic>.from(e);
      m.forEach((k, v) {
        if (v is DateTime) m[k] = v.toIso8601String();
      });
      return m;
    }).toList();
  }

  void _resetInMemoryProfile() {
    unreadNotificationsCount = 0;
    restingHeartRate = 0;
    activeHeartRate = 0;
    hrvMs = 0;
    sleepDuration = '—';
    deepSleep = '—';
    remSleep = '—';
    lightSleep = '—';
    dailySteps = 0;
    bloodOxygen = 0;
    bloodPressure = '—';
    dailyBalanceScore = 0;
    balanceStatus = 'Connect a wearable to begin';
    recoveryScore = 0;
    recoveryStatus = 'Insufficient data';
    dailyStrainScore = 0;
    sleepPerformanceScore = 0;
    selectedMood = '';
    moodProgress = 0;
    feelingStep = 1;
    lastSyncedTime = null;
    lastSyncMessage = '';
    isWearableConnected = false;
    wearableDeviceName = '';
    wearableSource = '';
    isRealHardware = false;
    dailyHydrationMl = 0;
    loggedMeals.clear();
    journalEntries.clear();
    feelingHistory.clear();
    menstrualCycleLogs.clear();
    cycleSymptoms.clear();
    isMenstrualTrackingEnabled = false;
    cycleDay = 0;
    cyclePhase = 'Not tracking';
    isPregnancyMode = false;
    pregnancyDueDate = null;
    pregnancyWeightLogs.clear();
    kickCounterLogs.clear();
    prenatalScans.clear();
    completedWorkouts.clear();
    glucoseHistory.clear();
    bpHistory.clear();
    bloodGlucoseMgDl = 0;
    systolicBp = 0;
    diastolicBp = 0;
    preventiveReminders.clear();
    activeChallenges.clear();
    claims.clear();
    allergies.clear();
    chronicConditions.clear();
    emergencyMedications.clear();
    isFallDetectionActive = false;
    isOnboardingBaselineCompleted = false;
    userHeightCm = null;
    userWeightKg = null;
    medications.clear();
    appointments.clear();
    familyMembers.clear();
    prescriptions.clear();
    activeReport = null;
    appointmentSegmentIndex = 0;
    selectedDateIndex = DateTime.now().weekday - 1;
    historicalDaysCount = 0;
    recoveryResult = null;
    sleepResult = null;
    loadResult = null;
    stressResult = null;
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
      'hrvMs': hrvMs,
      'dailyBalanceScore': dailyBalanceScore,
      'selectedMood': selectedMood,
      'moodProgress': moodProgress,
      'feelingStep': feelingStep,
      'lastSyncedTime': lastSyncedTime?.toIso8601String(),
      'unreadNotificationsCount': unreadNotificationsCount,
      'isWearableConnected': isWearableConnected,
      'wearableDeviceName': wearableDeviceName,
      'wearableSource': wearableSource,
      'isRealHardware': isRealHardware,
      'dailyHydrationMl': dailyHydrationMl,
      'isOnboardingBaselineCompleted': isOnboardingBaselineCompleted,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'isMenstrualTrackingEnabled': isMenstrualTrackingEnabled,
      'isPregnancyMode': isPregnancyMode,
      'isFallDetectionActive': isFallDetectionActive,
      'journalEntries': _encodeMapList(journalEntries),
      'loggedMeals': _encodeMapList(loggedMeals),
      'menstrualCycleLogs': _encodeMapList(menstrualCycleLogs),
      'pregnancyWeightLogs': _encodeMapList(pregnancyWeightLogs),
      'kickCounterLogs': _encodeMapList(kickCounterLogs),
      'prenatalScans': _encodeMapList(prenatalScans),
      'completedWorkouts': _encodeMapList(completedWorkouts),
      'glucoseHistory': _encodeMapList(glucoseHistory),
      'bpHistory': _encodeMapList(bpHistory),
      'preventiveReminders': _encodeMapList(preventiveReminders),
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyMedications': emergencyMedications,
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
    if (!hasVitalsData && journalEntries.isEmpty) {
      return [
        {
          'title': 'Build your baseline',
          'metric': 'No correlations yet',
          'insight':
              'Log how you feel and sync wearable data to unlock personalized sleep, mood, and HRV correlations.',
          'icon': Icons.insights_rounded,
          'color': const Color(0xFF818CF8),
        },
      ];
    }
    final sleepLabel = sleepDuration == '—' ? 'Sleep not synced' : '$sleepDuration rest';
    final hrLabel = restingHeartRate > 0 ? '$restingHeartRate bpm resting' : 'HR not synced';
    return [
      {
        'title': 'Sleep & Mood',
        'metric': sleepLabel,
        'insight': selectedMood.isEmpty
            ? 'Log a mood after syncing sleep to see patterns.'
            : 'Recent mood "$selectedMood" with sleep reading: $sleepLabel.',
        'icon': Icons.bedtime_rounded,
        'color': const Color(0xFF818CF8),
      },
      {
        'title': 'Heart rate context',
        'metric': hrLabel,
        'insight': hrvMs > 0
            ? 'Latest HRV sample: $hrvMs ms from your connected health source.'
            : 'Connect HealthKit / Health Connect to include HRV in insights.',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF38BDF8),
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
    _persistCurrentUserData();
    notifyListeners();
  }

  int get gestationalWeeks {
    final due = pregnancyDueDate;
    if (due == null) return 0;
    final conceptionEst = due.subtract(const Duration(days: 280));
    final daysPassed = DateTime.now().difference(conceptionEst).inDays;
    return (daysPassed / 7).floor().clamp(0, 42);
  }

  int get gestationalDaysRemainder {
    final due = pregnancyDueDate;
    if (due == null) return 0;
    final conceptionEst = due.subtract(const Duration(days: 280));
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

    // Parse sleep duration into hours (empty → null)
    double? sleepHours;
    if (sleepDuration != '—' && sleepDuration.contains('h')) {
      try {
        final parts = sleepDuration.split(' ');
        final h = double.tryParse(parts[0].replaceAll('h', '')) ?? 0;
        final m = parts.length > 1
            ? (double.tryParse(parts[1].replaceAll('m', '')) ?? 0.0)
            : 0.0;
        sleepHours = h + (m / 60.0);
      } catch (_) {}
    }

    // 3. Compute Recovery v0 Score
    recoveryResult = RecoveryModel.computeRecovery(
      todayHrv: consentManager.isCategoryEnabled(PermissionCategory.hrv) && hrvMs > 0
          ? hrvMs.toDouble()
          : null,
      todayRestingHr:
          consentManager.isCategoryEnabled(PermissionCategory.heartRate) &&
                  restingHeartRate > 0
              ? restingHeartRate.toDouble()
              : null,
      todaySleepHours: consentManager.isCategoryEnabled(PermissionCategory.sleep)
          ? sleepHours
          : null,
      todayRespiratoryRate: null,
      subjectiveFeeling: selectedMood.isEmpty ? null : selectedMood,
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
    // Never fabricate physiology in release binaries.
    if (kReleaseMode) return;
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
        source: 'debug_seed',
        sourceRecordId: 'debug-hrv-$i',
        quality: 0.95,
      ));
      eventStore.recordEvent(HealthEvent(
        metric: 'resting_heart_rate',
        value: 58.0 + (i % 4) * 1.5 - (i % 2) * 2.0,
        unit: 'bpm',
        start: day,
        end: day.add(const Duration(hours: 8)),
        source: 'debug_seed',
        sourceRecordId: 'debug-rhr-$i',
        quality: 0.95,
      ));
    }
    // Sync display fields from seeded events so Recovery UI can render in debug/tests.
    hrvMs = 58;
    restingHeartRate = 60;
    sleepDuration = '7h 10m';
    dailySteps = 5000;
    isWearableConnected = true;
    wearableSource = 'debug_seed';
    wearableDeviceName = 'Debug seed source';
    recalculateRecoveryEngine();
  }

  Map<String, dynamic> getTodaysMovementSuggestion() {
    if (!hasVitalsData) {
      return {
        'title': 'Connect health data first',
        'subtitle': 'Movement guidance needs recovery inputs',
        'recommendedDuration': '—',
        'intensity': 'Unavailable',
        'reasoning':
            'Sync Apple Health / Health Connect (or log how you feel) so we can recommend intensity safely.',
        'exerciseId': 'ex-3',
        'caution': 'No fabricated strain targets are shown without your data.',
      };
    }
    if (recoveryScore >= 75) {
      return {
        'title': 'Zone 2 Cardio & Steady State',
        'subtitle': 'Optimal for Endurance & Mitochondria',
        'recommendedDuration': '35-45 min',
        'intensity': 'Moderate Aerobic (HR 120-135 bpm)',
        'reasoning':
            'Your Recovery Score is high ($recoveryScore%) with HRV ${hrvMs > 0 ? "$hrvMs ms" : "n/a"} and resting pulse ${restingHeartRate > 0 ? "$restingHeartRate bpm" : "n/a"}.',
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
            'Moderate recovery ($recoveryScore%). A low-intensity walk supports circulation without overreaching.',
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
            'Recovery Score is lower ($recoveryScore%). Prioritize gentle movement and rest.',
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
    String? dob,
    String? sex,
    List<String>? goals,
  }) {
    if (heightCm != null) userHeightCm = heightCm;
    if (weightKg != null) userWeightKg = weightKg;
    if (photoPath != null) baselineProgressPhotoPath = photoPath;
    if (dob != null) dateOfBirth = dob;
    if (sex != null) biologicalSex = sex;
    if (goals != null) {
      healthGoals
        ..clear()
        ..addAll(goals);
    }
    isOnboardingBaselineCompleted = true;
    _persistCurrentUserData();
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

  Future<String> syncVitals() async {
    isSyncingVitals = true;
    lastSyncMessage = '';
    notifyListeners();

    try {
      final authorized = await WearableService.requestAuthorization();
      if (!authorized) {
        lastSyncMessage = 'Health permissions were denied. Enable access in system settings.';
        return lastSyncMessage;
      }

      final events = await WearableService.ingestEvents(consentManager: consentManager);
      final vitals = await WearableService.fetchLatestVitals();

      if (events.isEmpty && vitals['isRealHardware'] != true) {
        lastSyncMessage = WearableService.isPlatformSupported
            ? 'No new samples found. Wear your device and ensure it syncs to Health / Health Connect.'
            : 'Health sync requires iOS (HealthKit) or Android (Health Connect).';
        return lastSyncMessage;
      }

      if (events.isNotEmpty) {
        await eventStore.recordEvents(events);
      }

      if (vitals['restingHeartRate'] is int && (vitals['restingHeartRate'] as int) > 0) {
        restingHeartRate = vitals['restingHeartRate'] as int;
      }
      if (vitals['hrvMs'] is int && (vitals['hrvMs'] as int) > 0) {
        hrvMs = vitals['hrvMs'] as int;
      }
      if (vitals['bloodOxygen'] is int && (vitals['bloodOxygen'] as int) > 0) {
        bloodOxygen = vitals['bloodOxygen'] as int;
      }
      if (vitals['dailySteps'] is num) {
        dailySteps = (vitals['dailySteps'] as num).toDouble();
      }
      if (vitals['sleepDuration'] is String &&
          (vitals['sleepDuration'] as String).isNotEmpty) {
        sleepDuration = vitals['sleepDuration'] as String;
      }
      if (vitals['bloodPressure'] is String) {
        bloodPressure = vitals['bloodPressure'] as String;
      }

      final source = vitals['source'] as String? ?? WearableService.platformSourceLabel;
      wearableSource = source;
      wearableDeviceName = vitals['deviceName'] as String? ?? source;
      isWearableConnected = true;
      isRealHardware = vitals['isRealHardware'] == true;
      lastSyncedTime = DateTime.now();
      historicalDaysCount = _computeHistoricalDays();

      if (userId != null) {
        unawaited(supabaseSyncService.syncPendingEvents(userId!));
      }

      recalculateRecoveryEngine();
      await _persistCurrentUserData();
      lastSyncMessage =
          'Synced ${events.length} sample(s) from $source.';
      return lastSyncMessage;
    } catch (e) {
      lastSyncMessage = 'Sync failed: $e';
      return lastSyncMessage;
    } finally {
      isSyncingVitals = false;
      notifyListeners();
    }
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

    // Optimistic local row, then cloud OCR when available.
    var doc = ReportInterpreterService.interpretUpload(
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

    doc = await ReportInterpreterService.interpretUploadAsync(
      fileName: originalName,
      localPath: localPath,
      source: source,
      isImage: isImage,
      documentId: doc.id,
    );
    final idx = prescriptions.indexWhere((p) => p.id == doc.id);
    if (idx >= 0) {
      prescriptions[idx] = doc;
    } else {
      prescriptions.insert(0, doc);
    }
    activeReport = ReportInterpreterService.labReportFromPrescription(doc);
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
