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

class AppState extends ChangeNotifier {
  final AuthService _auth = AuthService();
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
  String sleepDuration = '7h 10m';
  double dailySteps = 8420;
  int bloodOxygen = 98;
  String bloodPressure = '118/76';
  bool isSyncingVitals = false;
  DateTime lastSyncedTime = DateTime.now().subtract(const Duration(minutes: 8));

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
      final user = await _auth.getSessionUser();
      if (user != null) {
        await _bindUser(user);
        _isSignedIn = true;
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

  void _recalculateBalance() {
    int score = 70;
    if (dailySteps > 8000) score += 5;
    if (restingHeartRate < 75) score += 3;
    if (selectedMood == 'Energetic' || selectedMood == 'Radiant') score += 4;
    if (selectedMood == 'Calm' || selectedMood == 'Relaxed') score += 3;
    if (selectedMood == 'Tired') score -= 4;

    dailyBalanceScore = score.clamp(40, 99);
    if (dailyBalanceScore >= 75) {
      balanceStatus = 'Good balance';
    } else if (dailyBalanceScore >= 60) {
      balanceStatus = 'Moderate balance';
    } else {
      balanceStatus = 'Needs attention';
    }
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
    restingHeartRate = 70 + (dailySteps.toInt() % 4);
    dailySteps += 350;
    sleepDuration = '7h 45m';
    bloodPressure = '116/74';
    lastSyncedTime = DateTime.now();
    isSyncingVitals = false;
    _recalculateBalance();
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
}
