// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/business_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/booking.dart';
import '../../models/rental_unit.dart';
import '../rental_unit/create_edit_unit_screen.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/cached_image_view.dart';
import 'business_detail_screen.dart';
import 'create_edit_business_screen.dart';
import 'owner_booking_requests_screen.dart';

/**
 * Screen presenting the Business Owner Dashboard interface.
 *
 * <p>Emerald Light Marketplace design:
 * - Real-time statistics (Units, Pending Requests, Active Bookings)
 * - Live catalogue preview carousel
 * - Quick business profile switcher
 * - Fast navigation to bookings and inventory management.</p>
 */
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Business? _selectedBusiness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final token = context.read<AuthService>().token;
    if (token == null) return;

    // Fetch owner's businesses
    await context.read<BusinessProvider>().fetchMyBusinesses(token);
    
    // Fetch owner's bookings
    await context.read<BookingProvider>().fetchOwnerBookings(token);

    final businesses = context.read<BusinessProvider>().myBusinesses;
    if (businesses.isNotEmpty) {
      setState(() {
        if (_selectedBusiness == null || !businesses.any((b) => b.id == _selectedBusiness!.id)) {
          _selectedBusiness = businesses.first;
        }
      });
      _fetchUnitsForSelected();
    }
  }

  void _fetchUnitsForSelected() {
    if (_selectedBusiness == null) return;
    context.read<RentalUnitProvider>().fetchUnitsForBusiness(_selectedBusiness!.id);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final businessProvider = context.watch<BusinessProvider>();
    final rentalUnitProvider = context.watch<RentalUnitProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    final myBusinesses = businessProvider.myBusinesses;
    final isLoading = businessProvider.isLoading || bookingProvider.isLoading || rentalUnitProvider.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: 'Owner Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondaryColor),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondaryColor),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: isLoading && myBusinesses.isEmpty
          ? const BkLoadingIndicator(message: 'Loading dashboard...')
          : RefreshIndicator(
              color: AppTheme.brandColor,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space20),
                child: myBusinesses.isEmpty
                    ? _buildEmptyState()
                    : _buildDashboardContent(rentalUnitProvider, bookingProvider, myBusinesses),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return BkEmptyState(
      icon: Icons.storefront_outlined,
      title: 'Register Your Business',
      message: 'Register your toilet hire or cold room rental business to start accepting client bookings.',
      actionLabel: 'Register Business',
      onAction: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateEditBusinessScreen(),
          ),
        );
        _loadDashboardData();
      },
    );
  }

  Widget _buildDashboardContent(
    RentalUnitProvider rentalUnitProvider,
    BookingProvider bookingProvider,
    List<Business> myBusinesses,
  ) {
    final currentBusiness = myBusinesses.firstWhere(
      (b) => b.id == _selectedBusiness?.id,
      orElse: () => myBusinesses.first,
    );

    final List<dynamic> rentalUnits = rentalUnitProvider.getUnitsForBusiness(currentBusiness.id);
    final unitIds = rentalUnits.map((u) => u.id).toSet();

    final businessBookings = bookingProvider.ownerBookings
        .where((b) => unitIds.contains(b.rentalUnitId))
        .toList();

    final pendingRequests = businessBookings.where((b) => b.status == BookingStatus.PENDING).length;
    final activeBookings = businessBookings.where((b) => b.status == BookingStatus.CONFIRMED).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Business Selector Card
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTIVE BUSINESS PROFILE',
                style: TextStyle(
                  color: AppTheme.brandColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Business>(
                    value: currentBusiness,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.brandColor),
                    items: myBusinesses.map((Business b) {
                      return DropdownMenuItem<Business>(
                        value: b,
                        child: Text(
                          b.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (Business? value) {
                      if (value != null) {
                        setState(() {
                          _selectedBusiness = value;
                        });
                        _fetchUnitsForSelected();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space20),

        // Statistics grid layout
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Rental Units', '${rentalUnits.length}', AppTheme.brandColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Pending Requests', '$pendingRequests', AppTheme.accentColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('Active Bookings', '$activeBookings', AppTheme.successColor, isFullWidth: true),

        const SizedBox(height: AppTheme.space24),

        // Live Inventory / Catalogue Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Inventory Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.2,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditUnitScreen(businessId: currentBusiness.id),
                  ),
                );
                _loadDashboardData();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.brandColor),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (rentalUnits.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppTheme.brandColor, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No units listed yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add your toilets or cold storage to begin accepting bookings.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 144,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rentalUnits.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final unit = rentalUnits[index] as RentalUnit;
                return Container(
                  width: 154,
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
                            builder: (context) => CreateEditUnitScreen(
                              businessId: currentBusiness.id,
                              unit: unit,
                            ),
                          ),
                        );
                        _loadDashboardData();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              child: CachedImageView(
                                imageUrl: unit.displayImageUrl,
                                width: double.infinity,
                                height: 68,
                                fit: BoxFit.cover,
                                fallbackIcon: unit.rentalUnitType == RentalUnitType.STANDARD_COLD_ROOM ||
                                        unit.rentalUnitType == RentalUnitType.MOBILE_COLD_ROOM
                                    ? Icons.ac_unit
                                    : Icons.wc,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              unit.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'R ${unit.pricePerDay.toStringAsFixed(0)}/d',
                                  style: const TextStyle(
                                    color: AppTheme.brandColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.photo_library_outlined, size: 10, color: AppTheme.textSecondaryColor),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${unit.images.length}',
                                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                                    ),
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
              },
            ),
          ),

        const SizedBox(height: AppTheme.space24),

        // Owner Actions
        const Text(
          'Management',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),

        _buildActionButton(
          label: 'Booking Requests',
          icon: Icons.calendar_today_outlined,
          badgeCount: pendingRequests,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerBookingRequestsScreen(business: currentBusiness),
              ),
            );
            _loadDashboardData();
          },
        ),
        const SizedBox(height: 10),

        _buildActionButton(
          label: 'Rental Units',
          icon: Icons.wc_outlined,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusinessDetailScreen(business: currentBusiness),
              ),
            );
            _loadDashboardData();
          },
        ),
        const SizedBox(height: 10),

        _buildActionButton(
          label: 'Business Profile',
          icon: Icons.edit_note_outlined,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEditBusinessScreen(business: currentBusiness),
              ),
            );
            _loadDashboardData();
          },
        ),

        const SizedBox(height: AppTheme.space20),
        BkSecondaryButton(
          label: 'Add Another Business',
          icon: Icons.add_business_outlined,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEditBusinessScreen(),
              ),
            );
            _loadDashboardData();
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(icon, color: AppTheme.brandColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: AppTheme.darkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
