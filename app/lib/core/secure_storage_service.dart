// ignore_for_file: slash_for_doc_comments, doc_directive_unknown
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 * Service to securely store user credentials and tokens on the device.
 *
 * <p>Uses the hardware-backed keystore/keychain through the
 * {@link FlutterSecureStorage} plugin. Persists the JWT token across app relaunches
 * so the user remains authenticated without logging in every session.</p>
 */
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';

  /**
   * Save the authenticated session details.
   */
  Future<void> saveSession({
    required String token,
    required String userId,
    required String email,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /**
   * Read the saved JWT token. Returns {@code null} if no session exists.
   */
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  /**
   * Read the saved user ID. Returns {@code null} if no session exists.
   */
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /**
   * Read the saved user email. Returns {@code null} if no session exists.
   */
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /**
   * Clear all session data (logout operation).
   */
  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
  }

  /**
   * Check whether a valid login session exists on the device.
   */
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
