// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/contact_helper.dart';
import '../../models/booking.dart';
import '../../models/booking_contact.dart';
import '../shared/components/bk_components.dart';

/**
 * Screen showing detailed, read-only status and variables of a customer reservation.
 *
 * <p>Emerald Light Marketplace design:
 * - Status header with dot badge
 * - Booking itinerary breakdown
 * - Booking-gated direct WhatsApp and telephone contact unlocked upon owner acceptance.</p>
 */
class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _isCancelling = false;
  late Booking _currentBooking;
  BookingContact? _bookingContact;
  bool _isLoadingContact = false;
  String? _contactError;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    if (_currentBooking.status == BookingStatus.CONFIRMED) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContact();
      });
    }
  }

  Future<void> _loadContact() async {
    final token = context.read<AuthService>().token;
    if (token == null) return;

    setState(() {
      _isLoadingContact = true;
      _contactError = null;
    });

    try {
      final contact = await context.read<BookingProvider>().fetchBookingContact(_currentBooking.id, token);
      if (mounted) {
        setState(() {
          _bookingContact = contact;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contactError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContact = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Cancel Booking', style: TextStyle(color: AppTheme.textPrimaryColor)),
        content: Text(
          'Are you sure you want to cancel booking request #${_currentBooking.id}?\n\n'
          '${_formatDate(_currentBooking.startDate)} → ${_formatDate(_currentBooking.endDate)}',
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Yes, Cancel Booking', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      setState(() {
        _isCancelling = true;
      });

      try {
        final provider = context.read<BookingProvider>();
        await provider.cancelBooking(_currentBooking.id, token);

        final updated = provider.myBookings.firstWhere((b) => b.id == _currentBooking.id);
        setState(() {
          _currentBooking = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request cancelled successfully.'),
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
          _isCancelling = false;
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
        title: 'Booking Details',
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
                        'Booking #${_currentBooking.id}',
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created on: ${_formatDate(_currentBooking.createdAt ?? DateTime.now())}',
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

            // Rental Itinerary Summary
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
                  _buildDetailRow('Rental Equipment', typeLabel, Icons.wc),
                  const Divider(color: AppTheme.borderColor, height: 24),
                  _buildDetailRow('Service Provider', _currentBooking.businessName ?? 'Local Business', Icons.storefront),
                  const Divider(color: AppTheme.borderColor, height: 24),
                  _buildDetailRow(
                    'Dates of Reservation',
                    '${_formatDate(_currentBooking.startDate)} → ${_formatDate(_currentBooking.endDate)} ($numberOfDays days)',
                    Icons.calendar_today,
                  ),
                  if (_currentBooking.notes != null && _currentBooking.notes!.isNotEmpty) ...[
                    const Divider(color: AppTheme.borderColor, height: 24),
                    _buildDetailRow('Special Instructions', _currentBooking.notes!, Icons.notes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Pricing Summary Card
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
                        'Total Rental Fee',
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
                      '$numberOfDays day booking',
                      style: const TextStyle(color: AppTheme.brandColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Booking-Gated Direct Contact Section
            _buildContactSection(),
            const SizedBox(height: AppTheme.space32),

            // Cancel CTA for PENDING requests
            if (_currentBooking.status == BookingStatus.PENDING)
              _isCancelling
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
                  : BkSecondaryButton(
                      label: 'Cancel Booking Request',
                      textColor: AppTheme.errorColor,
                      borderColor: AppTheme.errorColor,
                      onPressed: _cancelBooking,
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    if (_currentBooking.status == BookingStatus.CONFIRMED) {
      if (_isLoadingContact) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.space20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandColor),
              ),
              SizedBox(width: 12),
              Text(
                'Retrieving authorized provider contact...',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
            ],
          ),
        );
      }

      if (_bookingContact != null) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.space20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.brandColor.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brandColor.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.verified_rounded, color: AppTheme.brandColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct Provider Contact',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Unlocked for this accepted booking',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.brandColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: AppTheme.space12),

              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _bookingContact!.contactName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 10),
                  Text(
                    _bookingContact!.phoneNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space20),

              // Action Buttons
              Row(
                children: [
                  if (_bookingContact!.whatsappEnabled) ...[
                    Expanded(
                      child: BkPrimaryButton(
                        label: 'WhatsApp Provider',
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () {
                          ContactHelper.launchWhatsApp(
                            context,
                            phone: _bookingContact!.whatsappInternationalNumber ?? _bookingContact!.phoneNumber,
                            message: _bookingContact!.prefilledMessage,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: BkSecondaryButton(
                      label: 'Call Provider',
                      icon: Icons.phone_forwarded_outlined,
                      onPressed: () {
                        ContactHelper.launchCall(
                          context,
                          phone: _bookingContact!.phoneNumber,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      if (_contactError != null) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.errorColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _contactError!,
                  style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: _loadContact,
                child: const Text('Retry', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
              ),
            ],
          ),
        );
      }
    }

    if (_currentBooking.status == BookingStatus.PENDING) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.lock_clock_outlined, color: AppTheme.accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Contact Gated',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Direct telephone and WhatsApp communication will be unlocked automatically once the business owner accepts your booking request.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentBooking.status == BookingStatus.CANCELLED) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppTheme.textSecondaryColor, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This booking is cancelled. Direct contact access has been revoked.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
}
