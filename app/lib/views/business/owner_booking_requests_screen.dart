// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/booking.dart';
import 'owner_booking_details_screen.dart';

/**
 * Screen presenting a tabbed view of active/pending booking requests and historical logs.
 *
 * <p>Exposes inline Approve/Decline actions for pending items and navigates
 * to inspector detail cards.</p>
 */
class OwnerBookingRequestsScreen extends StatefulWidget {
  final Business business;

  const OwnerBookingRequestsScreen({super.key, required this.business});

  @override
  State<OwnerBookingRequestsScreen> createState() => _OwnerBookingRequestsScreenState();
}

class _OwnerBookingRequestsScreenState extends State<OwnerBookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final token = context.read<AuthService>().token;
    if (token != null) {
      context.read<BookingProvider>().fetchOwnerBookings(token);
    }
  }

  Future<void> _updateStatus(Booking booking, BookingStatus targetStatus) async {
    final String statusText = targetStatus == BookingStatus.CONFIRMED ? 'approve' : 'decline';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${statusText.toUpperCase()} Request'),
        content: Text(
          'Are you sure you want to $statusText booking request #${booking.id}?\n\n'
          'Customer: ${booking.customerId}\n'
          'Dates: ${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: targetStatus == BookingStatus.CONFIRMED ? const Color(0xFF66BB6A) : Colors.redAccent,
            ),
            child: Text(statusText.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token == null) return;

      try {
        await context.read<BookingProvider>().updateBookingStatus(booking.id, targetStatus, token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request updated successfully.'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final rentalUnitProvider = context.watch<RentalUnitProvider>();

    final units = rentalUnitProvider.getUnitsForBusiness(widget.business.id);
    final unitIds = units.map((u) => u.id).toSet();

    // Filter bookings belonging to this business's units
    final businessBookings = bookingProvider.ownerBookings
        .where((b) => unitIds.contains(b.rentalUnitId))
        .toList();

    final pendingList = businessBookings.where((b) => b.status == BookingStatus.PENDING).toList();
    final historyList = businessBookings.where((b) => b.status != BookingStatus.PENDING).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.business.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Booking History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending Requests Tab
            RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: pendingList.isEmpty
                  ? _buildEmptyState('No pending requests', 'You will see new booking requests from customers here.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        return _buildRequestCard(pendingList[index], isPending: true);
                      },
                    ),
            ),
            // History Tab
            RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: historyList.isEmpty
                  ? _buildEmptyState('No historical bookings', 'All confirmed, completed, or cancelled bookings will be saved here.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        return _buildRequestCard(historyList[index], isPending: false);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String description) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 72,
              color: Colors.grey.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Booking booking, {required bool isPending}) {
    // Status Badge Mappings
    Color badgeColor;
    Color textColor;
    String statusLabel;

    switch (booking.status) {
      case BookingStatus.PENDING:
        badgeColor = const Color(0xFFFFB74D).withOpacity(0.15);
        textColor = const Color(0xFFFFB74D);
        statusLabel = 'Pending';
        break;
      case BookingStatus.CONFIRMED:
        badgeColor = const Color(0xFF5D5FEF).withOpacity(0.15);
        textColor = const Color(0xFF8C8DFF);
        statusLabel = 'Confirmed';
        break;
      case BookingStatus.COMPLETED:
        badgeColor = const Color(0xFF66BB6A).withOpacity(0.15);
        textColor = const Color(0xFF81C784);
        statusLabel = 'Completed';
        break;
      case BookingStatus.CANCELLED:
        badgeColor = const Color(0xFFEF5350).withOpacity(0.15);
        textColor = const Color(0xFFE57373);
        statusLabel = 'Cancelled';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OwnerBookingDetailsScreen(booking: booking),
            ),
          );
          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header ID + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking ID: #${booking.id}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Unit details
              Text(
                booking.rentalUnitName ?? 'Rental Unit',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Dates
              Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 16, color: Color(0xFF5D5FEF)),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Notes preview
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(color: Colors.white10, height: 24),

              // Pricing Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'R ${booking.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (isPending)
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _updateStatus(booking, BookingStatus.CANCELLED),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateStatus(booking, BookingStatus.CONFIRMED),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D5FEF),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
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
