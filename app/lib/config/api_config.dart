// ignore_for_file: slash_for_doc_comments
import 'dart:io';
import 'package:flutter/foundation.dart';

/**
 * Global configuration for API endpoints and connection settings.
 *
 * <h2>Environment Routing</h2>
 * <ul>
 *   <li><strong>Production (Release Build):</strong> Defaults automatically to
 *       `https://back2kasi-api.back2kasi.workers.dev`.</li>
 *   <li><strong>Local Dev (Debug Build):</strong> Connects to local Wrangler dev server (port 8787).</li>
 *   <li><strong>Override:</strong> Pass `--dart-define=API_BASE_URL=https://...` at build time.</li>
 * </ul>
 */
class ApiConfig {
  // Override this local IP when testing on a physical device.
  static const String _hostPcIp = '192.168.1.100'; 
  
  // Environment variable set at build-time using: --dart-define=API_BASE_URL=https://...
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  
  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl;
    }

    // In release mode (production), default to live Cloudflare Worker API
    if (kReleaseMode) {
      return 'https://back2kasi-api.back2kasi.workers.dev';
    }

    if (kIsWeb) {
      return 'http://localhost:8787';
    }

    // Local development routing (port 8787)
    if (Platform.isAndroid) {
      // 10.0.2.2 is Android emulator alias to host machine
      return 'http://10.0.2.2:8787';
    } else if (Platform.isIOS || Platform.isWindows) {
      return 'http://localhost:8787';
    }
    // Fallback/physical device route
    return 'http://$_hostPcIp:8787';
  }

  // --- Auth endpoints ---
  static String get register => '$baseUrl/api/users/register';
  static String get login => '$baseUrl/api/users/login';
  static String get refresh => '$baseUrl/api/users/refresh';
  static String get logout => '$baseUrl/api/users/logout';
  static String get sessions => '$baseUrl/api/users/sessions';
  static String get revokeAllSessions => '$baseUrl/api/users/sessions/revoke-all';

  // --- Resource endpoints ---
  static String get businesses => '$baseUrl/api/v1/businesses';
  static String get myBusinesses => '$baseUrl/api/v1/businesses/my';
  static String businessContactSettings(int id) => '$businesses/$id/contact-settings';
  static String businessContact(int id) => businessContactSettings(id);
  static String get rentalUnits => '$baseUrl/api/v1/rental-units';
  static String get catalogueItems => '$baseUrl/api/v1/catalogue-items';
  static String catalogueItemsByBusiness(int businessId) =>
      '$catalogueItems?businessId=$businessId';
  static String get bookings => '$baseUrl/api/v1/bookings';
  static String bookingContact(int id) => '$bookings/$id/contact';

  // --- Image management endpoints ---
  static String rentalUnitImages(int unitId) => '$rentalUnits/$unitId/images';
  static String rentalUnitImagePrimary(int unitId, int imageId) =>
      '$rentalUnits/$unitId/images/$imageId/primary';
  static String rentalUnitImageDelete(int unitId, int imageId) =>
      '$rentalUnits/$unitId/images/$imageId';

  /**
   * Resolves relative image endpoints (e.g. /api/v1/images/...) into fully qualified URLs.
   */
  static String? resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$baseUrl$path';
  }
}
