import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/core/models/appointment.dart';
import 'package:health_companion/core/models/family_member.dart';
import 'package:health_companion/core/services/auth_service.dart';

void main() {
  group('AppState Tests', () {
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      await appState.register(
        fullName: 'Test User',
        email: 'test.user@gmail.com',
        password: 'testpass',
        bloodType: 'O+',
      );
    });

    test('New account uses the registered name, not Sarah', () {
      expect(appState.userName, 'Test User');
      expect(appState.userEmail, 'test.user@gmail.com');
      expect(appState.bloodType, 'O+');
      expect(appState.appointments, isEmpty);
      expect(appState.familyMembers, isEmpty);
      expect(appState.activeReport, isNull);
    });

    test('setTabIndex updates state and notifies listeners', () {
      bool notified = false;
      appState.addListener(() => notified = true);
      appState.setTabIndex(2);
      expect(appState.currentTabIndex, 2);
      expect(notified, isTrue);
    });

    test('addAppointment increases appointment list', () {
      final initialCount = appState.appointments.length;
      final newAppt = Appointment(
        id: 'test-apt',
        doctorName: 'Dr. Test',
        doctorTitle: 'Specialist',
        specialty: 'Testing',
        avatarUrl: '',
        dateTime: DateTime.now(),
        clinicName: 'Test Clinic',
        roomOrType: 'In Person',
        status: 'Confirmed',
        preparationNote: 'None',
      );
      appState.addAppointment(newAppt);
      expect(appState.appointments.length, initialCount + 1);
    });

    test('addFamilyMember increases family list', () {
      final initialCount = appState.familyMembers.length;
      final member = FamilyMember(
        id: 'fam-test',
        name: 'Alex Friend',
        relation: 'Sibling',
        avatarUrl: '',
        accessLevel: 'View Only',
        ageAndGender: '32 yrs',
      );
      appState.addFamilyMember(member);
      expect(appState.familyMembers.length, initialCount + 1);
    });

    test('submitNewSymptomTriage generates updated assessment', () {
      appState.submitNewSymptomTriage('Sudden chest tightness and breathlessness');
      expect(appState.activeTriage.userQuery, contains('chest tightness'));
      expect(appState.activeTriage.urgencyBadge, contains('URGENT'));
    });

    test('signOut clears session', () async {
      await appState.signOut();
      expect(appState.isSignedIn, isFalse);
      expect(appState.userEmail, isEmpty);
    });

    test('wrong password does not sign into another profile', () async {
      await appState.signOut();
      final auth = AuthService();
      await auth.register(
        fullName: 'Other Person',
        email: 'other@gmail.com',
        password: 'abcdef',
      );
      expect(
        () => auth.signIn(email: 'other@gmail.com', password: 'nope'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
