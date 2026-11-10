// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> openUrl(String url) async {
  try {
    if (url.startsWith('tel:')) {
      html.window.location.href = url;
    } else {
      html.window.open(url, '_blank');
    }
    return true;
  } catch (e) {
    return false;
  }
}

