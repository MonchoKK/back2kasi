// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import '../shared/main_navigation_shell.dart';

/**
 * Screen displayed to the customer on successful booking request creation.
 *
 * <p>Presents a checkmark graphic, informs the user of the PENDING status,
 * and provides navigation redirects to booking history or browse view.</p>
 */
class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon Animation/Representation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF66BB6A),
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Booking Requested!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Your booking request has been successfully created and is currently PENDING review by the service provider.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Actions
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to MainNavigationShell and select the Bookings tab (index 1)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationShell(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('View My Bookings'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Navigate to MainNavigationShell and select the Browse tab (index 0)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationShell(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF5D5FEF)),
                  foregroundColor: const Color(0xFF5D5FEF),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Back to Services',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
