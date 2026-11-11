import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:back2kasi_app/core/auth_service.dart';
import 'package:back2kasi_app/core/rental_unit_provider.dart';
import 'package:back2kasi_app/models/business.dart';
import 'package:back2kasi_app/models/business_category.dart';
import 'package:back2kasi_app/views/customer/customer_business_detail_screen.dart';
import 'package:back2kasi_app/views/business/business_detail_screen.dart';

void main() {
  group('Business Detail Screens Test', () {
    final testBusiness = Business(
      id: 1,
      name: 'Fresh Cuts Barbershop',
      address: '123 Main St, Soweto',
      phoneNumber: '0712345678',
      businessType: BusinessType.TOILET_RENTAL,
      category: BusinessCategory.BEAUTY,
      ownerId: 2,
    );

    testWidgets('CustomerBusinessDetailScreen renders without exceptions', (tester) async {
      final rentalUnitProvider = RentalUnitProvider();
      final authService = AuthService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
            ChangeNotifierProvider<RentalUnitProvider>.value(value: rentalUnitProvider),
          ],
          child: MaterialApp(
            home: CustomerBusinessDetailScreen(business: testBusiness),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fresh Cuts Barbershop'), findsOneWidget);
    });

    testWidgets('BusinessDetailScreen renders without exceptions', (tester) async {
      final rentalUnitProvider = RentalUnitProvider();
      final authService = AuthService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
            ChangeNotifierProvider<RentalUnitProvider>.value(value: rentalUnitProvider),
          ],
          child: MaterialApp(
            home: BusinessDetailScreen(business: testBusiness),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fresh Cuts Barbershop'), findsOneWidget);
    });
  });
}

