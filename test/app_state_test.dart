import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/core/models/appointment.dart';
import 'package:health_companion/core/models/family_member.dart';

void main() {
  group('AppState Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Initial tab index is 0 (Home)', () {
      expect(appState.currentTabIndex, 0);
    });

    test('setTabIndex updates state and notifies listeners', () {
      bool notified = false;
      appState.addListener(() => notified = true);
      appState.setTabIndex(2);
      expect(appState.currentTabIndex, 2);
      expect(notified, isTrue);
    });

    test('toggleMedication flips isTaken', () {
      final medId = appState.medications.first.id;
      final initialStatus = appState.medications.first.isTaken;
      appState.toggleMedication(medId);
      expect(appState.medications.first.isTaken, !initialStatus);
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
        name: 'Alex Jenkins',
        relation: 'Sibling',
        avatarUrl: '',
        accessLevel: 'View Only',
        ageAndGender: '32 yrs • Non-binary',
      );
      appState.addFamilyMember(member);
      expect(appState.familyMembers.length, initialCount + 1);
    });

    test('submitNewSymptomTriage generates updated assessment', () {
      appState.submitNewSymptomTriage('Sudden chest tightness and breathlessness');
      expect(appState.activeTriage.userQuery, contains('chest tightness'));
      expect(appState.activeTriage.urgencyBadge, contains('URGENT'));
    });
  });
}
