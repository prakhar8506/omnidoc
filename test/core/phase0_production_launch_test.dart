import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/env/app_env.dart';
import 'package:health_companion/core/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 0: Production Launch Foundation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Fresh AppState starts with empty persona and no fabricated vitals', () {
      final state = AppState();

      expect(state.userName, isEmpty);
      expect(state.userEmail, isEmpty);
      expect(state.isOnboardingBaselineCompleted, isFalse);
      expect(state.isWearableConnected, isFalse);
      expect(state.hasVitalsData, isFalse);

      expect(state.restingHeartRate, 0);
      expect(state.activeHeartRate, 0);
      expect(state.hrvMs, 0);
      expect(state.bloodOxygen, 0);
      expect(state.bloodPressure, '—');
      expect(state.sleepDuration, '—');
      expect(state.dailySteps, 0);

      expect(state.loggedMeals, isEmpty);
      expect(state.journalEntries, isEmpty);
      expect(state.menstrualCycleLogs, isEmpty);
      expect(state.pregnancyWeightLogs, isEmpty);
      expect(state.claims, isEmpty);
      expect(state.allergies, isEmpty);
      expect(state.chronicConditions, isEmpty);
      expect(state.emergencyMedications, isEmpty);
      expect(state.preventiveReminders, isEmpty);
      expect(state.activeChallenges, isEmpty);
    });

    test('AppEnv validateRequired detects missing required credentials', () {
      expect(AppEnv.isSupabaseConfigured, isFalse);
      expect(
        () => AppEnv.validateRequired(),
        throwsA(isA<StateError>()),
      );
    });

    test('Demo mode runtime flag adheres to enableDemo / isDemoEnabled', () {
      expect(AppEnv.isDemoEnabled, AppEnv.enableDemo);
      expect(AppEnv.enableDemo, isFalse);
    });

    test('Baseline profile persistence updates onboarding completed flag', () async {
      final state = AppState();
      expect(state.isOnboardingBaselineCompleted, isFalse);

      state.saveBaselineData(
        dob: '1990-05-15',
        sex: 'Male',
        heightCm: 182,
        weightKg: 78.5,
        goals: ['Sleep optimization', 'HRV improvement'],
      );

      expect(state.isOnboardingBaselineCompleted, isTrue);
      expect(state.biologicalSex, 'Male');
      expect(state.dateOfBirth, '1990-05-15');
      expect(state.userWeightKg, 78.5);
      expect(state.userHeightCm, 182);
      expect(state.healthGoals, contains('Sleep optimization'));
    });
  });
}
