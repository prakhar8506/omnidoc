import 'package:flutter/material.dart';
import '../../../core/branding/app_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/holographic_background.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
                    Text('Terms of Use', style: AppTypography.editorialSm),
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
                      'Agreement',
                      'By using ${AppBrand.name}, you agree to these Terms. If you do not agree, do not use the app.',
                    ),
                    _card(
                      'Not medical care',
                      '${AppBrand.name} provides organizational tools and informational AI assistance only. It is not a medical device, does not create a doctor–patient relationship, and must not be used for emergency decision-making. In an emergency, call local emergency services.',
                    ),
                    _card(
                      'Accounts',
                      'You are responsible for your credentials and for the accuracy of information you enter. Do not upload documents you are not allowed to share.',
                    ),
                    _card(
                      'AI & lab features',
                      'Automated reading of labs and AI chat may err or miss content. Always verify with a qualified clinician before acting on outputs.',
                    ),
                    _card(
                      'Limitation of liability',
                      'To the fullest extent permitted by law, ${AppBrand.legalEntity} is not liable for indirect, incidental, or consequential damages arising from use of the app or reliance on AI/lab summaries.',
                    ),
                    _card('Contact', AppBrand.supportEmail),
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
