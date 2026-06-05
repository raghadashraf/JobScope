import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import 'settings_scaffold.dart';

enum LegalDocumentType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalDocumentType type;
  const LegalScreen({super.key, required this.type});

  static const privacyUrl = 'https://jobscope.app/privacy';
  static const termsUrl = 'https://jobscope.app/terms';

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalDocumentType.privacy;
    final title = isPrivacy ? 'Privacy policy' : 'Terms of service';
    final url = isPrivacy ? privacyUrl : termsUrl;
    final body = isPrivacy ? _privacyText : _termsText;

    return SettingsScaffold(
      title: title,
      actions: [
        TextButton(
          onPressed: () => _openUrl(context, url),
          child: Text(
            'Open link',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
      child: Text(
        body,
        style: GoogleFonts.inter(fontSize: 14, height: 1.55),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

const _privacyText = '''
JobScope Privacy Policy (demo)

We collect account information (email, name, role), CV files you upload, job applications, messages, and notification preferences stored on your device.

Data is stored in Firebase (Firestore, Storage, Auth) under project flutter-ai-playground-2379c, database jobscope.

We do not sell personal data. For a production app, replace this text with counsel-reviewed policy and host it at your domain.

Contact: support@jobscope.app
''';

const _termsText = '''
JobScope Terms of Service (demo)

By using JobScope you agree to use the app for lawful job search and hiring purposes. Listings and applications must be accurate. AI features provide guidance only and do not guarantee employment outcomes.

Accounts may be suspended for abuse. The service is provided as-is for educational demonstration.

For production, replace with formal terms and host at your domain.

Contact: support@jobscope.app
''';
