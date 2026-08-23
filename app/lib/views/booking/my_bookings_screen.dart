// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../models/booking.dart';

/**
 * Screen displaying the user's booking history.
 *
 * <p>Fetches bookings from the backend via {@link BookingProvider} and displays
 * them as cards with status badges. Pending bookings can be cancelled.</p>
 */
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  void _loadBookings() {
    final token = context.read<AuthService>().token;
    if (token != null) {
      context.read<BookingProvider>().fetchMyBookings(token);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel booking #${booking.id}?\n\n'
          '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token != null) {
        try {
          await context.read<BookingProvider>().cancelBooking(booking.id, token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled'),
              backgroundColor: Color(0xFF66BB6A),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final bookings = provider.myBookings;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (errorMessage != null && bookings.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.redAccent.withOpacity(0.1),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(
            child: isLoading && bookings.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadBookings(),
                    child: bookings.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              return _buildBookingCard(bookings[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse available rental units and make your first booking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    // Status badge styling
    Color badgeColor;
    Color textColor;
    IconData statusIcon;
    String statusLabel;

    switch (booking.status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status + Booking ID
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: textColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Booking #${booking.id}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: Color(0xFF5D5FEF)),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Duration + Unit ID
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking.endDate.difference(booking.startDate).inDays} day(s)',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.home_work_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Unit #${booking.rentalUnitId}',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),

            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.notes!,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),

            // Footer: Total Price + Cancel
            Row(
              children: [
                Text(
                  'R ${booking.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (booking.status == BookingStatus.PENDING)
                  TextButton.icon(
                    onPressed: () => _cancelBooking(booking),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
