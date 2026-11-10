// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../shared/components/bk_components.dart';
import '../shared/main_navigation_shell.dart';

/**
 * Screen displayed to the customer on successful booking request creation.
 *
 * <p>Emerald Light Marketplace design:
 * - Emerald celebratory checkmark container
 * - Clear instructions on pending status review
 * - Direct shortcut navigation to My Bookings or Browse.</p>
 */
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon Container
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.brandColor,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Booking Requested!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                'Your booking request has been successfully created and is currently PENDING review by the service provider.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Actions
              BkPrimaryButton(
                label: 'View in My Bookings',
                icon: Icons.calendar_today,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationShell(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              BkSecondaryButton(
                label: 'Continue Browsing',
                icon: Icons.search,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationShell(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
