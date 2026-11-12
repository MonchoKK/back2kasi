// ignore_for_file: slash_for_doc_comments
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';

/**
 * State provider managing authentication lifecycle, network login, registration,
 * secure token storage, session restoration, and token rotation (Sprint 33).
 *
 * <p>Extends {@link ChangeNotifier} to notify screens when auth status changes
 * (e.g. redirecting from login screen to home dashboard on success or logout).</p>
 */
class AuthService extends ChangeNotifier {
  final SecureStorageService _secureStorage;
  final http.Client _client;

  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _userRole;
  DateTime? _expiresAt;
  bool _isLoading = false;

  // Concurrency guard to prevent multiple refresh calls from colliding
  Completer<String?>? _refreshCompleter;

  AuthService({
    SecureStorageService? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _client = client ?? http.Client();

  String? get token => _token;
  String? get refreshTokenString => _refreshToken;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userRole => _userRole;
  DateTime? get expiresAt => _expiresAt;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /**
   * Checks whether the current access token is within 60 seconds of expiring,
   * or has already expired.
   */
  bool get isTokenExpiringSoon {
    if (_expiresAt == null) return false;
    final cutoff = _expiresAt!.subtract(const Duration(seconds: 60));
    return DateTime.now().isAfter(cutoff);
  }

  /**
   * Returns a valid access token. If the current token is close to expiry
   * and a refresh token is present, it will automatically refresh the session first.
   */
  Future<String?> getValidToken() async {
    if (!isAuthenticated) return null;

    if (_refreshToken != null && isTokenExpiringSoon) {
      debugPrint('AuthService: Access token expiring soon, refreshing proactively...');
      final renewed = await refreshToken();
      if (renewed != null) return renewed;
    }

    return _token;
  }

  /**
   * Attempt to load and restore an existing secure session on startup.
   */
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final storedRefreshToken = await _secureStorage.getRefreshToken();
      final storedToken = await _secureStorage.getToken();
      final storedUserId = await _secureStorage.getUserId();
      final storedUserEmail = await _secureStorage.getUserEmail();
      final storedUserName = await _secureStorage.getUserName();
      final storedUserRole = await _secureStorage.getUserRole();
      final storedExpiresAt = await _secureStorage.getExpiresAt();

      if (storedRefreshToken == null && storedToken == null) {
        // No saved credentials on device
        _clearInMemoryState();
        return;
      }

      // Check if access token is present and still valid
      final bool tokenIsFresh = storedToken != null &&
          storedToken.isNotEmpty &&
          storedExpiresAt != null &&
          DateTime.now().isBefore(storedExpiresAt.subtract(const Duration(seconds: 60)));

      if (tokenIsFresh) {
        _token = storedToken;
        _refreshToken = storedRefreshToken;
        _userId = storedUserId ?? '1';
        _userEmail = storedUserEmail ?? '';
        _userName = storedUserName;
        _userRole = storedUserRole;
        _expiresAt = storedExpiresAt;
        debugPrint('AuthService: Session restored directly with valid access token');
        return;
      }

      // If access token is expired or missing, but refresh token exists: renew immediately
      if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
        debugPrint('AuthService: Access token expired/missing, renewing via refresh token...');
        _refreshToken = storedRefreshToken;
        _userId = storedUserId;
        _userEmail = storedUserEmail;
        _userName = storedUserName;
        _userRole = storedUserRole;

        final newToken = await refreshToken();
        if (newToken != null) {
          debugPrint('AuthService: Session restoration successful via token refresh');
          return;
        } else {
          debugPrint('AuthService: Refresh failed during auto-login, clearing session');
          await _clearLocalSession();
        }
      } else if (storedToken != null && storedToken.isNotEmpty) {
        // Legacy fallback: single token without refresh token
        _token = storedToken;
        _userId = storedUserId ?? '1';
        _userEmail = storedUserEmail ?? '';
        _userName = storedUserName;
        _userRole = storedUserRole;
        _expiresAt = storedExpiresAt;
      }
    } catch (e) {
      debugPrint('AuthService: tryAutoLogin error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Refreshes the access token using the stored refresh token.
   * Employs token rotation: server revokes the old refresh token and issues a new pair.
   *
   * @return The new access token on success, or null if refresh fails.
   */
  Future<String?> refreshToken() async {
    final tokenToUse = _refreshToken;
    if (tokenToUse == null || tokenToUse.isEmpty) {
      return null;
    }

    // Concurrency guard: return existing refresh in flight
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': tokenToUse,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['token'] as String;
        final newRefreshToken = (data['refreshToken'] as String?) ?? tokenToUse;
        final expiresIn = (data['expiresIn'] as num?)?.toInt() ?? 3600;
        final newExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        _token = newAccessToken;
        _refreshToken = newRefreshToken;
        _expiresAt = newExpiresAt;

        if (data['user'] is Map<String, dynamic>) {
          final userMap = data['user'] as Map<String, dynamic>;
          _userId = userMap['id']?.toString() ?? _userId;
          _userEmail = userMap['email'] ?? _userEmail;
          final first = userMap['firstName'] ?? '';
          final last = userMap['lastName'] ?? '';
          final fullName = '$first $last'.trim();
          if (fullName.isNotEmpty) _userName = fullName;
          _userRole = userMap['role'] ?? _userRole;
        }

        await _secureStorage.updateTokens(
          token: newAccessToken,
          refreshToken: newRefreshToken,
          expiresAt: newExpiresAt,
        );

        notifyListeners();
        _refreshCompleter?.complete(newAccessToken);
        return newAccessToken;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Session expired or revoked on server
        debugPrint('AuthService: Server rejected refresh token (${response.statusCode}). Terminating session.');
        await _clearLocalSession();
        notifyListeners();
        _refreshCompleter?.complete(null);
        return null;
      } else {
        debugPrint('AuthService: Token refresh encountered unexpected status ${response.statusCode}');
        _refreshCompleter?.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('AuthService: Token refresh network error: $e');
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /**
   * Send login credentials to the backend.
   *
   * @throws Exception describing the error message returned by the server
   */
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        _token = responseBody['token'];
        _refreshToken = responseBody['refreshToken'];

        final expiresIn = (responseBody['expiresIn'] as num?)?.toInt() ?? 3600;
        _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        if (responseBody['user'] is Map<String, dynamic>) {
          final userMap = responseBody['user'] as Map<String, dynamic>;
          _userId = userMap['id']?.toString() ?? '1';
          _userEmail = userMap['email'] ?? email;
          final first = userMap['firstName'] ?? '';
          final last = userMap['lastName'] ?? '';
          _userName = '$first $last'.trim();
          _userRole = userMap['role'] ?? 'USER';
        } else {
          _userEmail = responseBody['email'] ?? email;
          _userId = '1';
          _userName = null;
          _userRole = 'USER';
        }

        await _secureStorage.saveSession(
          token: _token!,
          refreshToken: _refreshToken ?? '',
          userId: _userId!,
          email: _userEmail!,
          name: _userName,
          role: _userRole,
          expiresAt: _expiresAt,
        );
      } else {
        String errorMessage = 'Login failed (HTTP ${response.statusCode})';
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic> && responseBody['message'] != null) {
            errorMessage = responseBody['message'];
          }
        } catch (_) {
          if (response.statusCode == 404) {
            errorMessage = 'Backend endpoint not found (HTTP 404). Please verify the server URL.';
          } else if (response.statusCode >= 500) {
            errorMessage = 'Server error (HTTP ${response.statusCode}). Please check if backend is running.';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _handleNetworkError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Register a new user account.
   *
   * @throws Exception with field validation errors or generic failure message
   */
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 201) {
        return;
      } else {
        String errorMessage = 'Registration failed (HTTP ${response.statusCode})';
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic>) {
            if (responseBody['fieldErrors'] != null) {
              final Map<String, dynamic> errors = responseBody['fieldErrors'];
              throw Exception(errors.values.join(', '));
            }
            if (responseBody['message'] != null) {
              errorMessage = responseBody['message'];
            }
          }
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
          if (response.statusCode == 404) {
            errorMessage = 'Backend endpoint not found (HTTP 404). Please verify the server URL.';
          } else if (response.statusCode >= 500) {
            errorMessage = 'Server error (HTTP ${response.statusCode}). Please check if backend is running.';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _handleNetworkError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleNetworkError(dynamic e) {
    if (e is FormatException) {
      throw Exception('Server returned an unexpected response format. Please try again later.');
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('clientexception') ||
        msg.contains('timeoutexception') ||
        msg.contains('connection reset')) {
      throw Exception('Unable to connect to server. Please check your internet connection and try again.');
    }
    throw e;
  }

  /**
   * Terminate the session cleanly: notify backend to revoke the session in D1,
   * then wipe local secure storage and notify UI listeners.
   */
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final currentRefreshToken = _refreshToken;
    final currentToken = _token;

    // Fire backend revocation in background (best effort)
    if (currentRefreshToken != null || currentToken != null) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (currentToken != null) {
          headers['Authorization'] = 'Bearer $currentToken';
        }
        await _client.post(
          Uri.parse(ApiConfig.logout),
          headers: headers,
          body: jsonEncode({
            'refreshToken': currentRefreshToken,
          }),
        );
      } catch (e) {
        debugPrint('AuthService: Server logout notification failed: $e');
      }
    }

    await _clearLocalSession();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    await _secureStorage.clearSession();
    _clearInMemoryState();
  }

  void _clearInMemoryState() {
    _token = null;
    _refreshToken = null;
    _userId = null;
    _userEmail = null;
    _userName = null;
    _userRole = null;
    _expiresAt = null;
  }
}
