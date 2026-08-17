// ignore_for_file: slash_for_doc_comments
import 'dart:io';

/**
 * Global configuration for API endpoints and connection settings.
 *
 * <h2>Local Development Networking</h2>
 * <p>When connecting to a Spring Boot service running on {@code localhost:8080}
 * from a mobile client, the default "localhost" loopback points to the mobile
 * device itself, not the hosting computer.</p>
 *
 * <ul>
 *   <li><strong>Android Emulator:</strong> Routes traffic through {@code 10.0.2.2:8080}.</li>
 *   <li><strong>iOS Simulator:</strong> Renders on the host network, so {@code localhost:8080} works directly.</li>
 *   <li><strong>Physical Device:</strong> Requires the host PC's local IP address (e.g. {@code 192.168.1.100:8080})
 *       and both devices must be connected to the same Wi-Fi network.</li>
 * </ul>
 */
class ApiConfig {
  // Override this local IP when testing on a physical device.
  static const String _hostPcIp = '192.168.1.100'; 
  
  static String get baseUrl {
    // If we are running in a web context, Platform.isAndroid will throw.
    // However, since this is a pure mobile setup (Android/iOS), Platform is safe.
    if (Platform.isAndroid) {
      // 10.0.2.2 is Android's special alias to the host machine's loopback interface.
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS || Platform.isWindows) {
      return 'http://localhost:8080';
    }
    // Fallback/physical device route
    return 'http://$_hostPcIp:8080';
  }

  // --- Auth endpoints ---
  static String get register => '$baseUrl/api/users/register';
  static String get login => '$baseUrl/api/users/login';

  // --- Resource endpoints ---
  static String get businesses => '$baseUrl/api/v1/businesses';
  static String get rentalUnits => '$baseUrl/api/v1/rental-units';
  static String get bookings => '$baseUrl/api/v1/bookings';
}
