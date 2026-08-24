// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../models/booking.dart';

/**
 * Screen showing detailed, read-only status and variables of a customer reservation.
 *
 * <p>Enables cancelling PENDING requests with confirmation dialog blocks.</p>
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

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel booking request #${_currentBooking.id}?\n\n'
          '${_formatDate(_currentBooking.startDate)} → ${_formatDate(_currentBooking.endDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Yes, Cancel Booking'),
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

        // Update local state by finding the updated booking in the provider list
        final updated = provider.myBookings.firstWhere((b) => b.id == _currentBooking.id);
        setState(() {
          _currentBooking = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request cancelled successfully.'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      } catch (e) {
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanMsg),
            backgroundColor: Colors.redAccent,
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

    // Status styling
    Color badgeColor;
    Color textColor;
    IconData statusIcon;
    String statusLabel;

    switch (_currentBooking.status) {
      case BookingStatus.PENDING:
        badgeColor = const Color(0xFFFFB74D).withOpacity(0.15);
        textColor = const Color(0xFFFFB74D);
        statusIcon = Icons.schedule;
        statusLabel = 'Pending';
        break;
      case BookingStatus.CONFIRMED:
        badgeColor = const Color(0xFF5D5FEF).withOpacity(0.15);
        textColor = const Color(0xFF8C8DFF);
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Confirmed';
        break;
      case BookingStatus.COMPLETED:
        badgeColor = const Color(0xFF66BB6A).withOpacity(0.15);
        textColor = const Color(0xFF81C784);
        statusIcon = Icons.done_all;
        statusLabel = 'Completed';
        break;
      case BookingStatus.CANCELLED:
        badgeColor = const Color(0xFFEF5350).withOpacity(0.15);
        textColor = const Color(0xFFE57373);
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Cancelled';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: textColor, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $statusLabel',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Booking ID: #${_currentBooking.id}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary variables
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
                  _buildDetailRow('Business', _currentBooking.businessName ?? 'Service Provider', Icons.storefront),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow('Rental Unit', typeLabel, Icons.wc),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow(
                    'Dates',
                    '${_formatDate(_currentBooking.startDate)} → ${_formatDate(_currentBooking.endDate)}',
                    Icons.date_range,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow('Duration', '$numberOfDays day(s)', Icons.timer_outlined),
                  if (_currentBooking.notes != null && _currentBooking.notes!.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Notes', _currentBooking.notes!, Icons.notes),
                  ],
                  if (_currentBooking.createdAt != null) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Requested On', _formatDateTime(_currentBooking.createdAt!), Icons.history),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161524),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5D5FEF).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R ${_currentBooking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Cancel button
            if (_currentBooking.status == BookingStatus.PENDING)
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Text(
                          'Cancel Booking Request',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  String _formatDateTime(DateTime date) {
    final dateStr = _formatDate(date);
    final hours = date.hour.toString().padLeft(2, '0');
    final mins = date.minute.toString().padLeft(2, '0');
    return '$dateStr at $hours:$mins';
  }
}
