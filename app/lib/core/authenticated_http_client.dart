// ignore_for_file: slash_for_doc_comments
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/**
 * Authenticated HTTP client wrapper that injects Authorization Bearer tokens,
 * automatically handles 401 Unauthorized responses by rotating tokens via
 * {@link AuthService#refreshToken}, and seamlessly retries the failed request.
 *
 * <p>Prevents unnecessary user logout interruptions while actively using the app.</p>
 */
class AuthenticatedHttpClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _inner;

  AuthenticatedHttpClient(
    this._authService, {
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Ensure token is valid before sending request
    final token = await _authService.getValidToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Copy request body for potential retry
    final http.BaseRequest originalRequestCopy = _copyRequest(request);

    final response = await _inner.send(request);

    // 2. If 401 Unauthorized and user has a refresh token, attempt seamless renewal
    if (response.statusCode == 401 && _authService.refreshTokenString != null) {
      debugPrint('AuthenticatedHttpClient: Encountered 401, attempting token refresh...');
      final newToken = await _authService.refreshToken();

      if (newToken != null && newToken.isNotEmpty) {
        debugPrint('AuthenticatedHttpClient: Token refreshed successfully, retrying request...');
        originalRequestCopy.headers['Authorization'] = 'Bearer $newToken';
        return await _inner.send(originalRequestCopy);
      }
    }

    return response;
  }

  http.BaseRequest _copyRequest(http.BaseRequest request) {
    if (request is http.Request) {
      final copy = http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..encoding = request.encoding
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
      copy.bodyBytes = request.bodyBytes;
      return copy;
    }
    // For MultipartRequest or other types, return same request
    return request;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
