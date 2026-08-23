import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:back2kasi_app/core/auth_service.dart';
import 'package:back2kasi_app/core/booking_provider.dart';
import 'package:back2kasi_app/core/business_provider.dart';
import 'package:back2kasi_app/core/rental_unit_provider.dart';
import 'package:back2kasi_app/models/business.dart';
import 'package:back2kasi_app/models/rental_unit.dart';
import 'package:back2kasi_app/models/booking.dart';
import 'package:back2kasi_app/views/business/dashboard_screen.dart';
import 'package:back2kasi_app/views/business/owner_booking_requests_screen.dart';
import 'package:back2kasi_app/views/business/owner_booking_details_screen.dart';

class MockAuthService extends AuthService {
  @override
  String? get token => 'mock_owner_token';
  @override
  bool get isAuthenticated => true;
  @override
  bool get isLoading => false;
}

void main() {
  group('Owner Dashboard and Requests Widget Tests', () {
    late Business mockBusiness;
    late RentalUnit mockUnit;
    late Booking mockPendingBooking;
    late Booking mockConfirmedBooking;

    setUp(() {
      mockBusiness = Business(
        id: 10,
        name: 'Kasi Toilets Co',
        address: '123 Soweto St',
        phoneNumber: '+27711234567',
        businessType: BusinessType.TOILET_RENTAL,
        ownerId: 1,
      );

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

      mockPendingBooking = Booking(
        id: 50,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
        totalPrice: 1000.0,
        status: BookingStatus.PENDING,
        rentalUnitId: 100,
        rentalUnitName: 'VIP Toilet Luxury',
        businessName: 'Kasi Toilets Co',
        customerId: 2,
      );

      mockConfirmedBooking = Booking(
        id: 51,
        startDate: DateTime(2026, 8, 25),
        endDate: DateTime(2026, 8, 27),
        totalPrice: 1000.0,
        status: BookingStatus.CONFIRMED,
        rentalUnitId: 100,
        rentalUnitName: 'VIP Toilet Luxury',
        businessName: 'Kasi Toilets Co',
        customerId: 3,
      );
    });

    Widget createTestableWidget({
      required Widget child,
      required AuthService authService,
      required BookingProvider bookingProvider,
      required BusinessProvider businessProvider,
      required RentalUnitProvider rentalUnitProvider,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
          ChangeNotifierProvider<BusinessProvider>.value(value: businessProvider),
          ChangeNotifierProvider<RentalUnitProvider>.value(value: rentalUnitProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('DashboardScreen renders business stats correctly', (WidgetTester tester) async {
      // Set larger viewport to avoid offscreen widgets
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authService = MockAuthService();
      final businessProvider = BusinessProvider();
      final rentalUnitProvider = RentalUnitProvider();
      final bookingProvider = BookingProvider();

      // Seed data into providers
      businessProvider.myBusinesses.add(mockBusiness);
      rentalUnitProvider.businessUnits[10] = [mockUnit];
      bookingProvider.ownerBookings.addAll([mockPendingBooking, mockConfirmedBooking]);

      await tester.pumpWidget(
        createTestableWidget(
          child: const DashboardScreen(),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
          rentalUnitProvider: rentalUnitProvider,
        ),
      );

      // Verify business dropdown selector shows selected business name
      expect(find.text('Kasi Toilets Co'), findsOneWidget);

      // Verify stats grid (1 Rental Unit, 1 Pending Request, 1 Active Booking)
      expect(find.text('1'), findsAtLeast(3));
    });

    testWidgets('OwnerBookingRequestsScreen displays pending and history tabs', (WidgetTester tester) async {
      final authService = MockAuthService();
      final businessProvider = BusinessProvider();
      final rentalUnitProvider = RentalUnitProvider();
      final bookingProvider = BookingProvider();

      businessProvider.myBusinesses.add(mockBusiness);
      rentalUnitProvider.businessUnits[10] = [mockUnit];
      bookingProvider.ownerBookings.addAll([mockPendingBooking, mockConfirmedBooking]);

      await tester.pumpWidget(
        createTestableWidget(
          child: OwnerBookingRequestsScreen(business: mockBusiness),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
          rentalUnitProvider: rentalUnitProvider,
        ),
      );

      // Check Tabs
      expect(find.text('Pending Requests'), findsOneWidget);
      expect(find.text('Booking History'), findsOneWidget);

      // Check pending request card in current view
      expect(find.text('Booking ID: #50'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('OwnerBookingDetailsScreen renders and executes approve status change', (WidgetTester tester) async {
      // Set larger viewport to avoid offscreen widgets
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockHttpClient = MockClient((request) async {
        final mockJson = {
          'id': 50,
          'startDate': '2026-08-20',
          'endDate': '2026-08-22',
          'totalPrice': 1000.0,
          'status': 'CONFIRMED',
          'rentalUnitId': 100,
          'customerId': 2,
        };
        return http.Response(jsonEncode(mockJson), 200);
      });

      final authService = MockAuthService();
      final businessProvider = BusinessProvider();
      final rentalUnitProvider = RentalUnitProvider();
      final bookingProvider = BookingProvider(client: mockHttpClient);

      bookingProvider.ownerBookings.add(mockPendingBooking);

      await tester.pumpWidget(
        createTestableWidget(
          child: OwnerBookingDetailsScreen(booking: mockPendingBooking),
          authService: authService,
          bookingProvider: bookingProvider,
          businessProvider: businessProvider,
          rentalUnitProvider: rentalUnitProvider,
        ),
      );

      // Verify details
      expect(find.text('Booking ID: #50'), findsOneWidget);
      expect(find.text('Status: Pending'), findsOneWidget);

      // Tap Approve
      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve Request'));
      await tester.pump(); // Show confirmation dialog
      
      // Tap Confirm in dialog
      await tester.tap(find.widgetWithText(TextButton, 'APPROVE'));
      await tester.pump(); // Trigger status update request
      await tester.pump(); // Settle updates

      // Status should transition to Confirmed
      expect(find.text('Status: Confirmed'), findsOneWidget);
    });
  });
}
