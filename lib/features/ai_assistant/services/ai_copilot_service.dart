import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_message.dart';
import '../../../core/env/app_env.dart';
import '../../../core/models/triage_models.dart';
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
          'Generate questions for my next visit',
          'How do I upload another document',
        ];
      default:
        return [
          'Explain my health metrics',
          'How do I use this app?',
          'Ask any clinical question',
        ];
    }
  }

  /// Consent-gated health bundle sent to Gemini via Edge Function.
  static Map<String, dynamic> buildHealthContext(AppState state) {
    final meds = state.medications
        .map((m) => {
              'name': m.name,
              'dose': m.dosage,
              'time': m.scheduleTime,
              'taken': m.isTaken,
            })
        .toList();

    final scripts = state.prescriptions.take(3).map((p) {
      return {
        'title': p.fileName,
        'summary': p.plainLanguageSummary,
        'detail': p.detailedExplanation,
        'findings': p.keyFindings,
        'ocrConfidence': p.ocrConfidence,
      };
    }).toList();

    final labs = state.activeReport == null
        ? null
        : {
            'title': state.activeReport!.title,
            'synthesis': state.activeReport!.overallSynthesis,
          };

    return {
      'tabIndex': state.currentTabIndex,
      'userName': state.userName,
      'bloodType': state.bloodType,
      'dailyBalanceScore': state.dailyBalanceScore,
      'energyScore': state.energyScore,
      'selectedMood': state.selectedMood,
      'restingHeartRate': state.restingHeartRate,
      'sleepDuration': state.sleepDuration,
      'dailySteps': state.dailySteps,
      'bloodOxygen': state.bloodOxygen,
      'hrvMs': state.hrvMs,
      'stress': {
        'highest': state.stressHighest,
        'lowest': state.stressLowest,
        'average': state.stressAverage,
      },
      'medications': meds,
      'prescriptions': scripts,
      'labReport': labs,
      'activeTriage': {
        'urgency': state.activeTriage.urgencyBadge,
        'rationale': state.activeTriage.clinicalRationale,
        'query': state.activeTriage.userQuery,
      },
      'wearableConnected': state.isWearableConnected,
    };
  }

  /// Remote Edge Function path with local fallback.
  static Future<AiMessage> processQueryAsync(
    String query,
    AppState state, {
    String mode = 'chat',
  }) async {
    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty || !AppEnv.isSupabaseConfigured) {
      return _offlinePrefixed(processQuery(query, state));
    }

    try {
      String? sessionToken;
      try {
        sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        sessionToken = null;
      }

      if (sessionToken == null || sessionToken.isEmpty) {
        return AiMessage(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Sign in to unlock live Health AI answers. '
              'Your session is required to call the secure coach endpoint.',
          sender: AiSender.assistant,
          timestamp: DateTime.now(),
          contextualBadge: 'Auth required',
        );
      }
      final bearer = sessionToken;

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
              'mode': mode,
              'context': buildHealthContext(state),
            }),
          )
          .timeout(const Duration(seconds: 45));

      // One retry on transient Edge/provider failures.
      var effective = response;
      if (response.statusCode >= 500) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        effective = await http
            .post(
              Uri.parse('$base/health-ai-chat'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $bearer',
                'apikey': AppEnv.supabaseAnonKey,
              },
              body: jsonEncode({
                'message': query,
                'mode': mode,
                'context': buildHealthContext(state),
              }),
            )
            .timeout(const Duration(seconds: 45));
      }

      if (effective.statusCode >= 200 && effective.statusCode < 300) {
        final decoded = jsonDecode(effective.body);
        if (decoded is Map) {
          final text = (decoded['reply'] ??
                  decoded['message'] ??
                  decoded['text'] ??
                  decoded['content'] ??
                  '')
              .toString()
              .trim();
          if (text.isNotEmpty) {
            final provider = (decoded['provider'] ?? 'cloud').toString();
            return AiMessage(
              id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
              text: text,
              sender: AiSender.assistant,
              timestamp: DateTime.now(),
              contextualBadge: provider == 'gemini'
                  ? 'Health AI • Gemini'
                  : provider == 'openai'
                      ? 'Health AI • Cloud'
                      : 'Health AI • Cloud',
            );
          }
        }
      } else if (effective.statusCode == 401) {
        return AiMessage(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Sign in to unlock live Health AI answers powered by Gemini. '
              'Your session token is required to call the secure coach endpoint.',
          sender: AiSender.assistant,
          timestamp: DateTime.now(),
          contextualBadge: 'Auth required',
        );
      } else {
        debugPrint(
          '[AiCopilot] health-ai-chat ${effective.statusCode}: ${effective.body}',
        );
      }
    } catch (e) {
      debugPrint('[AiCopilot] health-ai-chat failed: $e');
    }

    return _offlinePrefixed(processQuery(query, state));
  }

  /// Structured triage via Gemini; falls back to local heuristics.
  static Future<TriageAssessment> runSymptomTriageAsync(
    String query,
    AppState state,
  ) async {
    final base = AppEnv.functionsBaseUrl;
    if (base.isEmpty || !AppEnv.isSupabaseConfigured) {
      return _localTriage(query);
    }

    try {
      String? sessionToken;
      try {
        sessionToken = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        sessionToken = null;
      }
      if (sessionToken == null || sessionToken.isEmpty) {
        return _localTriage(query);
      }
      final bearer = sessionToken;

      final response = await http
          .post(
            Uri.parse('$base/health-ai-chat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $bearer',
              'apikey': AppEnv.supabaseAnonKey,
            },
            body: jsonEncode({
              'message':
                  'User reports: "$query". Provide wellness triage using the template. '
                  'If they ask about medicine, reference logged medications/prescriptions in context.',
              'mode': 'triage',
              'context': buildHealthContext(state),
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final triageRaw = decoded['triage'];
          final reply = (decoded['reply'] ?? '').toString();
          if (triageRaw is Map) {
            return _triageFromMap(query, triageRaw, fallbackText: reply);
          }
          if (reply.trim().isNotEmpty) {
            return _triageFromMap(query, {
              'urgency': 'MODERATE',
              'timeframeWindow': '24–48 hrs',
              'clinicalRationale': reply.trim(),
              'selfCare': const [],
              'redFlags': const [
                'Difficulty breathing or sudden chest pressure.',
                'Loss of consciousness or severe disorientation.',
              ],
              'recommendedSpecialty': 'General Practice / Telehealth',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[AiCopilot] triage failed: $e');
    }

    return _localTriage(query);
  }

  static TriageAssessment _triageFromMap(
    String query,
    Map triageRaw, {
    String fallbackText = '',
  }) {
    final urgencyStr = (triageRaw['urgency'] ?? 'MODERATE').toString().toUpperCase();
    TriageUrgency urgency;
    String badge;
    switch (urgencyStr) {
      case 'EMERGENCY':
        urgency = TriageUrgency.emergency;
        badge = 'EMERGENCY CARE NOW';
        break;
      case 'URGENT':
        urgency = TriageUrgency.urgent;
        badge = 'URGENT EVALUATION';
        break;
      case 'LOW':
        urgency = TriageUrgency.low;
        badge = 'LOW CONCERN • MONITOR';
        break;
      default:
        urgency = TriageUrgency.moderate;
        badge = 'MONITOR & CONSULT';
    }

    final selfCareRaw = triageRaw['selfCare'];
    final selfCare = <SelfCareGuidance>[];
    if (selfCareRaw is List) {
      for (final item in selfCareRaw) {
        if (item is Map) {
          selfCare.add(
            SelfCareGuidance(
              icon: Icons.spa_rounded,
              title: (item['title'] ?? 'Self-care').toString(),
              description: (item['description'] ?? '').toString(),
            ),
          );
        }
      }
    }
    if (selfCare.isEmpty) {
      selfCare.addAll(const [
        SelfCareGuidance(
          icon: Icons.spa_rounded,
          title: 'Rest in a quiet space',
          description:
              'Rest in a dim room with good airflow; elevate your head if congested or headachy.',
        ),
        SelfCareGuidance(
          icon: Icons.water_drop_rounded,
          title: 'Hydration & gentle nutrition',
          description: 'Sip water or herbal tea; avoid alcohol until you feel better.',
        ),
      ]);
    }

    final redFlagsRaw = triageRaw['redFlags'];
    final redFlags = <String>[];
    if (redFlagsRaw is List) {
      for (final f in redFlagsRaw) {
        final s = f.toString().trim();
        if (s.isNotEmpty) redFlags.add(s);
      }
    }
    if (redFlags.isEmpty) {
      redFlags.addAll(const [
        'Difficulty breathing or sudden chest pressure.',
        'Uncontrollable vomiting or severe dizziness.',
        'Loss of consciousness or severe disorientation.',
      ]);
    }

    final rationale = (triageRaw['clinicalRationale'] ?? fallbackText)
        .toString()
        .trim();

    return TriageAssessment(
      id: 'tri-${DateTime.now().millisecondsSinceEpoch}',
      userQuery: '“$query”',
      timestamp: DateTime.now(),
      urgency: urgency,
      urgencyBadge: badge,
      timeframeWindow:
          (triageRaw['timeframeWindow'] ?? '24–48 hrs').toString(),
      clinicalRationale: rationale.isNotEmpty
          ? rationale
          : 'Based on reported symptoms: "$query". This is wellness guidance only — not a diagnosis.',
      selfCareItems: selfCare,
      redFlagAlerts: redFlags,
      recommendedSpecialty:
          (triageRaw['recommendedSpecialty'] ?? 'General Practice / Telehealth')
              .toString(),
      audioNarrationTranscript:
          'Assessment complete for your reported symptoms. Please review guidance and contact your physician if discomfort worsens.',
    );
  }

  static TriageAssessment _localTriage(String query) {
    final lower = query.toLowerCase();
    final urgent = lower.contains('chest') ||
        lower.contains('breath') ||
        lower.contains('stroke') ||
        lower.contains('unconscious');
    return TriageAssessment(
      id: 'tri-${DateTime.now().millisecondsSinceEpoch}',
      userQuery: '“$query”',
      timestamp: DateTime.now(),
      urgency: urgent ? TriageUrgency.urgent : TriageUrgency.moderate,
      urgencyBadge: urgent ? 'URGENT EVALUATION' : 'MONITOR & CONSULT',
      timeframeWindow: urgent ? 'Immediate / Same Day' : 'Window: 24–48 hrs',
      clinicalRationale:
          'Live AI is temporarily unavailable. Based on "$query", monitor symptoms and seek clinician advice. '
          'This is not a diagnosis. For chest pain, severe breathing trouble, or sudden weakness, seek emergency care.',
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
          description:
              'Sip warm herbal teas (chamomile or peppermint) and maintain balanced hydration.',
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
        lower.contains('upload') ||
        lower.contains('medicine') ||
        lower.contains('medication') ||
        lower.contains('pill')) {
      final report = state.activeReport;
      final latest =
          state.prescriptions.isNotEmpty ? state.prescriptions.first : null;
      final medLines = state.medications.isEmpty
          ? 'No medications logged yet.'
          : state.medications
              .map((m) => '• **${m.name}** ${m.dosage} (${m.scheduleTime})')
              .join('\n');

      if (lower.contains('medicine') ||
          lower.contains('medication') ||
          lower.contains('pill') ||
          lower.contains('headache') ||
          lower.contains('take')) {
        return AiMessage(
          id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
          text:
              "I can't prescribe medications, **$firstName**, but here is what is on your profile:\n\n"
              "**Logged medications**\n$medLines\n\n"
              "${latest != null ? '**Latest prescription document**: ${latest.fileName}\n${latest.detailedExplanation}\n\n' : ''}"
              "For headaches, people often use rest, hydration, and OTC pain relief **only if** it does not conflict with your listed meds — confirm with a pharmacist or clinician. "
              "Seek urgent care for sudden severe headache, chest pain, or neurological symptoms.",
          sender: AiSender.assistant,
          timestamp: DateTime.now(),
          contextualBadge: 'Meds • Local guidance',
          actionLinks: const [
            AiActionLink(label: 'Open Labs', targetTabIndex: 4),
            AiActionLink(label: 'Open Triage', targetTabIndex: 2),
          ],
        );
      }

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
      final names =
          state.familyMembers.map((m) => '• **${m.name}** (${m.relation})').join('\n');
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
          AiActionLink(
            label: 'Manage Family Sharing',
            targetTabIndex: 3,
            actionType: 'family_tab',
          ),
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
        lower.contains('energy') ||
        lower.contains('blood pressure')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Here is your biometric snapshot, **$firstName**:\n\n"
            "• **Daily Balance**: **${state.dailyBalanceScore}/100** (${state.balanceStatus})\n"
            "• **Energy Score**: **${state.energyScore}/100**\n"
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
            "• Energy Score: **${state.energyScore}/100**\n"
            "• Autonomic Stress: **${state.stressHighest} max / ${state.stressAverage} avg**\n"
            "• Tip: Light cardio or gentle stretching can support recovery when energy is low.\n\n"
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
            "Use the Triage tab to describe new symptoms for a fresh assessment. "
            "Seek emergency care for chest pain, severe breathing trouble, or sudden weakness.",
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
