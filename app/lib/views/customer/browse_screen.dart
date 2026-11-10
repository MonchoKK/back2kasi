// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../core/contact_helper.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/cached_image_view.dart';
import '../shared/widgets/skeleton_loading_card.dart';
import 'customer_business_detail_screen.dart';
import 'rental_unit_detail_screen.dart';

/**
 * Screen presenting the redesigned Customer Marketplace for Back2Kasi.
 *
 * <p>Emerald Light Marketplace interface:
 * - Image-led rental unit and business discovery
 * - Category filter pills with Emerald active states
 * - Clean white cards with subtle borders and shadows
 * - Fast live search by equipment, class, or township.</p>
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

  List<RentalUnit> _filterUnits(List<RentalUnit> units, List<Business> businesses) {
    final businessMap = {for (var b in businesses) b.id: b};

    return units.where((unit) {
      // Category filter
      if (_selectedCategory != 'ALL') {
        final biz = businessMap[unit.businessId];
        if (biz != null) {
          if (biz.category.key != _selectedCategory) {
            return false;
          }
        } else if (_selectedCategory != 'EVENTS_RENTALS') {
          return false;
        }
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final nameMatch = unit.name.toLowerCase().contains(_searchQuery);
        final descMatch = unit.description?.toLowerCase().contains(_searchQuery) ?? false;
        final typeMatch = unit.rentalUnitType.toString().toLowerCase().contains(_searchQuery);
        final itemTypeMatch = (unit.isProduct ? 'product' : 'service').contains(_searchQuery);
        final priceMatch = unit.formattedPrice.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !descMatch && !typeMatch && !itemTypeMatch && !priceMatch) return false;
      }

      return true;
    }).toList();
  }

  List<Business> _filterBusinesses(List<Business> businesses) {
    return businesses.where((business) {
      if (_selectedCategory != 'ALL') {
        if (business.category.key != _selectedCategory) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final nameMatch = business.name.toLowerCase().contains(_searchQuery);
        final descMatch = business.description?.toLowerCase().contains(_searchQuery) ?? false;
        final addrMatch = business.address.toLowerCase().contains(_searchQuery);
        final catMatch = business.category.displayName.toLowerCase().contains(_searchQuery);
        if (!nameMatch && !descMatch && !addrMatch && !catMatch) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final businessProvider = context.watch<BusinessProvider>();
    final rentalUnitProvider = context.watch<RentalUnitProvider>();

    final rawUnits = rentalUnitProvider.allUnits;
    final rawBusinesses = businessProvider.allBusinesses;

    final filteredUnits = _filterUnits(rawUnits, rawBusinesses);
    final filteredBusinesses = _filterBusinesses(rawBusinesses);

    final isLoading = businessProvider.isLoading || rentalUnitProvider.isLoading;
    final errorMessage = businessProvider.errorMessage ?? rentalUnitProvider.errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.brandColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_outlined, color: AppTheme.brandColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Back2Kasi',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondaryColor),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.textSecondaryColor),
            tooltip: 'Logout',
            onPressed: () => authService.logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderColor, height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.brandColor,
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Welcome & Search Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local businesses. More opportunities.',
                      style: TextStyle(
                        color: AppTheme.brandColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find equipment rentals in your kasi',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input Field
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
                          color: AppTheme.errorColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
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
                      child: BkEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No rentals found',
                        message: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'No available rental units match your filter criteria.'
                            : 'No rental units currently available in catalogue.',
                        actionLabel: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'Reset Filters'
                            : null,
                        onAction: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'ALL';
                            _searchController.clear();
                          });
                        },
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
                      child: BkEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No providers found',
                        message: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'No registered providers match your filter criteria.'
                            : 'No registered service providers yet.',
                        actionLabel: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                            ? 'Reset Filters'
                            : null,
                        onAction: () {
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'ALL';
                            _searchController.clear();
                          });
                        },
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
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search products, services, or local businesses...',
          hintStyle: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppTheme.brandColor, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = [
      {'key': 'ALL', 'label': 'All Categories', 'icon': Icons.grid_view},
      {'key': 'BEAUTY', 'label': '💇 Beauty & Personal Care', 'icon': Icons.content_cut_outlined},
      {'key': 'FOOD', 'label': '🍔 Food & Catering', 'icon': Icons.restaurant_outlined},
      {'key': 'AUTOMOTIVE', 'label': '🚗 Automotive', 'icon': Icons.directions_car_outlined},
      {'key': 'RETAIL', 'label': '🛍️ Retail & Products', 'icon': Icons.shopping_bag_outlined},
      {'key': 'HOME_SERVICES', 'label': '🛠️ Home & Construction', 'icon': Icons.home_repair_service_outlined},
      {'key': 'EVENTS_RENTALS', 'label': '🎪 Events & Rentals', 'icon': Icons.celebration_outlined},
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
              color: isSelected ? AppTheme.white : AppTheme.textSecondaryColor,
            ),
            label: Text(cat['label'] as String),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.white : AppTheme.textSecondaryColor,
            ),
            backgroundColor: AppTheme.surfaceColor,
            selectedColor: AppTheme.brandColor,
            elevation: isSelected ? 1 : 0,
            pressElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              side: BorderSide(
                color: isSelected ? AppTheme.brandColor : AppTheme.borderColor,
                width: 1.2,
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
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderColor, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              label: 'Products & Services',
              count: rentalCount,
              icon: Icons.local_offer_outlined,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              label: 'Local Businesses',
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.white : AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.2) : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.white : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard(RentalUnit unit, Business? business) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unit.isProduct ? Icons.shopping_bag_outlined : Icons.handyman_outlined,
                            size: 11,
                            color: AppTheme.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit.isProduct ? 'Product' : 'Service',
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                          color: AppTheme.darkColor.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 12, color: AppTheme.white),
                            const SizedBox(width: 4),
                            Text(
                              '${unit.images.length}',
                              style: const TextStyle(
                                color: AppTheme.white,
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
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Text(
                        unit.formattedPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unit.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: const Text(
                            'Available',
                            style: TextStyle(
                              color: AppTheme.brandColor,
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
                          Icon(business.category.icon, size: 14, color: AppTheme.brandColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${business.name} • ${business.address}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          unit.isProduct ? Icons.inventory_2_outlined : Icons.build_outlined,
                          size: 15,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit.isProduct ? 'Product' : 'Service',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
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
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            side: const BorderSide(color: AppTheme.borderColor, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                          ),
                          child: const Text('Details', style: TextStyle(fontSize: 12, color: AppTheme.darkColor)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final targetBusiness = business;
                            if (targetBusiness == null) return;
                            final phone = targetBusiness.whatsappNumber ?? targetBusiness.phoneNumber;
                            final msg = ContactHelper.buildCatalogueItemMessage(
                              itemName: unit.name,
                              isProduct: unit.isProduct,
                            );
                            ContactHelper.launchWhatsApp(context, phone: phone, message: msg);
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                          label: const Text('Enquire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            backgroundColor: AppTheme.brandColor,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    final businessIcon = business.category.icon;
    final typeLabel = business.category.displayName;

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
                builder: (context) => CustomerBusinessDetailScreen(business: business),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(businessIcon, color: AppTheme.brandColor, size: 22),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: const TextStyle(
                                  color: AppTheme.brandColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              if (business.isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.accentColor.withOpacity(0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 10, color: Color(0xFFB45309)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (business.whatsappEnabled &&
                                  business.whatsappNumber != null &&
                                  business.whatsappNumber!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, size: 10, color: Color(0xFF25D366)),
                                      SizedBox(width: 3),
                                      Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF25D366),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                  ],
                ),
                if (business.description != null && business.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    business.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        business.address,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View Catalogue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandColor,
                        fontWeight: FontWeight.w600,
                      ),
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
}
