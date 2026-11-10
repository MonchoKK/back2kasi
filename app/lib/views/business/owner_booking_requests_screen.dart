// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/booking.dart';
import '../shared/components/bk_components.dart';
import 'owner_booking_details_screen.dart';

/**
 * Screen presenting a tabbed view of active/pending booking requests and historical logs.
 *
 * <p>Emerald Light Marketplace design:
 * - Clean tab navigation
 * - Card-based request inspector with approve/decline CTAs
 * - Status chips and transparent price calculations.</p>
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
        backgroundColor: AppTheme.surfaceColor,
        title: Text('${statusText.toUpperCase()} Request', style: const TextStyle(color: AppTheme.textPrimaryColor)),
        content: Text(
          'Are you sure you want to $statusText booking request #${booking.id}?\n\n'
          'Customer ID: ${booking.customerId}\n'
          'Dates: ${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
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
              foregroundColor: targetStatus == BookingStatus.CONFIRMED ? AppTheme.brandColor : AppTheme.errorColor,
            ),
            child: Text(statusText.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
          const SnackBar(
            content: Text('Request updated successfully.'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final rentalUnitProvider = context.watch<RentalUnitProvider>();

    final units = rentalUnitProvider.getUnitsForBusiness(widget.business.id);
    final unitIds = units.map((u) => u.id).toSet();

    final businessBookings = bookingProvider.ownerBookings
        .where((b) => unitIds.contains(b.rentalUnitId))
        .toList();

    final pendingList = businessBookings.where((b) => b.status == BookingStatus.PENDING).toList();
    final historyList = businessBookings.where((b) => b.status != BookingStatus.PENDING).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.business.name,
            style: const TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.brandColor,
            labelColor: AppTheme.brandColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Booking History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pending Requests Tab
            RefreshIndicator(
              color: AppTheme.brandColor,
              onRefresh: () async => _loadData(),
              child: pendingList.isEmpty
                  ? BkEmptyState(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'No pending requests',
                      message: 'You will see new booking requests from customers here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      itemCount: pendingList.length,
                      itemBuilder: (context, index) {
                        return _buildRequestCard(pendingList[index], isPending: true);
                      },
                    ),
            ),
            // History Tab
            RefreshIndicator(
              color: AppTheme.brandColor,
              onRefresh: () async => _loadData(),
              child: historyList.isEmpty
                  ? BkEmptyState(
                      icon: Icons.history_outlined,
                      title: 'No historical bookings',
                      message: 'All confirmed, completed, or cancelled bookings will be saved here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.space16),
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

  Widget _buildRequestCard(Booking booking, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerBookingDetailsScreen(booking: booking),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking ID: #${booking.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    BkBookingStatusChip(status: booking.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.wc, size: 16, color: AppTheme.brandColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        booking.rentalUnitName ?? 'Rental Unit #${booking.rentalUnitId}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Price', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                        Text(
                          'R ${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ],
                    ),
                    if (isPending)
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _updateStatus(booking, BookingStatus.CANCELLED),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor, width: 1.2),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                            ),
                            child: const Text('Decline', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _updateStatus(booking, BookingStatus.CONFIRMED),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              backgroundColor: AppTheme.brandColor,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                            ),
                            child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    else
                      const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
