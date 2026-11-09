// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../booking/create_booking_screen.dart';
import '../shared/widgets/cached_image_view.dart';
import '../shared/widgets/skeleton_loading_card.dart';
import 'customer_business_detail_screen.dart';
import 'rental_unit_detail_screen.dart';

/**
 * Screen presenting the redesigned Customer Marketplace for Back2Kasi.
 *
 * <p>Enables browsing available rental units with rich imagery, filtering by
 * township equipment categories, searching by keyword, exploring verified local
 * providers, and accessing photo galleries and booking workflows.</p>
 */
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  int _selectedTab = 0; // 0 = Rentals, 1 = Providers

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthService>().token;
    if (token != null) {
      context.read<BusinessProvider>().fetchAllBusinesses(token);
    }
    context.read<RentalUnitProvider>().fetchAllAvailableUnits();
  }

  List<RentalUnit> _filterUnits(List<RentalUnit> units) {
    return units.where((unit) {
      // Category filter
      if (_selectedCategory != 'ALL') {
        if (_selectedCategory == 'VIP_TOILET' && unit.rentalUnitType != RentalUnitType.VIP_TOILET) {
          return false;
        }
        if (_selectedCategory == 'STANDARD_TOILET' && unit.rentalUnitType != RentalUnitType.STANDARD_TOILET) {
          return false;
        }
        if (_selectedCategory == 'CHEMICAL_TOILET' && unit.rentalUnitType != RentalUnitType.CHEMICAL_TOILET) {
          return false;
        }
        if (_selectedCategory == 'COLD_ROOM' &&
            unit.rentalUnitType != RentalUnitType.STANDARD_COLD_ROOM &&
            unit.rentalUnitType != RentalUnitType.MOBILE_COLD_ROOM) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final nameMatch = unit.name.toLowerCase().contains(_searchQuery);
        final descMatch = unit.description?.toLowerCase().contains(_searchQuery) ?? false;
        final typeMatch = unit.rentalUnitType.toString().toLowerCase().contains(_searchQuery);
        if (!nameMatch && !descMatch && !typeMatch) return false;
      }

      return true;
    }).toList();
  }

  List<Business> _filterBusinesses(List<Business> businesses) {
    return businesses.where((business) {
      if (_selectedCategory != 'ALL') {
        if (_selectedCategory == 'COLD_ROOM' &&
            business.businessType != BusinessType.COLD_ROOM_RENTAL) {
          return false;
        }
        if ((_selectedCategory == 'VIP_TOILET' ||
                _selectedCategory == 'STANDARD_TOILET' ||
                _selectedCategory == 'CHEMICAL_TOILET') &&
            business.businessType != BusinessType.TOILET_RENTAL) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final nameMatch = business.name.toLowerCase().contains(_searchQuery);
        final descMatch = business.description?.toLowerCase().contains(_searchQuery) ?? false;
        final addrMatch = business.address.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !descMatch && !addrMatch) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final businessProvider = context.watch<BusinessProvider>();
    final rentalUnitProvider = context.watch<RentalUnitProvider>();

    final userEmail = authService.userEmail ?? 'Client';
    final rawUnits = rentalUnitProvider.allUnits;
    final rawBusinesses = businessProvider.allBusinesses;

    final filteredUnits = _filterUnits(rawUnits);
    final filteredBusinesses = _filterBusinesses(rawBusinesses);

    final isLoading = businessProvider.isLoading || rentalUnitProvider.isLoading;
    final errorMessage = businessProvider.errorMessage ?? rentalUnitProvider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5D5FEF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_outlined, color: Color(0xFF5D5FEF), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Back2Kasi',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Back2Kasi,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar with active filter text input
                    _buildSearchBar(),

                    const SizedBox(height: 16),

                    // Category Filter Pills
                    _buildCategoryPills(),

                    const SizedBox(height: 20),

                    // Segmented Tabs: Rentals vs Providers
                    _buildSegmentedTab(filteredUnits.length, filteredBusinesses.length),

                    const SizedBox(height: 16),

                    // Error banner
                    if (errorMessage != null && (rawUnits.isNotEmpty || rawBusinesses.isNotEmpty))
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content List (Rentals or Providers)
            if (isLoading && rawUnits.isEmpty && rawBusinesses.isEmpty)
              const SliverFillRemaining(
                child: MarketplaceSkeletonList(),
              )
            else if (_selectedTab == 0)
              filteredUnits.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No rentals found',
                        message: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'No available rental units match your filter criteria.'
                            : 'No rental units currently available for booking.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final unit = filteredUnits[index];
                            final business = rawBusinesses.cast<Business?>().firstWhere(
                                  (b) => b?.id == unit.businessId,
                                  orElse: () => null,
                                );
                            return _buildRentalCard(unit, business);
                          },
                          childCount: filteredUnits.length,
                        ),
                      ),
                    )
            else
              filteredBusinesses.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No providers found',
                        message: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'No registered providers match your filter criteria.'
                            : 'No registered service providers yet.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _buildBusinessCard(filteredBusinesses[index]);
                          },
                          childCount: filteredBusinesses.length,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161524),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by equipment, class, or township...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF5D5FEF)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = [
      {'key': 'ALL', 'label': 'All Categories', 'icon': Icons.grid_view},
      {'key': 'VIP_TOILET', 'label': 'VIP Trailers', 'icon': Icons.star_border},
      {'key': 'STANDARD_TOILET', 'label': 'Standard Toilets', 'icon': Icons.wc},
      {'key': 'CHEMICAL_TOILET', 'label': 'Chemical Toilets', 'icon': Icons.cleaning_services_outlined},
      {'key': 'COLD_ROOM', 'label': 'Cold Storage', 'icon': Icons.ac_unit},
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['key'];
          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              cat['icon'] as IconData,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            label: Text(cat['label'] as String),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            backgroundColor: const Color(0xFF161524),
            selectedColor: const Color(0xFF5D5FEF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color(0xFF5D5FEF) : Colors.white.withOpacity(0.06),
              ),
            ),
            onSelected: (val) {
              setState(() {
                _selectedCategory = cat['key'] as String;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSegmentedTab(int rentalCount, int providerCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161524),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              label: 'Available Rentals',
              count: rentalCount,
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              label: 'Local Providers',
              count: providerCount,
              icon: Icons.storefront_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D5FEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard(RentalUnit unit, Business? business) {
    final typeLabel = unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RentalUnitDetailScreen(
                unit: unit,
                business: business,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header with Badges
            Stack(
              children: [
                CachedImageView(
                  imageUrl: unit.displayImageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: unit.rentalUnitType == RentalUnitType.STANDARD_COLD_ROOM ||
                          unit.rentalUnitType == RentalUnitType.MOBILE_COLD_ROOM
                      ? Icons.ac_unit
                      : Icons.wc,
                ),

                // Category Badge (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Photo Count Badge (Top Right)
                if (unit.images.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${unit.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Price Tag Pill (Bottom Right of Image)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161524).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.4)),
                    ),
                    child: Text(
                      'R ${unit.pricePerDay.toStringAsFixed(2)} / day',
                      style: const TextStyle(
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          unit.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (business != null)
                    Row(
                      children: [
                        const Icon(Icons.storefront, size: 14, color: Color(0xFF5D5FEF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${business.name} • ${business.address}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Capacity: ${unit.capacity}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RentalUnitDetailScreen(
                                unit: unit,
                                business: business,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Details', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateBookingScreen(unit: unit),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Book Now', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    IconData businessIcon;
    String typeLabel;

    if (business.businessType == BusinessType.COLD_ROOM_RENTAL) {
      businessIcon = Icons.ac_unit;
      typeLabel = 'Cold Storage Provider';
    } else {
      businessIcon = Icons.wc;
      typeLabel = 'Toilet Rental Agency';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerBusinessDetailScreen(business: business),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF5D5FEF).withOpacity(0.15),
                    child: Icon(businessIcon, color: const Color(0xFF5D5FEF), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                        ),
                        Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Color(0xFF8C8DFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (business.description != null && business.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  business.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      business.address,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'View Inventory',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D5FEF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            if (_searchQuery.isNotEmpty || _selectedCategory != 'ALL') ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'ALL';
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
