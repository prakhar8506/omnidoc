import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../branding/app_brand.dart';

/// Labels an assistant reply and opens a mail report. The draft is not
/// uploaded anywhere except the mail app the person chooses.
class AiDraftNotice extends StatelessWidget {
  const AiDraftNotice({super.key, required this.draft});

  final String draft;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Text(
          'AI draft',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.6)),
        ),
        const Spacer(),
        TextButton(
          onPressed: draft.trim().isEmpty ? null : () => reportAiDraft(context, draft),
          child: const Text('Report this draft'),
        ),
      ],
    );
  }
}

Future<void> reportAiDraft(BuildContext context, String draft) async {
  final clipped = draft.length > 2000 ? '${draft.substring(0, 2000)}…' : draft;
  final uri = Uri(
    scheme: 'mailto',
    path: AppBrand.supportEmail,
    queryParameters: {
      'subject': 'Report an AI draft',
      'body': 'Please review this AI draft. It is not a diagnosis.\n\n$clipped',
    },
  );
  final opened = await launchUrl(uri);
  if (!context.mounted || opened) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Email ${AppBrand.supportEmail} with the subject “Report an AI draft”.')),
  );
}
