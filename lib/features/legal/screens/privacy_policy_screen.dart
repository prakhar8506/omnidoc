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
                    Text('Last updated: September 18, 2026', style: AppTypography.labelSm),
                    const SizedBox(height: 20),
                    _card(
                      'Overview',
                      '${AppBrand.name} helps you organize personal health information, wearable trends, appointments, and lab documents. ${AppBrand.name} is not a medical device and does not provide diagnosis or treatment.',
                    ),
                    _card(
                      'Data we collect',
                      'Account data (email, display name), health inputs you enter, wearable metrics you authorize (heart rate, steps, sleep via Apple Health / Health Connect), uploaded documents, and diagnostics needed for reliability.',
                    ),
                    _card(
                      'How we use data',
                      'We authenticate you, sync records to your private cloud account, power optional AI summaries you request, and keep the service reliable. We do not sell your health data.',
                    ),
                    _card(
                      'AI processing',
                      'AI chat and lab reading send relevant content to our edge functions and may use a contracted AI provider (e.g. Google Gemini) solely to fulfill your request. Outputs are informational and may be incomplete — confirm with a clinician.',
                    ),
                    _card(
                      'Storage & security',
                      'Account data is stored in Supabase with row-level security. Local caches may keep recent data for offline use. Use a strong password and keep your device locked.',
                    ),
                    _card(
                      'Retention & deletion',
                      'Delete your account in Profile → Delete Account. This removes application data for your user id and requests auth account removal. Backups may persist briefly before purge.',
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
