import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Opens a Firebase Storage download URL (PDF/DOCX) in the browser or external app.
Future<bool> openFileUrl(String url) async {
  if (url.isEmpty) return false;
  final uri = Uri.parse(url);
  if (kIsWeb) {
    return launchUrl(uri, webOnlyWindowName: '_blank');
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
