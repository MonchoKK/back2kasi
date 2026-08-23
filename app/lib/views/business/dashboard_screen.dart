// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/booking_provider.dart';
import '../../core/business_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/booking.dart';
import 'business_detail_screen.dart';
import 'create_edit_business_screen.dart';
import 'owner_booking_requests_screen.dart';

/**
 * Screen presenting the Business Owner Dashboard interface.
 *
 * <p>Enables selecting among owned businesses, viewing real-time statistics
 * (Units, Pending Requests, and Active Bookings), and accessing management sections.</p>
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
        // Keep selection if still valid, otherwise default to first
        if (_selectedBusiness == null || !businesses.any((b) => b.id == _selectedBusiness!.id)) {
          _selectedBusiness = businesses.first;
        }
      });
      // Fetch units for current selected business
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
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: isLoading && myBusinesses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: myBusinesses.isEmpty
                    ? _buildEmptyState()
                    : _buildDashboardContent(rentalUnitProvider, bookingProvider, myBusinesses),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        const Icon(
          Icons.storefront_outlined,
          size: 80,
          color: Color(0xFFFFB74D),
        ),
        const SizedBox(height: 24),
        const Text(
          'Register Your Business',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Register your toilet hire or cold room rental business to start accepting client bookings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEditBusinessScreen(),
              ),
            );
            _loadDashboardData();
          },
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Register Business'),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(
    RentalUnitProvider rentalUnitProvider,
    BookingProvider bookingProvider,
    List<Business> myBusinesses,
  ) {
    // Dropdown value validation
    final currentBusiness = myBusinesses.firstWhere(
      (b) => b.id == _selectedBusiness?.id,
      orElse: () => myBusinesses.first,
    );

    // Filter rental units and bookings for selected business
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161524),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Business',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Business>(
                    value: currentBusiness,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF161524),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5D5FEF)),
                    items: myBusinesses.map((Business b) {
                      return DropdownMenuItem<Business>(
                        value: b,
                        child: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        const SizedBox(height: 24),

        // Statistics grid layout
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Rental Units', '${rentalUnits.length}', const Color(0xFF5D5FEF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Pending Requests', '$pendingRequests', const Color(0xFFFFB74D)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard('Active Bookings', '$activeBookings', const Color(0xFF66BB6A), isFullWidth: true),

        const SizedBox(height: 32),

        // Owner Actions
        const Text(
          'Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
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
        const SizedBox(height: 12),

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
        const SizedBox(height: 12),

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

        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEditBusinessScreen(),
              ),
            );
            _loadDashboardData();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Another Business'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161524),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161524),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5D5FEF)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
