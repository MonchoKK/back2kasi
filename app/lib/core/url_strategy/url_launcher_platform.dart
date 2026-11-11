import 'package:url_launcher/url_launcher.dart' as ul;

/**
 * Universal URL launcher supporting Android, iOS, Web, and Desktop.
 * Uses externalApplication mode to properly trigger native apps (WhatsApp, Phone dialer).
 */
Future<bool> openUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    return await ul.launchUrl(
      uri,
      mode: ul.LaunchMode.externalApplication,
    );
  } catch (e) {
    return false;
  }
}
