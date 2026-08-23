import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:back2kasi_app/core/auth_service.dart';
import 'package:back2kasi_app/core/booking_provider.dart';
import 'package:back2kasi_app/core/business_provider.dart';
import 'package:back2kasi_app/models/business.dart';
import 'package:back2kasi_app/models/rental_unit.dart';
import 'package:back2kasi_app/views/booking/booking_confirmation_screen.dart';
import 'package:back2kasi_app/views/booking/booking_success_screen.dart';

// Test double for AuthService to inject mock credentials in widget tests.
class MockAuthService extends AuthService {
  String? _mockToken;
  String? _mockEmail;

  void setMockCredentials({String? token, String? email}) {
    _mockToken = token;
    _mockEmail = email;
  }

  @override
  String? get token => _mockToken;

  @override
  String? get userEmail => _mockEmail;

  @override
  bool get isAuthenticated => _mockToken != null;
}

void main() {
  group('Booking Screens Widget Tests', () {
    late RentalUnit mockUnit;
    late Business mockBusiness;

    setUp(() {
      mockUnit = RentalUnit(
        id: 100,
        name: 'VIP Toilet Luxury',
        description: 'Gold-plated interior',
        pricePerDay: 500.0,
        capacity: 1,
        rentalUnitType: RentalUnitType.VIP_TOILET,
        status: RentalUnitStatus.AVAILABLE,
        businessId: 10,
      );

      mockBusiness = Business(
        id: 10,
        name: 'Kasi Toilets Co',
        address: '123 Soweto St',
        phoneNumber: '+27711234567',
        businessType: BusinessType.TOILET_RENTAL,
        ownerId: 1,
      );
    });

    Widget createTestableWidget({
      required Widget child,
      required AuthService authService,
      required BookingProvider bookingProvider,
      required BusinessProvider businessProvider,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
          ChangeNotifierProvider<BusinessProvider>.value(value: businessProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('BookingConfirmationScreen renders details correctly', (WidgetTester tester) async {
      final authService = MockAuthService();
      final bookingProvider = BookingProvider();
      final businessProvider = BusinessProvider();

      // Seed business list to resolve business name
      businessProvider.allBusinesses.add(mockBusiness);

      await tester.pumpWidget(
        createTestableWidget(
          child: BookingConfirmationScreen(
            unit: mockUnit,
            startDate: DateTime(2026, 8, 20),
            endDate: DateTime(2026, 8, 22),
            notes: 'Leave near the fence',
          ),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
        ),
      );

      // Verify page titles and detail widgets
      expect(find.text('Review Booking'), findsOneWidget);
      expect(find.text('Kasi Toilets Co'), findsOneWidget);
      expect(find.text('VIP Toilet Luxury (VIP TOILET)'), findsOneWidget);
      expect(find.text('2 Day(s)'), findsOneWidget);
      expect(find.text('Leave near the fence'), findsOneWidget);

      // Estimated price (R500 * 2 = R1000)
      expect(find.text('R 1000.00'), findsOneWidget);
    });

    testWidgets('Tapping Request Booking shows spinner, calls api, and redirects to success', (WidgetTester tester) async {
      // Mock HTTP response for booking creation (201 Created)
      final mockHttpClient = MockClient((request) async {
        final mockResponse = {
          'id': 12,
          'startDate': '2026-08-20',
          'endDate': '2026-08-22',
          'totalPrice': 1000.0,
          'status': 'PENDING',
          'rentalUnitId': 100,
          'customerId': 2,
        };
        return http.Response(jsonEncode(mockResponse), 201);
      });

      final authService = MockAuthService();
      authService.setMockCredentials(token: 'mock_token', email: 'user@kasi.co.za');
      
      final bookingProvider = BookingProvider(client: mockHttpClient);
      final businessProvider = BusinessProvider();
      businessProvider.allBusinesses.add(mockBusiness);

      await tester.pumpWidget(
        createTestableWidget(
          child: BookingConfirmationScreen(
            unit: mockUnit,
            startDate: DateTime(2026, 8, 20),
            endDate: DateTime(2026, 8, 22),
          ),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
        ),
      );

      // Tap the submit button
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Request Booking');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pump(); // Start navigation/request flow

      // Settle transitions
      await tester.pumpAndSettle();

      // Should land on BookingSuccessScreen
      expect(find.byType(BookingSuccessScreen), findsOneWidget);
      expect(find.text('Booking Requested!'), findsOneWidget);
    });

    testWidgets('Tapping Request Booking shows custom error banner on api conflict', (WidgetTester tester) async {
      // Mock HTTP response for booking conflict (409 Conflict)
      final mockHttpClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Overlapping dates'}), 409);
      });

      final authService = MockAuthService();
      authService.setMockCredentials(token: 'mock_token', email: 'user@kasi.co.za');

      final bookingProvider = BookingProvider(client: mockHttpClient);
      final businessProvider = BusinessProvider();
      businessProvider.allBusinesses.add(mockBusiness);

      await tester.pumpWidget(
        createTestableWidget(
          child: BookingConfirmationScreen(
            unit: mockUnit,
            startDate: DateTime(2026, 8, 20),
            endDate: DateTime(2026, 8, 22),
          ),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
        ),
      );

      // Tap request button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Request Booking'));
      await tester.pump(); // Process the async request
      await tester.pump(); // Catch state update and error mapping

      // Expect specific mapped customer error banner
      expect(
        find.text('The selected dates are no longer available for this unit. Please select different dates.'),
        findsOneWidget,
      );
    });
  });
}
