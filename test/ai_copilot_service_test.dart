import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/features/ai_assistant/services/ai_copilot_service.dart';

void main() {
  group('AiCopilotService Tests', () {
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
      await appState.register(
        fullName: 'Casey Lee',
        email: 'casey@gmail.com',
        password: 'pass1234',
      );
    });

    test('Returns contextual quick prompts for Home tab', () {
      final prompts = AiCopilotService.getQuickPromptsForTab(0);
      expect(prompts, isNotEmpty);
      expect(prompts.any((p) => p.toLowerCase().contains('heart')), isTrue);
    });

    test('Returns contextual quick prompts for Lab Reports tab', () {
      final prompts = AiCopilotService.getQuickPromptsForTab(3);
      expect(prompts, isNotEmpty);
      expect(prompts.any((p) => p.toLowerCase().contains('upload')), isTrue);
    });

    test('Lab queries guide empty profiles to upload', () {
      final response = AiCopilotService.processQuery('Explain my lab report', appState);
      expect(response.text.toLowerCase(), contains('upload'));
      expect(response.actionLinks!.any((a) => a.targetTabIndex == 3), isTrue);
    });

    test('Appointment queries handle empty schedule', () {
      final response = AiCopilotService.processQuery('When is my appointment?', appState);
      expect(response.text.toLowerCase(), contains('no upcoming'));
      expect(response.actionLinks!.any((a) => a.targetTabIndex == 2), isTrue);
    });

    test('Processes vitals queries with live metrics', () {
      final response = AiCopilotService.processQuery('How is my heart rate?', appState);
      expect(response.text.contains('${appState.restingHeartRate} bpm'), isTrue);
      expect(response.text.contains('Casey'), isTrue);
    });
  });
}
