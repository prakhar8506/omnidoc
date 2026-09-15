import '../models/ai_message.dart';
import '../../../core/state/app_state.dart';

class AiCopilotService {
  static List<String> getQuickPromptsForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // Home
        return [
          "Explain my latest CMP report",
          "How is my resting heart rate today?",
          "Check my supplement schedule",
          "What features are available in the app?",
        ];
      case 1: // Triage
        return [
          "What do my headache symptoms mean?",
          "When should I go to urgent care vs ER?",
          "Can you suggest safe home remedies?",
          "Are my medications safe to take now?",
        ];
      case 2: // Appointments & Family
        return [
          "Prepare questions for Dr. Priya Sharma",
          "How do I share records with David?",
          "What documents should I take to clinic?",
          "Find next available cardiologist slot",
        ];
      case 3: // Lab Reports
        return [
          "What does elevated ALT (65 U/L) mean?",
          "Why is my fasting glucose (92) optimal?",
          "What lifestyle changes support liver health?",
          "Generate questions for my doctor",
        ];
      default:
        return [
          "Explain my health metrics",
          "How do I use this app?",
          "Ask any clinical question",
        ];
    }
  }

  static AiMessage processQuery(String query, AppState state) {
    final lower = query.toLowerCase();

    // 1. Context: Lab Reports / ALT / Biomarkers
    if (lower.contains('alt') || lower.contains('liver') || lower.contains('cmp') || lower.contains('lab') || lower.contains('biomarker') || lower.contains('glucose') || lower.contains('creatinine')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Here is the clinical breakdown for your **Comprehensive Metabolic Panel (CMP)**:\n\n"
              "• **ALT (Alanine Aminotransferase)** is mildly elevated at **65 U/L** (Reference: 7–56 U/L, +12% since July).\n"
              "• **Fasting Glucose** is **92 mg/dL** (Optimal glycemic regulation).\n"
              "• **Serum Creatinine** is **0.88 mg/dL** with eGFR > 90 (Optimal renal function).\n\n"
              "**Clinical Insight**: Mild isolated ALT elevation often relates to strenuous muscular training, supplement clearance, or minor metabolic strain. All other 13 biomarkers are optimal.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Lab Analysis • Clinical Context',
        bulletPoints: [
          'Stay well hydrated (2.5L daily).',
          'Avoid intense resistance training 48h before repeat lab test.',
          'Discuss your supplement stack with Dr. Sharma today.',
        ],
        actionLinks: const [
          AiActionLink(label: 'Open Full Lab Report', targetTabIndex: 3),
          AiActionLink(label: 'View Doctor Questions', targetTabIndex: 3, actionType: 'view_questions'),
        ],
      );
    }

    // 2. Context: Appointments / Doctors
    if (lower.contains('doctor') || lower.contains('sharma') || lower.contains('vance') || lower.contains('appointment') || lower.contains('visit') || lower.contains('clinic') || lower.contains('book')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "You have **1 upcoming appointment today** and **1 scheduled for next week**:\n\n"
              "1. **Dr. Priya Sharma, MD** (Internal Medicine & Hepatology)\n"
              "   • **Time**: Today at 10:30 AM (In ~2 hours)\n"
              "   • **Location**: Metro Center Health Pavilion, Suite 402\n"
              "   • **Preparation**: Bring your CMP report & supplement list.\n\n"
              "2. **Dr. Marcus Vance, FACC** (Cardiology)\n"
              "   • **Time**: Next week (Telehealth HD Video)\n"
              "   • **Status**: Confirmed, resting heart rate sync active.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Appointments • Schedule',
        actionLinks: const [
          AiActionLink(label: 'Go to Appointments', targetTabIndex: 2),
          AiActionLink(label: 'Book New Specialist', targetTabIndex: 2, actionType: 'book_new'),
        ],
      );
    }

    // 3. Context: Family Sharing / Permissions
    if (lower.contains('family') || lower.contains('david') || lower.contains('maya') || lower.contains('share') || lower.contains('permission') || lower.contains('caregiver')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Your **Family Health Sharing Hub** is currently managing 3 members:\n\n"
              "• **David Jenkins (Spouse)**: Full Caregiver Access (Vitals, Labs, Prescriptions & Emergency SOS enabled).\n"
              "• **Maya Jenkins (Daughter)**: Dependent Profile (Full guardian visibility).\n"
              "• **Eleanor Jenkins (Mother)**: Emergency SOS Contact Only (Lab records restricted).\n\n"
              "You can adjust granular permissions anytime or invite new family members via encrypted invite link.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Family Sharing • Privacy & Security',
        actionLinks: const [
          AiActionLink(label: 'Manage Family Sharing', targetTabIndex: 2, actionType: 'family_tab'),
        ],
      );
    }

    // 4. Context: Vitals / Heart Rate / Sleep / Steps
    if (lower.contains('vital') || lower.contains('heart') || lower.contains('bpm') || lower.contains('sleep') || lower.contains('step') || lower.contains('spo2') || lower.contains('oxygen') || lower.contains('blood pressure')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Here is your live biometric status for today:\n\n"
              "• **Resting Heart Rate**: **${state.restingHeartRate} bpm** (Well within the optimal athletic/healthy 60–80 bpm zone).\n"
              "• **Sleep**: **${state.sleepDuration}** (Deep & REM sleep architecture in high recovery range).\n"
              "• **Activity**: **${(state.dailySteps / 1000).toStringAsFixed(1)}k steps** (On track to reach 10,000 daily goal).\n"
              "• **Blood Oxygen (SpO2)**: **${state.bloodOxygen}%** (Excellent pulmonary oxygenation).\n"
              "• **Blood Pressure**: **${state.bloodPressure} mmHg** (Normal normotensive range).",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Biometrics • Live Vitals',
        actionLinks: const [
          AiActionLink(label: 'View Vitals Dashboard', targetTabIndex: 0),
        ],
      );
    }

    // 5. Context: Symptom / Triage / Pain / Headache / Fever
    if (lower.contains('headache') || lower.contains('pain') || lower.contains('symptom') || lower.contains('triage') || lower.contains('neck') || lower.contains('stiff') || lower.contains('fever') || lower.contains('sick')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Your active triage assessment for tension headache and neck stiffness is classified as **Moderate Attention (Window: 24–48 hrs)**.\n\n"
              "**Safe Home Guidance**:\n"
              "1. **Hydration**: Drink 500ml water immediately with electrolytes.\n"
              "2. **Posture & Ergonomics**: Follow the 20-20-20 screen rule.\n"
              "3. **Thermal Therapy**: Apply cool compress to forehead and warm towel to suboccipital neck muscles.\n\n"
              "⚠️ *Emergency Warning*: Seek immediate emergency care if you experience sudden thunderclap severity, high fever with stiff neck, or visual/speech disturbance.",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Clinical Triage • Protocol v4.2',
        actionLinks: const [
          AiActionLink(label: 'Open Symptom Triage', targetTabIndex: 1),
          AiActionLink(label: 'Book Consultation', targetTabIndex: 2),
        ],
      );
    }

    // 6. Context: App Features & Navigation help
    if (lower.contains('feature') || lower.contains('app') || lower.contains('how to') || lower.contains('help') || lower.contains('what can you do')) {
      return AiMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        text: "Welcome to **Health Companion (Serene Clinical)**! I am your 24/7 AI Health Copilot available across the entire app.\n\n"
              "Here is what you can do:\n\n"
              "1. 🏠 **Health Companion Home**: Live vitals (Heart rate, Sleep, Steps), medication reminders, and diagnostic summary.\n"
              "2. 🩺 **Symptom Triage Assistant**: Voice & text clinical triage with urgency classification, audio summaries, and safe home self-care.\n"
              "3. 📅 **Appointments & Family Sharing**: Manage doctor visits (in-person & telehealth) and share records with loved ones.\n"
              "4. 📊 **Lab Report Interpreter**: Upload lab PDFs or photos, review biomarker explanations, and prepare doctor discussion questions.\n"
              "5. 💬 **Global AI Copilot**: Ask me any question at any time!",
        sender: AiSender.assistant,
        timestamp: DateTime.now(),
        contextualBadge: 'Health Companion Guide',
        actionLinks: const [
          AiActionLink(label: 'Explore Home Hub', targetTabIndex: 0),
          AiActionLink(label: 'Check Symptoms', targetTabIndex: 1),
          AiActionLink(label: 'View Lab Reports', targetTabIndex: 3),
        ],
      );
    }

    // General Health Query fallback
    return AiMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      text: "Thank you for asking about **\"$query\"**.\n\n"
            "As your Serene Clinical AI Copilot, I've analyzed this in relation to your personal health profile (Sarah Jenkins, Blood Group A+, resting heart rate ${state.restingHeartRate} bpm, and latest CMP lab work).\n\n"
            "• **Key Insight**: Maintaining balanced hydration, consistent circadian rhythm, and regular biomarker monitoring supports optimal vitality.\n"
            "• **Personalized Context**: You can cross-reference your latest reports or discuss this during your consultation with Dr. Sharma today at 10:30 AM.",
      sender: AiSender.assistant,
      timestamp: DateTime.now(),
      contextualBadge: 'Clinical AI Copilot Response',
      bulletPoints: [
        'All guidance follows evidence-based medical literature.',
        'Not a substitute for formal diagnostic testing or personalized physician directives.',
      ],
      actionLinks: const [
        AiActionLink(label: 'View Today\'s Appointments', targetTabIndex: 2),
        AiActionLink(label: 'Check Biomarkers', targetTabIndex: 3),
      ],
    );
  }
}
