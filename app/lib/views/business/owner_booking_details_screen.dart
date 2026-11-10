// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../models/booking.dart';
import '../shared/components/bk_components.dart';

/**
 * Screen presenting an inspector card for owners to evaluate booking requests.
 *
 * <p>Emerald Light Marketplace design:
 * - Clean white information surfaces
 * - Clear pricing breakdown with duration calculations
 * - One-tap Approve, Decline, and Complete actions.</p>
 */
class OwnerBookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const OwnerBookingDetailsScreen({super.key, required this.booking});

  @override
  State<OwnerBookingDetailsScreen> createState() => _OwnerBookingDetailsScreenState();
}

class _OwnerBookingDetailsScreenState extends State<OwnerBookingDetailsScreen> {
  bool _isProcessing = false;
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  Future<void> _updateStatus(BookingStatus targetStatus) async {
    final String actionText = targetStatus == BookingStatus.CONFIRMED
        ? 'approve'
        : targetStatus == BookingStatus.CANCELLED
            ? 'decline'
            : 'complete';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('${actionText.toUpperCase()} REQUEST', style: const TextStyle(color: AppTheme.textPrimaryColor)),
        content: Text(
          'Are you sure you want to $actionText booking request #${_currentBooking.id}?',
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: targetStatus == BookingStatus.CONFIRMED || targetStatus == BookingStatus.COMPLETED
                  ? AppTheme.brandColor
                  : AppTheme.errorColor,
            ),
            child: Text(actionText.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      setState(() {
        _isProcessing = true;
      });

      try {
        final provider = context.read<BookingProvider>();
        await provider.updateBookingStatus(_currentBooking.id, targetStatus, token);

        final updated = provider.ownerBookings.firstWhere((b) => b.id == _currentBooking.id);
        setState(() {
          _currentBooking = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking request status updated to ${_currentBooking.status.name}.'),
            backgroundColor: AppTheme.brandColor,
          ),
        );
      } catch (e) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String typeLabel = _currentBooking.rentalUnitName ?? 'Rental Unit';
    final int numberOfDays = _currentBooking.endDate.difference(_currentBooking.startDate).inDays + 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const BkAppBar(
        title: 'Booking Request Details',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  BkBookingStatusChip(status: _currentBooking.status),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID: #${_currentBooking.id}',
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Status: ${_formatStatus(_currentBooking.status)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Summary Variables
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
                  _buildDetailRow('Customer ID', '${_currentBooking.customerId}', Icons.person_outline),
                  const Divider(color: AppTheme.borderColor, height: 24),
                  _buildDetailRow('Business', _currentBooking.businessName ?? 'Service Provider', Icons.storefront),
                  const Divider(color: AppTheme.borderColor, height: 24),
                  _buildDetailRow('Rental Unit', typeLabel, Icons.wc),
                  const Divider(color: AppTheme.borderColor, height: 24),
                  _buildDetailRow(
                    'Dates',
                    '${_formatDate(_currentBooking.startDate)} → ${_formatDate(_currentBooking.endDate)} ($numberOfDays days)',
                    Icons.calendar_today,
                  ),
                  if (_currentBooking.notes != null && _currentBooking.notes!.isNotEmpty) ...[
                    const Divider(color: AppTheme.borderColor, height: 24),
                    _buildDetailRow('Client Notes', _currentBooking.notes!, Icons.chat_bubble_outline),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Payment Expected',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R ${_currentBooking.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      '$numberOfDays day reservation',
                      style: const TextStyle(color: AppTheme.brandColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Actions Based on Current Lifecycle State
            if (_isProcessing)
              const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
            else if (_currentBooking.status == BookingStatus.PENDING)
              Row(
                children: [
                  Expanded(
                    child: BkSecondaryButton(
                      label: 'Decline',
                      textColor: AppTheme.errorColor,
                      borderColor: AppTheme.errorColor,
                      onPressed: () => _updateStatus(BookingStatus.CANCELLED),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BkPrimaryButton(
                      label: 'Approve Request',
                      onPressed: () => _updateStatus(BookingStatus.CONFIRMED),
                    ),
                  ),
                ],
              )
            else if (_currentBooking.status == BookingStatus.CONFIRMED)
              BkPrimaryButton(
                label: 'Mark as Completed',
                icon: Icons.check,
                onPressed: () => _updateStatus(BookingStatus.COMPLETED),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Center(
                  child: Text(
                    'This booking is ${_currentBooking.status.name.toLowerCase()} and archived.',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.brandColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.CONFIRMED:
        return 'Confirmed';
      case BookingStatus.PENDING:
        return 'Pending';
      case BookingStatus.COMPLETED:
        return 'Completed';
      case BookingStatus.CANCELLED:
        return 'Cancelled';
    }
  }
}
