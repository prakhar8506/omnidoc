import 'package:flutter/material.dart';
import '../../../core/branding/app_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/holographic_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HolographicBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    const SizedBox(width: 4),
                    Text('Privacy Policy', style: AppTypography.editorialSm),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    Text(AppBrand.name, style: AppTypography.editorialLg),
                    const SizedBox(height: 4),
                    Text(AppBrand.tagline, style: AppTypography.labelSm),
                    const SizedBox(height: 8),
                    Text('Last updated: September 28, 2026', style: AppTypography.labelSm),
                    const SizedBox(height: 20),
                    _card(
                      'Overview',
                      '${AppBrand.name} helps you organize personal health information, wearable trends, appointments, and lab documents. ${AppBrand.name} is not a medical device and does not provide diagnosis or treatment.',
                    ),
                    _card(
                      'Who can use Cura',
                      'Cura is for adults aged 18 and over. We do not knowingly collect information from children. If you believe a child has created an account, write to ${AppBrand.supportEmail} and we will remove it.',
                    ),
                    _card(
                      'Data we collect',
                      'Account details you give us (email address, display name, blood type).\n\n'
                          'Health information you enter: journal reflections, symptoms you describe, mood and mental-health screening answers, meals and water, medications, allergies, chronic conditions, menstrual cycle and pregnancy logs, glucose and blood pressure readings, and emergency contacts.\n\n'
                          'Wearable metrics you authorize through Apple Health or Health Connect: heart rate, resting heart rate, heart rate variability, steps, sleep, oxygen saturation, and blood pressure.\n\n'
                          'Documents you upload: photos and PDFs of lab reports and prescriptions, and the text read from them.\n\n'
                          'The city you type when searching for a doctor.\n\n'
                          'Crash and performance diagnostics, so we can fix errors.',
                    ),
                    _card(
                      'How we use data',
                      'We authenticate you, sync your records to your private cloud account, produce the summaries and explanations you ask for, and keep the service reliable. We do not sell your health data and we do not use it for advertising.',
                    ),
                    _card(
                      'AI processing',
                      'When you use AI chat, symptom guidance, or lab report reading, the relevant content is sent to our own server functions and then to an AI provider we contract with — currently OpenAI, with Google Gemini as a fallback — purely to answer that request.\n\n'
                          'For lab reports this can include the report image itself, or the text read from it, together with a short summary of your medications and recent metrics so the explanation makes sense. Providers process this on our behalf and are not permitted to use it to train their models.\n\n'
                          'AI output is informational, can be incomplete or wrong, and is never a diagnosis. Confirm anything that matters with a clinician.',
                    ),
                    _card(
                      'Crash and performance reporting',
                      'We use Sentry to receive crash reports and performance traces. These contain technical details such as the error, screen, device model, and operating system version. They are not used to identify you and they do not carry your health records.',
                    ),
                    _card(
                      'Storage & security',
                      'Cloud data is stored in Supabase with row-level security so only your account can read it. A copy is kept on your phone so the app works offline; that copy is excluded from Google and Apple device backups. Use a strong password and keep your device locked.',
                    ),
                    _card(
                      'Retention & deletion',
                      'Tap your avatar in the top bar, then Delete Account. That removes your cloud records, uploaded documents, and auth account, and erases the copy stored on this phone, including your saved profile and local health history. It cannot be undone. Server backups may retain data briefly before they rotate out.',
                    ),
                    _card(
                      'Your choices',
                      'You can turn individual wearable categories on or off in the permission centre, export your data as a PDF at any time, and delete your account entirely. Denying a permission does not stop you from using the rest of the app.',
                    ),
                    _card(
                      'Public copy',
                      'A hosted copy of this policy is at ${AppBrand.privacyPolicyUrl}',
                    ),
                    _card(
                      'Contact',
                      '${AppBrand.legalEntity}\n${AppBrand.supportEmail}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMd),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
