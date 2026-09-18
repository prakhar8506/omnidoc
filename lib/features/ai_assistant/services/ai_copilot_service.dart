import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_message.dart';
import '../../../core/env/app_env.dart';
import '../../../core/state/app_state.dart';

class AiCopilotService {
  static List<String> getQuickPromptsForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return [
          'Explain my Daily Balance score',
          'How is my resting heart rate today?',
          'Check my medication schedule',
          'What features are available in the app?',
        ];
      case 1:
        return [
          'How does my feeling correlate with vitals?',
          'Tips to improve my energy and focus',
          'Explain autonomic stress balance',
          'Log feeling with voice or AI',
        ];
      case 2:
        return [
          'What do my symptoms mean?',
          'When should I go to urgent care vs ER?',
          'Can you suggest safe home remedies?',
          'Are my medications safe to take now?',
        ];
      case 3:
        return [
          'Prepare questions for my next visit',
          'How do I share records with family?',
          'What documents should I take to clinic?',
          'Help me book a new appointment',
        ];
      case 4:
        return [
          'Explain my uploaded prescription or lab',
          'What does my ALT biomarker level mean?',
          'Generate questions for Dr. Priya Sharma',
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

  /// Remote Edge Function path with local fallback.
  static Future<AiMessage> processQueryAsync(String query, AppState state) async {
    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty) {
      return _offlinePrefixed(processQuery(query, state));
    }

    try {
      String? sessionToken;
      try {
        sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        sessionToken = null;
      }

      final bearer = (sessionToken != null && sessionToken.isNotEmpty)
          ? sessionToken
          : AppEnv.supabaseAnonKey;

      final response = await http
          .post(
            Uri.parse('$base/health-ai-chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $bearer',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode({
              'message': query,
              'context': {
                'tabIndex': state.currentTabIndex,
                'userName': state.userName,
                'dailyBalanceScore': state.dailyBalanceScore,
                'restingHeartRate': state.restingHeartRate,
                'selectedMood': state.selectedMood,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        String text;
        if (decoded is Map) {
          text = (decoded['reply'] ??
                  decoded['message'] ??
                  decoded['text'] ??
                  decoded['content'] ??
                  '')
              .toString();
        } else {
          text = decoded.toString();
        }
        if (text.trim().isNotEmpty) {
          return AiMessage(
            id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
            text: text.trim(),
            sender: AiSender.assistant,
            timestamp: DateTime.now(),
            contextualBadge: 'Health AI • Cloud',
          );
        }
      }
    } catch (_) {
      // Fall through to local guidance
    }

    return _offlinePrefixed(processQuery(query, state));
  }

  static AiMessage _offlinePrefixed(AiMessage local) {
    return AiMessage(
      id: local.id,
      text: 'Offline assistant (local guidance only).\n\n${local.text}',
      sender: local.sender,
      timestamp: local.timestamp,
      contextualBadge: local.contextualBadge,
      actionLinks: local.actionLinks,
    );
  }

  static AiMessage processQuery(String query, AppState state) {
    final lower = query.toLowerCase();
    final firstName = state.firstName;

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
              "Go to **Biology & Labs**, then choose **Camera**, **Gallery**, or **Files** to upload a document. "
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
          AiActionLink(label: 'Open Labs', targetTabIndex: 4),
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
            AiActionLink(label: 'Go to Appointments', targetTabIndex: 3),
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
          AiActionLink(label: 'Go to Appointments', targetTabIndex: 3),
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
          AiActionLink(label: 'Manage Family Sharing', targetTabIndex: 3, actionType: 'family_tab'),
        ],
      );
    }

    if (lower.contains('vital') ||
        lower.contains('heart') ||
        lower.contains('bpm') ||
        lower.contains('sleep') ||
        lower.contains('step') ||
        lower.contains('spo2') ||
        lower.contains('balance') ||
        lower.contains('oxygen') ||
        lower.contains('blood pressure')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Here is your biometric snapshot, **$firstName**:\n\n"
            "• **Daily Balance**: **${state.dailyBalanceScore}/100** (${state.balanceStatus})\n"
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

    if (lower.contains('mood') ||
        lower.contains('feel') ||
        lower.contains('journal') ||
        lower.contains('stress') ||
        lower.contains('mind')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Your current tracked feeling is **${state.selectedMood}**.\n\n"
            "• Autonomic Stress: **${state.stressHighest} max / ${state.stressAverage} avg**\n"
            "• Physiological Tip: Light cardio or gentle stretching promotes serotonin & dopamine homeostasis.\n\n"
            "Open your Feeling Journal to dial in adjustments anytime.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Mental Balance • Journal',
        actionLinks: const [
          AiActionLink(label: 'Open Feeling Journal', targetTabIndex: 1),
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
          AiActionLink(label: 'Open Symptom Triage', targetTabIndex: 2),
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
        text: "Welcome to **Cura**, **$firstName**.\n\n"
            "1. **Daily Balance (Home)** — vitals, medications, stress telemetry\n"
            "2. **Feeling Journal** — interactive mood arc dial & mental telemetry\n"
            "3. **Symptom Triage** — describe symptoms for clinical evaluation\n"
            "4. **Fitness & Visits** — book doctors & manage family connectivity\n"
            "5. **Biology & Labs** — upload prescriptions & interpret biomarkers",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Cura Guide',
        actionLinks: const [
          AiActionLink(label: 'Explore Home', targetTabIndex: 0),
          AiActionLink(label: 'Open Journal', targetTabIndex: 1),
          AiActionLink(label: 'Upload Document', targetTabIndex: 4),
        ],
      );
    }

    return AiMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: "Thanks for asking about **\"$query\"**, **$firstName**.\n\n"
          "I am analyzing your profile (${state.userName}, blood type ${state.bloodType}, "
          "heart rate ${state.restingHeartRate} bpm, feeling ${state.selectedMood}).\n\n"
          "This is general guidance only — not a diagnosis. Upload reports in Labs or book a visit for clinician advice.",
      sender: AiSender.assistant,
      timestamp: DateTime.now(),
      contextualBadge: 'Health AI Copilot',
      actionLinks: const [
        AiActionLink(label: 'Open Labs', targetTabIndex: 4),
        AiActionLink(label: 'Book Visit', targetTabIndex: 3),
      ],
    );
  }
}
