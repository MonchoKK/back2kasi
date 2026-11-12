import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:back2kasi_app/config/api_config.dart';
import 'package:back2kasi_app/core/auth_service.dart';
import 'package:back2kasi_app/core/authenticated_http_client.dart';
import 'package:back2kasi_app/core/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sprint 33: SecureStorageService', () {
    late SecureStorageService storage;
    late Map<String, String> inMemory;

    setUp(() {
      inMemory = {};
      storage = SecureStorageService(inMemoryStorage: inMemory);
    });

    test('saveSession persists access token, refresh token, expiry, and profile', () async {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      await storage.saveSession(
        token: 'access_jwt_123',
        refreshToken: 'refresh_hex_abc',
        userId: '42',
        email: 'bongi@example.com',
        name: 'Bongi Ndlovu',
        role: 'USER',
        expiresAt: expiry,
      );

      expect(await storage.getToken(), 'access_jwt_123');
      expect(await storage.getRefreshToken(), 'refresh_hex_abc');
      expect(await storage.getUserId(), '42');
      expect(await storage.getUserEmail(), 'bongi@example.com');
      expect(await storage.getUserName(), 'Bongi Ndlovu');
      expect(await storage.getUserRole(), 'USER');
      final readExpiry = await storage.getExpiresAt();
      expect(readExpiry, isNotNull);
      expect(readExpiry!.difference(expiry).inSeconds.abs(), lessThan(2));
      expect(await storage.hasSession(), isTrue);
    });

    test('updateTokens updates tokens and expiry without overwriting user profile', () async {
      await storage.saveSession(
        token: 'old_access',
        refreshToken: 'old_refresh',
        userId: '42',
        email: 'bongi@example.com',
        name: 'Bongi Ndlovu',
      );

      final newExpiry = DateTime.now().add(const Duration(hours: 2));
      await storage.updateTokens(
        token: 'new_access',
        refreshToken: 'new_refresh',
        expiresAt: newExpiry,
      );

      expect(await storage.getToken(), 'new_access');
      expect(await storage.getRefreshToken(), 'new_refresh');
      expect(await storage.getUserEmail(), 'bongi@example.com');
      expect(await storage.getUserName(), 'Bongi Ndlovu');
    });

    test('clearSession wipes all stored credentials', () async {
      await storage.saveSession(
        token: 'to_delete',
        refreshToken: 'to_delete_refresh',
        userId: '1',
        email: 'test@example.com',
      );
      expect(await storage.hasSession(), isTrue);

      await storage.clearSession();
      expect(await storage.getToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserId(), isNull);
      expect(await storage.hasSession(), isFalse);
    });
  });

  group('Sprint 33: AuthService Session Management', () {
    late SecureStorageService storage;
    late Map<String, String> inMemory;

    setUp(() {
      inMemory = {};
      storage = SecureStorageService(inMemoryStorage: inMemory);
    });

    test('login successfully populates tokens and persists session', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.login) {
          return http.Response(
            jsonEncode({
              'token': 'mock_access_jwt',
              'refreshToken': 'mock_refresh_token_xyz',
              'tokenType': 'Bearer',
              'expiresIn': 3600,
              'user': {
                'id': 7,
                'email': 'sipho@example.com',
                'firstName': 'Sipho',
                'lastName': 'Khumalo',
                'role': 'USER',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockClient);

      await authService.login('sipho@example.com', 'Pass123!');

      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, 'mock_access_jwt');
      expect(authService.refreshTokenString, 'mock_refresh_token_xyz');
      expect(authService.userId, '7');
      expect(authService.userEmail, 'sipho@example.com');
      expect(authService.userName, 'Sipho Khumalo');

      // Check persistent storage
      expect(await storage.getToken(), 'mock_access_jwt');
      expect(await storage.getRefreshToken(), 'mock_refresh_token_xyz');
    });

    test('tryAutoLogin restores session directly if access token is fresh', () async {
      final futureExpiry = DateTime.now().add(const Duration(minutes: 30));
      await storage.saveSession(
        token: 'cached_fresh_token',
        refreshToken: 'cached_refresh_token',
        userId: '15',
        email: 'fresh@example.com',
        name: 'Fresh User',
        expiresAt: futureExpiry,
      );

      final authService = AuthService(secureStorage: storage);
      await authService.tryAutoLogin();

      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, 'cached_fresh_token');
      expect(authService.userEmail, 'fresh@example.com');
      expect(authService.userName, 'Fresh User');
    });

    test('tryAutoLogin automatically refreshes expired access token on app launch', () async {
      final expiredTime = DateTime.now().subtract(const Duration(minutes: 10));
      await storage.saveSession(
        token: 'expired_access_token',
        refreshToken: 'valid_refresh_token',
        userId: '15',
        email: 'renew@example.com',
        expiresAt: expiredTime,
      );

      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.refresh) {
          final body = jsonDecode(request.body);
          expect(body['refreshToken'], 'valid_refresh_token');

          return http.Response(
            jsonEncode({
              'token': 'brand_new_access_token',
              'refreshToken': 'rotated_refresh_token',
              'expiresIn': 3600,
              'user': {
                'id': 15,
                'email': 'renew@example.com',
                'firstName': 'Renew',
                'lastName': 'User',
                'role': 'USER',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockClient);
      await authService.tryAutoLogin();

      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, 'brand_new_access_token');
      expect(authService.refreshTokenString, 'rotated_refresh_token');

      // Storage updated with rotated tokens
      expect(await storage.getToken(), 'brand_new_access_token');
      expect(await storage.getRefreshToken(), 'rotated_refresh_token');
    });

    test('tryAutoLogin terminates session if stored refresh token has been revoked', () async {
      final expiredTime = DateTime.now().subtract(const Duration(hours: 1));
      await storage.saveSession(
        token: 'stale_token',
        refreshToken: 'revoked_refresh_token',
        userId: '99',
        email: 'revoked@example.com',
        expiresAt: expiredTime,
      );

      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.refresh) {
          return http.Response(
            jsonEncode({
              'status': 401,
              'error': 'Unauthorized',
              'message': 'Session has been revoked',
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockClient);
      await authService.tryAutoLogin();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.token, isNull);
      expect(await storage.hasSession(), isFalse);
    });

    test('getValidToken proactively triggers refresh when access token is near expiry', () async {
      // Token expires in 20 seconds (< 60 seconds threshold)
      final nearExpiry = DateTime.now().add(const Duration(seconds: 20));
      await storage.saveSession(
        token: 'expiring_soon_token',
        refreshToken: 'valid_refresh_token',
        userId: '1',
        email: 'proactive@example.com',
        expiresAt: nearExpiry,
      );

      int refreshCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.refresh) {
          refreshCalls++;
          return http.Response(
            jsonEncode({
              'token': 'refreshed_access_token',
              'refreshToken': 'rotated_refresh_2',
              'expiresIn': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockClient);
      await authService.tryAutoLogin();

      final validToken = await authService.getValidToken();
      expect(refreshCalls, 1, reason: 'Should have proactively renewed token before expiry');
      expect(validToken, 'refreshed_access_token');
    });

    test('logout notifies backend and completely clears local storage', () async {
      await storage.saveSession(
        token: 'active_token',
        refreshToken: 'active_refresh',
        userId: '1',
        email: 'logout@example.com',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      bool logoutEndpointCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.logout) {
          logoutEndpointCalled = true;
          final body = jsonDecode(request.body);
          expect(body['refreshToken'], 'active_refresh');
          expect(request.headers['Authorization'], 'Bearer active_token');
          return http.Response(jsonEncode({'message': 'Logged out successfully'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockClient);
      await authService.tryAutoLogin();
      expect(authService.isAuthenticated, isTrue);

      await authService.logout();

      expect(logoutEndpointCalled, isTrue);
      expect(authService.isAuthenticated, isFalse);
      expect(authService.token, isNull);
      expect(await storage.hasSession(), isFalse);
    });
  });

  group('Sprint 33: AuthenticatedHttpClient Automatic 401 Interception & Retry', () {
    test('intercepts 401, calls refreshToken, and retries original request transparently', () async {
      final inMemory = <String, String>{};
      final storage = SecureStorageService(inMemoryStorage: inMemory);

      await storage.saveSession(
        token: 'initial_access_token',
        refreshToken: 'valid_refresh_token',
        userId: '5',
        email: 'retry@example.com',
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      int resourceAttempts = 0;
      final mockInnerClient = MockClient((request) async {
        if (request.url.toString() == 'https://example.com/api/protected') {
          resourceAttempts++;
          if (resourceAttempts == 1) {
            // First attempt with initial token fails with 401
            expect(request.headers['Authorization'], 'Bearer initial_access_token');
            return http.Response(jsonEncode({'message': 'Token expired'}), 401);
          } else {
            // Second attempt after token refresh succeeds with 200
            expect(request.headers['Authorization'], 'Bearer fresh_renewed_token');
            return http.Response(jsonEncode({'data': 'secret data'}), 200);
          }
        } else if (request.url.toString() == ApiConfig.refresh) {
          return http.Response(
            jsonEncode({
              'token': 'fresh_renewed_token',
              'refreshToken': 'new_refresh_token',
              'expiresIn': 3600,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = AuthService(secureStorage: storage, client: mockInnerClient);
      await authService.tryAutoLogin();

      final authenticatedClient = AuthenticatedHttpClient(authService, inner: mockInnerClient);

      final response = await authenticatedClient.get(Uri.parse('https://example.com/api/protected'));

      expect(response.statusCode, 200);
      expect(resourceAttempts, 2, reason: 'Request should have been automatically retried once');
      expect(authService.token, 'fresh_renewed_token');
    });
  });
}
