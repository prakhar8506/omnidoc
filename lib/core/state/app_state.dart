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
  String get userName => _currentUser?.fullName ?? 'Guest';
  String get bloodType => _currentUser?.bloodType ?? 'Unknown';
  String get userAvatar => _currentUser?.avatarPath ?? '';
  String? get userId => _currentUser?.id;

  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  int unreadNotificationsCount = 0;
  int restingHeartRate = 72;
  String sleepDuration = '—';
  double dailySteps = 0;
  int bloodOxygen = 98;
  String bloodPressure = '—';
  bool isSyncingVitals = false;
  DateTime lastSyncedTime = DateTime.now();

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
      await _persistCurrentUserData();
      return;
    }

    final data = await _userData.load(user.id);
    restingHeartRate = data['restingHeartRate'] as int? ?? 72;
    sleepDuration = data['sleepDuration'] as String? ?? '—';
    dailySteps = (data['dailySteps'] as num?)?.toDouble() ?? 0;
    bloodOxygen = data['bloodOxygen'] as int? ?? 98;
    bloodPressure = data['bloodPressure'] as String? ?? '—';
    lastSyncedTime =
        DateTime.tryParse(data['lastSyncedTime'] as String? ?? '') ?? DateTime.now();
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
  }

  void _resetInMemoryProfile() {
    unreadNotificationsCount = 0;
    restingHeartRate = 72;
    sleepDuration = '—';
    dailySteps = 0;
    bloodOxygen = 98;
    bloodPressure = '—';
    lastSyncedTime = DateTime.now();
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

  void clearNotifications() {
    unreadNotificationsCount = 0;
    _persistCurrentUserData();
    notifyListeners();
  }

  Future<void> syncVitals() async {
    isSyncingVitals = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 700));
    restingHeartRate = 68 + (dailySteps.toInt() % 8);
    dailySteps += 120;
    if (sleepDuration == '—') sleepDuration = '7h 10m';
    if (bloodPressure == '—') bloodPressure = '118/76';
    lastSyncedTime = DateTime.now();
    isSyncingVitals = false;
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

  /// Real upload path: persist file under the signed-in user, interpret, save.
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

  @Deprecated('Use uploadHealthDocument')
  void applyUploadedLabReport({required String sourceLabel}) {
    // Kept for older call sites; prefer real upload.
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
