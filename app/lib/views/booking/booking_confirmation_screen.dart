// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import 'booking_success_screen.dart';

/**
 * Screen presenting a final review summary of the booking details before submission.
 *
 * <p>Validates authorization, shows estimates, handles progress indicator states,
 * and calls the booking API. Displays clean validation/overlap conflict errors.</p>
 */
class BookingConfirmationScreen extends StatefulWidget {
  final RentalUnit unit;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  const BookingConfirmationScreen({
    super.key,
    required this.unit,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isSubmitting = false;
  String? _localError;

  int get _numberOfDays => widget.endDate.difference(widget.startDate).inDays;
  double get _totalPrice => widget.unit.pricePerDay * _numberOfDays;

  Future<void> _submitBooking() async {
    final authService = context.read<AuthService>();
    final token = authService.token;

    if (token == null) {
      setState(() => _localError = 'You must be logged in to request a booking.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    try {
      await context.read<BookingProvider>().createBooking(
            rentalUnitId: widget.unit.id,
            startDate: widget.startDate,
            endDate: widget.endDate,
            notes: widget.notes,
            token: token,
          );

      // On success, navigate to the success screen and clear path stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BookingSuccessScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _localError = cleanMsg;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the business profile name from cached providers
    final businessProvider = context.read<BusinessProvider>();
    final businesses = businessProvider.allBusinesses.isEmpty
        ? businessProvider.myBusinesses
        : businessProvider.allBusinesses;

    final business = businesses.firstWhere(
      (b) => b.id == widget.unit.businessId,
      orElse: () => Business(
        id: widget.unit.businessId,
        name: 'Service Provider',
        address: 'N/A',
        phoneNumber: 'N/A',
        businessType: BusinessType.TOILET_RENTAL,
        ownerId: 0,
      ),
    );

    final String typeLabel = widget.unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verify details before placing booking request:',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Error display card
            if (_localError != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Booking Details Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161524),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryItem('Business', business.name, Icons.storefront),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryItem('Rental Unit', '${widget.unit.name} ($typeLabel)', Icons.wc),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryItem(
                    'Rental Dates',
                    '${_formatDate(widget.startDate)} → ${_formatDate(widget.endDate)}',
                    Icons.date_range,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildSummaryItem('Duration', '$_numberOfDays Day(s)', Icons.timer_outlined),
                  if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildSummaryItem('Notes', widget.notes!, Icons.notes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pricing Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161524),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5D5FEF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R ${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pricing is estimated; the host determines the final invoice amount.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Action Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Request Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF5D5FEF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
