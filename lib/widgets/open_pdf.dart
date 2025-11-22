import 'package:url_launcher/url_launcher.dart';
import 'package:project_flutter/server_url.dart';

/// Opens PDF in external browser.
/// Returns true if launch succeeded, false otherwise.
Future<bool> openPdf(String path) async {
  final uri = Uri.parse(kNgrokBase + path.trim());
  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
    );
  } catch (_) {
    return false;
  }
}