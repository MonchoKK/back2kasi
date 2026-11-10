import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:back2kasi_app/core/auth_service.dart';
import 'package:back2kasi_app/core/business_provider.dart';
import 'package:back2kasi_app/core/rental_unit_provider.dart';
import 'package:back2kasi_app/core/booking_provider.dart';
import 'package:back2kasi_app/models/business.dart';
import 'package:back2kasi_app/models/rental_unit.dart';
import 'package:back2kasi_app/models/rental_unit_image.dart';
import 'package:back2kasi_app/views/customer/browse_screen.dart';
import 'package:back2kasi_app/views/customer/rental_unit_detail_screen.dart';

void main() {
  group('Sprint 26 - Customer Marketplace Tests', () {
    testWidgets('BrowseScreen renders search bar, category chips, and tabs', (tester) async {
      final authService = AuthService();
      final businessProvider = BusinessProvider();
      final rentalUnitProvider = RentalUnitProvider();
      final bookingProvider = BookingProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
            ChangeNotifierProvider<BusinessProvider>.value(value: businessProvider),
            ChangeNotifierProvider<RentalUnitProvider>.value(value: rentalUnitProvider),
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
          ],
          child: const MaterialApp(
            home: BrowseScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Brand title & search
      expect(find.text('Back2Kasi'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products, services, or local businesses...'), findsOneWidget);

      // Verify Category Chips
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('💇 Beauty & Personal Care'), findsOneWidget);
      expect(find.text('🍔 Food & Catering'), findsOneWidget);

      // Verify Segmented Tabs
      expect(find.text('Products & Services'), findsOneWidget);
      expect(find.text('Local Businesses'), findsOneWidget);
    });

    testWidgets('RentalUnitDetailScreen renders gallery, specs and booking CTA', (tester) async {
      final unit = RentalUnit(
        id: 77,
        name: 'Deluxe VIP Toilet Trailer',
        description: 'Solar powered lighting and luxury mirrors.',
        pricePerDay: 750.0,
        capacity: 2,
        rentalUnitType: RentalUnitType.VIP_TOILET,
        status: RentalUnitStatus.AVAILABLE,
        businessId: 10,
        images: [
          RentalUnitImage(
            id: 1,
            rentalUnitId: 77,
            imageUrl: 'https://example.com/photo1.jpg',
            isPrimary: true,
          ),
        ],
      );

      final business = Business(
        id: 10,
        name: 'Kasi Luxury Rentals',
        address: '88 Vilakazi St, Orlando West, Soweto',
        phoneNumber: '+27712345678',
        businessType: BusinessType.TOILET_RENTAL,
        ownerId: 3,
      );

      final businessProvider = BusinessProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessProvider>.value(value: businessProvider),
          ],
          child: MaterialApp(
            home: RentalUnitDetailScreen(
              unit: unit,
              business: business,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify unit specs
      expect(find.text('Deluxe VIP Toilet Trailer'), findsOneWidget);
      expect(find.text('R 750'), findsWidgets);
      expect(find.text('Solar powered lighting and luxury mirrors.'), findsOneWidget);

      // Verify business provider info
      expect(find.text('Kasi Luxury Rentals'), findsOneWidget);
      expect(find.text('88 Vilakazi St, Orlando West, Soweto'), findsOneWidget);

      // Verify Sticky CTA button
      expect(find.text('Enquire on WhatsApp'), findsOneWidget);
    });
  });
}
