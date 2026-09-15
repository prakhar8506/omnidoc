import '../models/ai_message.dart';
import '../../../core/state/app_state.dart';

class AiCopilotService {
  static List<String> getQuickPromptsForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return [
          'Explain my latest uploaded report',
          'How is my resting heart rate today?',
          'Check my medication schedule',
          'What features are available in the app?',
        ];
      case 1:
        return [
          'What do my symptoms mean?',
          'When should I go to urgent care vs ER?',
          'Can you suggest safe home remedies?',
          'Are my medications safe to take now?',
        ];
      case 2:
        return [
          'Prepare questions for my next visit',
          'How do I share records with family?',
          'What documents should I take to clinic?',
          'Help me book a new appointment',
        ];
      case 3:
        return [
          'Explain my uploaded prescription or lab',
          'What lifestyle tips support recovery?',
          'Generate questions for my doctor',
          'How do I upload another document?',
        ];
      default:
        return [
          'Explain my health metrics',
          'How do I use this app?',
          'Ask any clinical question',
        ];
    }
  }

  static AiMessage processQuery(String query, AppState state) {
    final lower = query.toLowerCase();
    final firstName = state.userName.split(' ').first;

    if (lower.contains('alt') ||
        lower.contains('liver') ||
        lower.contains('cmp') ||
        lower.contains('lab') ||
        lower.contains('biomarker') ||
        lower.contains('glucose') ||
        lower.contains('creatinine') ||
        lower.contains('prescription') ||
        lower.contains('report') ||
        lower.contains('upload')) {
      final report = state.activeReport;
      final latest = state.prescriptions.isNotEmpty ? state.prescriptions.first : null;
      final body = report == null
          ? "You do not have an uploaded lab or prescription yet, **$firstName**.\n\n"
              "Go to **Labs**, then choose **Camera**, **Gallery**, or **Files** to upload a document. "
              "I will explain it in plain language afterward."
          : "Here is a plain-language summary of your latest document:\n\n"
              "**${report.title}**\n"
              "${report.overallSynthesis}\n\n"
              "${latest != null ? latest.detailedExplanation : 'Open the Labs tab for biomarker details and doctor questions.'}";

      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: body,
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Labs • Document Insight',
        actionLinks: const [
          AiActionLink(label: 'Open Labs', targetTabIndex: 3),
        ],
      );
    }

    if (lower.contains('doctor') ||
        lower.contains('appointment') ||
        lower.contains('visit') ||
        lower.contains('clinic') ||
        lower.contains('book')) {
      if (state.appointments.isEmpty) {
        return AiMessage(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          text: "You have **no upcoming visits** yet, **$firstName**.\n\n"
              "Open **Visits** and tap **Book Visit** to schedule an in-person or telehealth appointment.",
          sender: AiSender.assistant,
          timestamp: DateTime.now(),
          contextualBadge: 'Appointments',
          actionLinks: const [
            AiActionLink(label: 'Go to Appointments', targetTabIndex: 2),
          ],
        );
      }

      final next = state.appointments.first;
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Your next visit is with **${next.doctorName}**.\n\n"
              "• **When**: ${next.dateTime}\n"
              "• **Where**: ${next.clinicName}\n"
              "• **Type**: ${next.roomOrType}\n"
              "• **Prep**: ${next.preparationNote}",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Appointments • Schedule',
        actionLinks: const [
          AiActionLink(label: 'Go to Appointments', targetTabIndex: 2),
        ],
      );
    }

    if (lower.contains('family') ||
        lower.contains('share') ||
        lower.contains('permission') ||
        lower.contains('caregiver')) {
      final count = state.familyMembers.length;
      final names = state.familyMembers.map((m) => '• **${m.name}** (${m.relation})').join('\n');
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: count == 0
            ? "No family members are connected yet. Invite someone from **Visits → Family Sharing** or **Family Connectivity**."
            : "You currently share with **$count** family member(s):\n\n$names\n\n"
                "You can change permissions anytime.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Family Sharing',
        actionLinks: const [
          AiActionLink(label: 'Manage Family Sharing', targetTabIndex: 2, actionType: 'family_tab'),
        ],
      );
    }

    if (lower.contains('vital') ||
        lower.contains('heart') ||
        lower.contains('bpm') ||
        lower.contains('sleep') ||
        lower.contains('step') ||
        lower.contains('spo2') ||
        lower.contains('oxygen') ||
        lower.contains('blood pressure')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Here is your biometric snapshot, **$firstName**:\n\n"
              "• **Resting Heart Rate**: **${state.restingHeartRate} bpm**\n"
              "• **Sleep**: **${state.sleepDuration}**\n"
              "• **Activity**: **${(state.dailySteps / 1000).toStringAsFixed(1)}k steps**\n"
              "• **Blood Oxygen**: **${state.bloodOxygen}%**\n"
              "• **Blood Pressure**: **${state.bloodPressure}**",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Biometrics • Live Vitals',
        actionLinks: const [
          AiActionLink(label: 'View Vitals Dashboard', targetTabIndex: 0),
        ],
      );
    }

    if (lower.contains('headache') ||
        lower.contains('pain') ||
        lower.contains('symptom') ||
        lower.contains('triage') ||
        lower.contains('neck') ||
        lower.contains('fever') ||
        lower.contains('sick')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Your latest triage note:\n\n"
              "**${state.activeTriage.urgencyBadge}** (${state.activeTriage.timeframeWindow})\n\n"
              "${state.activeTriage.clinicalRationale}\n\n"
              "Use the Triage tab to describe new symptoms. Seek emergency care for chest pain, severe breathing trouble, or sudden weakness.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Clinical Triage',
        actionLinks: const [
          AiActionLink(label: 'Open Symptom Triage', targetTabIndex: 1),
        ],
      );
    }

    if (lower.contains('feature') ||
        lower.contains('app') ||
        lower.contains('how to') ||
        lower.contains('help') ||
        lower.contains('what can you do')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Welcome to **Health Companion**, **$firstName**.\n\n"
              "1. **Home** — vitals, medications, quick actions\n"
              "2. **Triage** — describe symptoms for guidance\n"
              "3. **Visits** — book appointments and share with family\n"
              "4. **Labs** — upload prescriptions/labs from camera, gallery, or files\n"
              "5. **Ask Health AI** — ask me anytime",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Health Companion Guide',
        actionLinks: const [
          AiActionLink(label: 'Explore Home', targetTabIndex: 0),
          AiActionLink(label: 'Upload Document', targetTabIndex: 3),
        ],
      );
    }

    return AiMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: "Thanks for asking about **\"$query\"**, **$firstName**.\n\n"
            "I am using your profile (${state.userName}, blood type ${state.bloodType}, "
            "heart rate ${state.restingHeartRate} bpm).\n\n"
            "This is general guidance only — not a diagnosis. Upload reports in Labs or book a visit for clinician advice.",
      sender: AiSender.assistant,
      timestamp: DateTime.now(),
      contextualBadge: 'Health AI Copilot',
      actionLinks: const [
        AiActionLink(label: 'Open Labs', targetTabIndex: 3),
        AiActionLink(label: 'Book Visit', targetTabIndex: 2),
      ],
    );
  }
}
