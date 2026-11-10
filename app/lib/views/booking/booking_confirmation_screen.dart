// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../shared/components/bk_components.dart';
import 'booking_success_screen.dart';

/**
 * Screen presenting a final review summary of the booking details before submission.
 *
 * <p>Emerald Light Marketplace design:
 * - Transparent cost breakdown with duration calculation
 * - Provider contact information
 * - Non-blocking submit action with Emerald CTA.</p>
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

  int get _numberOfDays => widget.endDate.difference(widget.startDate).inDays + 1;
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: const BkAppBar(
        title: 'Confirm Booking Request',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error banner if any
            if (_localError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                ),
                child: Text(
                  _localError!,
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Reservation Summary Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: AppTheme.brandColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.unit.name} (${typeLabel.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 12),
                  _buildReviewRow('Provider', business.name, Icons.storefront),
                  const SizedBox(height: 10),
                  _buildReviewRow('Address', business.address, Icons.location_on_outlined),
                  const SizedBox(height: 10),
                  _buildReviewRow(
                    'Dates',
                    '${_formatDate(widget.startDate)} → ${_formatDate(widget.endDate)}',
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 10),
                  _buildReviewRow('Duration', '$_numberOfDays Day(s)', Icons.timer_outlined),
                  if (widget.notes != null) ...[
                    const SizedBox(height: 10),
                    _buildReviewRow('Notes', widget.notes!, Icons.notes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Cost Summary Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R ${widget.unit.pricePerDay.toStringAsFixed(2)} × $_numberOfDays days',
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                      Text(
                        'R ${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        'R ${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Terms note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your booking request will be submitted as PENDING. The business owner will review and confirm availability.',
                    style: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.9), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space32),

            // Submit Button
            BkPrimaryButton(
              label: 'Request Booking',
              isLoading: _isSubmitting,
              icon: Icons.send_rounded,
              onPressed: _submitBooking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.brandColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimaryColor),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
