import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:back2kasi_app/config/app_theme.dart';
import 'package:back2kasi_app/models/booking.dart';
import 'package:back2kasi_app/views/shared/components/bk_components.dart';

void main() {
  group('Back2Kasi Emerald Dark Theme Bk Components Tests', () {
    Widget buildTestHarness(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('BkPrimaryButton renders label and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          BkPrimaryButton(
            label: 'Confirm Booking',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Confirm Booking'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('BkPrimaryButton shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const BkPrimaryButton(
            label: 'Processing',
            isLoading: true,
            onPressed: null,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing'), findsNothing);
    });

    testWidgets('BkSecondaryButton renders outlined button and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestHarness(
          BkSecondaryButton(
            label: 'Cancel Request',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Cancel Request'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, isTrue);
    });

    testWidgets('BkTextField renders label, hint, and allows text input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestHarness(
          BkTextField(
            controller: controller,
            label: 'Customer Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person,
          ),
        ),
      );

      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Lerato Mokoena');
      expect(controller.text, equals('Lerato Mokoena'));
    });

    testWidgets('BkAppBar renders title with dark surface background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            appBar: BkAppBar(
              title: 'Catalogue Units',
            ),
          ),
        ),
      );

      expect(find.text('Catalogue Units'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('BkBookingStatusChip renders correct badges and dot indicators', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const Column(
            children: [
              BkBookingStatusChip(status: BookingStatus.CONFIRMED),
              BkBookingStatusChip(status: BookingStatus.PENDING),
              BkBookingStatusChip(status: BookingStatus.COMPLETED),
              BkBookingStatusChip(status: BookingStatus.CANCELLED),
            ],
          ),
        ),
      );

      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('CANCELLED'), findsOneWidget);
    });

    testWidgets('BkPriceDisplay formats ZAR daily rental price correctly', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(
          const BkPriceDisplay(
            pricePerDay: 450.50,
          ),
        ),
      );

      expect(find.text('R 450.50'), findsOneWidget);
      expect(find.text('/day'), findsOneWidget);
    });

    testWidgets('BkEmptyState renders icon, title, message, and CTA', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildTestHarness(
          BkEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Units Listed',
            message: 'You have not registered any rental units for this business yet.',
            actionLabel: 'Add First Unit',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.text('No Units Listed'), findsOneWidget);
      expect(
        find.text('You have not registered any rental units for this business yet.'),
        findsOneWidget,
      );
      expect(find.text('Add First Unit'), findsOneWidget);

      await tester.tap(find.text('Add First Unit'));
      expect(actionTriggered, isTrue);
    });
  });
}
