import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:back2kasi_app/core/booking_provider.dart';
import 'package:back2kasi_app/models/booking.dart';

void main() {
  group('BookingProvider Tests', () {
    test('fetchMyBookings success should populate list', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/bookings/my');
        expect(request.headers['Authorization'], 'Bearer mock_token');

        final responseJson = [
          {
            'id': 1,
            'startDate': '2026-08-20',
            'endDate': '2026-08-22',
            'totalPrice': 300.0,
            'status': 'PENDING',
            'rentalUnitId': 100,
            'customerId': 2,
            'notes': 'Some notes',
          }
        ];

        return http.Response(jsonEncode(responseJson), 200);
      });

      final provider = BookingProvider(client: mockClient);
      await provider.fetchMyBookings('mock_token');

      expect(provider.myBookings.length, 1);
      expect(provider.myBookings.first.id, 1);
      expect(provider.errorMessage, isNull);
    });

    test('createBooking success should append booking and keep error clear', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/bookings');
        
        final body = jsonDecode(request.body);
        expect(body['rentalUnitId'], 100);
        expect(body['startDate'], '2026-08-20');
        expect(body['endDate'], '2026-08-22');

        final responseJson = {
          'id': 10,
          'startDate': '2026-08-20',
          'endDate': '2026-08-22',
          'totalPrice': 300.0,
          'status': 'PENDING',
          'rentalUnitId': 100,
          'customerId': 2,
          'notes': 'Some notes',
        };

        return http.Response(jsonEncode(responseJson), 201);
      });

      final provider = BookingProvider(client: mockClient);
      await provider.createBooking(
        rentalUnitId: 100,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
        notes: 'Some notes',
        token: 'mock_token',
      );

      expect(provider.myBookings.length, 1);
      expect(provider.myBookings.first.id, 10);
      expect(provider.errorMessage, isNull);
    });

    test('createBooking conflict overlap (HTTP 409) should throw and set clean message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Dates overlap'}),
          409,
        );
      });

      final provider = BookingProvider(client: mockClient);

      await expectLater(
        provider.createBooking(
          rentalUnitId: 100,
          startDate: DateTime(2026, 8, 20),
          endDate: DateTime(2026, 8, 22),
          token: 'mock_token',
        ),
        throwsException,
      );

      // Verify clean customer-facing message
      expect(
        provider.errorMessage,
        contains('The selected dates are no longer available'),
      );
    });

    test('createBooking validation failure (HTTP 400) should concatenate field errors', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Validation failed',
            'fieldErrors': {
              'startDate': 'must be in the future',
              'endDate': 'must be after start date',
            }
          }),
          400,
        );
      });

      final provider = BookingProvider(client: mockClient);

      await expectLater(
        provider.createBooking(
          rentalUnitId: 100,
          startDate: DateTime(2026, 8, 20),
          endDate: DateTime(2026, 8, 22),
          token: 'mock_token',
        ),
        throwsException,
      );

      expect(provider.errorMessage, contains('must be in the future'));
      expect(provider.errorMessage, contains('must be after start date'));
    });

    test('cancelBooking success should update booking status in provider memory', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/bookings/5/status');

        final responseJson = {
          'id': 5,
          'startDate': '2026-08-20',
          'endDate': '2026-08-22',
          'totalPrice': 300.0,
          'status': 'CANCELLED',
          'rentalUnitId': 100,
          'customerId': 2,
        };

        return http.Response(jsonEncode(responseJson), 200);
      });

      final provider = BookingProvider(client: mockClient);
      
      // Seed provider with mock booking PENDING
      final initialBooking = Booking(
        id: 5,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
        totalPrice: 300.0,
        status: BookingStatus.PENDING,
        rentalUnitId: 100,
        customerId: 2,
      );
      provider.myBookings.add(initialBooking);

      await provider.cancelBooking(5, 'mock_token');

      expect(provider.myBookings.first.status, BookingStatus.CANCELLED);
      expect(provider.errorMessage, isNull);
    });

    test('fetchOwnerBookings success should populate list', () async {
      final mockClient = MockClient((request) async {
        final mockResponseList = [
          {
            'id': 15,
            'startDate': '2026-08-20',
            'endDate': '2026-08-22',
            'totalPrice': 600.0,
            'status': 'PENDING',
            'rentalUnitId': 101,
            'customerId': 3,
          }
        ];
        return http.Response(jsonEncode(mockResponseList), 200);
      });

      final provider = BookingProvider(client: mockClient);
      await provider.fetchOwnerBookings('mock_token');

      expect(provider.ownerBookings.length, 1);
      expect(provider.ownerBookings.first.id, 15);
      expect(provider.errorMessage, isNull);
    });

    test('updateBookingStatus (CONFIRMED) should update both myBookings and ownerBookings caches', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'id': 5,
          'startDate': '2026-08-20',
          'endDate': '2026-08-22',
          'totalPrice': 300.0,
          'status': 'CONFIRMED',
          'rentalUnitId': 100,
          'customerId': 2,
        };
        return http.Response(jsonEncode(responseJson), 200);
      });

      final provider = BookingProvider(client: mockClient);

      // Seed both lists
      final initialBooking = Booking(
        id: 5,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
        totalPrice: 300.0,
        status: BookingStatus.PENDING,
        rentalUnitId: 100,
        customerId: 2,
      );
      provider.myBookings.add(initialBooking);
      provider.ownerBookings.add(initialBooking);

      await provider.updateBookingStatus(5, BookingStatus.CONFIRMED, 'mock_token');

      expect(provider.myBookings.first.status, BookingStatus.CONFIRMED);
      expect(provider.ownerBookings.first.status, BookingStatus.CONFIRMED);
      expect(provider.errorMessage, isNull);
    });
  });
}
