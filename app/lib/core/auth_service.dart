// ignore_for_file: slash_for_doc_comments
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';

/**
 * State provider managing authentication lifecycle, network login, and registration.
 *
 * <p>Extends {@link ChangeNotifier} to notify screens when auth status changes
 * (e.g. redirecting from login screen to home dashboard on success).</p>
 */
class AuthService extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();

  String? _token;
  String? _userId;
  String? _userEmail;
  bool _isLoading = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  /**
   * Attempt to load an existing secure session on startup.
   */
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasSession = await _secureStorage.hasSession();
      if (hasSession) {
        _token = await _secureStorage.getToken();
        _userId = await _secureStorage.getUserId();
        _userEmail = await _secureStorage.getUserEmail();
      }
    } catch (e) {
      // Session load failed (corrupted secure storage, etc.) — clear state
      await _secureStorage.clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Send login credentials to the Spring Boot backend.
   *
   * @throws Exception describing the error message returned by the server
   */
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful login
        _token = responseBody['token'];
        _userEmail = responseBody['email'];
        // Defaulting ID to stub for now since backend token payload acts as verification
        _userId = '1'; 

        await _secureStorage.saveSession(
          token: _token!,
          userId: _userId!,
          email: _userEmail!,
        );
      } else {
        // Handle standardized ApiError format
        final errorMessage = responseBody['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
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
      final response = await http.post(
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
        // Registration success. User can now transition to login.
        return;
      } else {
        final responseBody = jsonDecode(response.body);
        if (responseBody['fieldErrors'] != null) {
          // Flatten field-level validation errors
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          final validationMsg = errors.values.join(', ');
          throw Exception(validationMsg);
        }
        final errorMessage = responseBody['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Clear auth session and remove local security credentials.
   */
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _secureStorage.clearSession();
    _token = null;
    _userId = null;
    _userEmail = null;

    _isLoading = false;
    notifyListeners();
  }
}
