// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../models/booking.dart';

/**
 * Screen presenting an inspector card for owners to evaluate booking requests.
 *
 * <p>Enables transition actions (Approve, Decline, Complete) depending on current lifecycle state.</p>
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
        title: Text('${actionText.toUpperCase()} REQUEST'),
        content: Text('Are you sure you want to $actionText booking request #${_currentBooking.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: targetStatus == BookingStatus.CONFIRMED || targetStatus == BookingStatus.COMPLETED
                  ? const Color(0xFF66BB6A)
                  : Colors.redAccent,
            ),
            child: Text(actionText.toUpperCase()),
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
            backgroundColor: const Color(0xFF66BB6A),
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
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String typeLabel = _currentBooking.rentalUnitName ?? 'Rental Unit';
    final int numberOfDays = _currentBooking.endDate.difference(_currentBooking.startDate).inDays;

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
        title: const Text('Booking Request Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
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

            // Summary Variables
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
                  _buildDetailRow('Customer ID', '${_currentBooking.customerId}', Icons.person_outline),
                  const Divider(color: Colors.white10, height: 24),
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

            // Total financial summary
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
                    'Price',
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

            // Contextual Actions
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_currentBooking.status == BookingStatus.PENDING) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(BookingStatus.CANCELLED),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          ),
                          child: const Text('Decline Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _updateStatus(BookingStatus.CONFIRMED),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                          ),
                          child: const Text('Approve Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_currentBooking.status == BookingStatus.CONFIRMED) ...[
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(BookingStatus.COMPLETED),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Mark Booking Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                    ),
                  ),
                ),
              ],
            ],
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
