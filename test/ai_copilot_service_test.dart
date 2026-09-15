import 'package:flutter_test/flutter_test.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/features/ai_assistant/services/ai_copilot_service.dart';

void main() {
  group('AiCopilotService Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Returns contextual quick prompts for Home tab', () {
      final prompts = AiCopilotService.getQuickPromptsForTab(0);
      expect(prompts, isNotEmpty);
      expect(prompts.any((p) => p.contains('CMP') || p.contains('heart rate')), isTrue);
    });

    test('Returns contextual quick prompts for Lab Reports tab', () {
      final prompts = AiCopilotService.getQuickPromptsForTab(3);
      expect(prompts, isNotEmpty);
      expect(prompts.any((p) => p.contains('ALT')), isTrue);
    });

    test('Processes ALT lab queries with clinical context', () {
      final response = AiCopilotService.processQuery('What is my ALT level?', appState);
      expect(response.text.contains('65 U/L'), isTrue);
      expect(response.actionLinks, isNotNull);
      expect(response.actionLinks!.any((a) => a.targetTabIndex == 3), isTrue);
    });

    test('Processes doctor appointment queries with Dr. Sharma context', () {
      final response = AiCopilotService.processQuery('When is my appointment with Dr. Sharma?', appState);
      expect(response.text.contains('Dr. Priya Sharma'), isTrue);
      expect(response.actionLinks!.any((a) => a.targetTabIndex == 2), isTrue);
    });

    test('Processes vitals queries with live metrics', () {
      final response = AiCopilotService.processQuery('How is my heart rate?', appState);
      expect(response.text.contains('${appState.restingHeartRate} bpm'), isTrue);
    });
  });
}
