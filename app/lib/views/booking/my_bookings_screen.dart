// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../models/booking.dart';
import '../shared/components/bk_components.dart';
import 'booking_details_screen.dart';

/**
 * Screen displaying the user's booking history.
 *
 * <p>Emerald Light Marketplace design:
 * - Status chips with dot indicators
 * - Clean white cards with borders and subtle elevation
 * - Clear date ranges and total price breakdown.</p>
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final bookings = provider.myBookings;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: 'My Bookings',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondaryColor),
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
              color: AppTheme.errorColor.withOpacity(0.08),
              child: Text(
                errorMessage,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(
            child: isLoading && bookings.isEmpty
                ? const BkLoadingIndicator(message: 'Loading your bookings...')
                : RefreshIndicator(
                    color: AppTheme.brandColor,
                    onRefresh: () async => _loadBookings(),
                    child: bookings.isEmpty
                        ? BkEmptyState(
                            icon: Icons.calendar_today_outlined,
                            title: 'No bookings yet',
                            message: 'Browse available rental units in your kasi and place your first reservation.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.space16),
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

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(booking: booking),
              ),
            );
            _loadBookings();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status + Booking ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BkBookingStatusChip(status: booking.status),
                    Text(
                      'Booking #${booking.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rental Unit Name
                Text(
                  booking.rentalUnitName ?? 'Rental Unit #${booking.rentalUnitId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),

                // Business Name
                if (booking.businessName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 14, color: AppTheme.brandColor),
                      const SizedBox(width: 4),
                      Text(
                        booking.businessName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Dates
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDate(booking.startDate)} → ${_formatDate(booking.endDate)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),

                // Price and Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R ${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brandColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: AppTheme.brandColor),
                      ],
                    ),
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
