// ignore_for_file: slash_for_doc_comments, prefer_conditional_assignment
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking.dart';

/**
 * State provider managing the booking lifecycle.
 *
 * <p>Handles calling the Spring Boot backend REST endpoints for creating,
 * retrieving, and cancelling bookings. Caches the user's bookings in memory
 * and notifies interested UI components on state changes.</p>
 */
class BookingProvider extends ChangeNotifier {
  final http.Client _client;
  List<Booking> _myBookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  BookingProvider({http.Client? client}) : _client = client ?? http.Client();

  List<Booking> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /**
   * Fetch all bookings made by the currently authenticated user.
   * Calls GET /api/v1/bookings/my
   */
  Future<void> fetchMyBookings(String token) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.bookings}/my'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> listJson = jsonDecode(response.body);
        _myBookings = listJson.map((json) => Booking.fromJson(json)).toList();
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to load bookings';
      }
    } catch (e) {
      _errorMessage = 'Connection error: unable to reach host';
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Create a new booking for a rental unit.
   * Calls POST /api/v1/bookings
   */
  Future<void> createBooking({
    required int rentalUnitId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.bookings),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rentalUnitId': rentalUnitId,
          'startDate': startDate.toIso8601String().substring(0, 10),
          'endDate': endDate.toIso8601String().substring(0, 10),
          'notes': notes,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final newBooking = Booking.fromJson(responseBody);
        _myBookings.insert(0, newBooking);
      } else {
        if (response.statusCode == 409) {
          _errorMessage = 'The selected dates are no longer available for this unit. Please select different dates.';
        } else if (responseBody['fieldErrors'] != null) {
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          _errorMessage = errors.values.join(', ');
        } else {
          _errorMessage = responseBody['message'] ?? 'Failed to create booking';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to create booking';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Cancel a pending booking.
   * Calls PATCH /api/v1/bookings/{id}/status with {"status": "CANCELLED"}
   */
  Future<void> cancelBooking(int bookingId, String token) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _client.patch(
        Uri.parse('${ApiConfig.bookings}/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'CANCELLED',
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final updatedBooking = Booking.fromJson(responseBody);
        final index = _myBookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          _myBookings[index] = updatedBooking;
        }
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to cancel booking';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to cancel booking';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
