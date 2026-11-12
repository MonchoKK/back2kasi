// ignore_for_file: slash_for_doc_comments, doc_directive_unknown
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 * Service to securely store user credentials, refresh tokens, and session state on the device.
 *
 * <p>Uses the hardware-backed keystore/keychain through the {@link FlutterSecureStorage} plugin.
 * Persists both short-lived access tokens and long-lived refresh tokens across app relaunches
 * so the user remains authenticated without logging in every session (Sprint 33).</p>
 */
class SecureStorageService {
  final FlutterSecureStorage? _storage;
  final Map<String, String>? _inMemoryFallback;

  SecureStorageService({
    FlutterSecureStorage? storage,
    Map<String, String>? inMemoryStorage,
  })  : _storage = inMemoryStorage == null
            ? (storage ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(
                    encryptedSharedPreferences: true,
                  ),
                ))
            : null,
        _inMemoryFallback = inMemoryStorage;

  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyExpiresAt = 'auth_expires_at';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserRole = 'auth_user_role';

  Future<void> _write(String key, String value) async {
    if (_inMemoryFallback != null) {
      _inMemoryFallback[key] = value;
      return;
    }
    await _storage?.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (_inMemoryFallback != null) {
      return _inMemoryFallback[key];
    }
    return await _storage?.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (_inMemoryFallback != null) {
      _inMemoryFallback.remove(key);
      return;
    }
    await _storage?.delete(key: key);
  }

  /**
   * Save the full authenticated session details after login or registration.
   */
  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userId,
    required String email,
    String? name,
    String? role,
    DateTime? expiresAt,
  }) async {
    await _write(_keyToken, token);
    await _write(_keyRefreshToken, refreshToken);
    await _write(_keyUserId, userId);
    await _write(_keyUserEmail, email);

    if (name != null) {
      await _write(_keyUserName, name);
    }
    if (role != null) {
      await _write(_keyUserRole, role);
    }
    if (expiresAt != null) {
      await _write(_keyExpiresAt, expiresAt.toIso8601String());
    }
  }

  /**
   * Update rotated access and refresh tokens without modifying user profile data.
   */
  Future<void> updateTokens({
    required String token,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _write(_keyToken, token);
    await _write(_keyRefreshToken, refreshToken);
    if (expiresAt != null) {
      await _write(_keyExpiresAt, expiresAt.toIso8601String());
    }
  }

  /**
   * Read the saved JWT access token. Returns {@code null} if no session exists.
   */
  Future<String?> getToken() async {
    return await _read(_keyToken);
  }

  /**
   * Read the saved long-lived refresh token. Returns {@code null} if no session exists.
   */
  Future<String?> getRefreshToken() async {
    return await _read(_keyRefreshToken);
  }

  /**
   * Read the expiration timestamp of the current access token.
   */
  Future<DateTime?> getExpiresAt() async {
    final raw = await _read(_keyExpiresAt);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /**
   * Read the saved user ID. Returns {@code null} if no session exists.
   */
  Future<String?> getUserId() async {
    return await _read(_keyUserId);
  }

  /**
   * Read the saved user email. Returns {@code null} if no session exists.
   */
  Future<String?> getUserEmail() async {
    return await _read(_keyUserEmail);
  }

  /**
   * Read the saved user display name.
   */
  Future<String?> getUserName() async {
    return await _read(_keyUserName);
  }

  /**
   * Read the saved user role.
   */
  Future<String?> getUserRole() async {
    return await _read(_keyUserRole);
  }

  /**
   * Clear all session data (logout operation).
   */
  Future<void> clearSession() async {
    await _delete(_keyToken);
    await _delete(_keyRefreshToken);
    await _delete(_keyExpiresAt);
    await _delete(_keyUserId);
    await _delete(_keyUserEmail);
    await _delete(_keyUserName);
    await _delete(_keyUserRole);
  }

  /**
   * Check whether a valid login session exists on the device (either refresh token or access token).
   */
  Future<bool> hasSession() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) return true;
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
