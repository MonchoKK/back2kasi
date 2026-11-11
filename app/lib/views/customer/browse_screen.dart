// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/business_category.dart';
import '../../models/rental_unit.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/skeleton_loading_card.dart';
import 'customer_business_detail_screen.dart';

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

  List<Business> _filterBusinesses(List<Business> businesses, List<RentalUnit> units) {
    final unitsByBusiness = <int, List<RentalUnit>>{};
    for (final u in units) {
      unitsByBusiness.putIfAbsent(u.businessId, () => []).add(u);
    }

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

        // Also search across their catalogue items (e.g. searching "cake" finds bakeries selling cake)
        final bizUnits = unitsByBusiness[business.id] ?? [];
        final itemMatch = bizUnits.any((u) =>
            u.name.toLowerCase().contains(_searchQuery) ||
            (u.description?.toLowerCase().contains(_searchQuery) ?? false));

        if (!nameMatch && !descMatch && !addrMatch && !catMatch && !itemMatch) return false;
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

    final filteredBusinesses = _filterBusinesses(rawBusinesses, rawUnits);

    final unitsByBusiness = <int, List<RentalUnit>>{};
    for (final u in rawUnits) {
      unitsByBusiness.putIfAbsent(u.businessId, () => []).add(u);
    }

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
                      'Support Local • Kasi Marketplace',
                      style: TextStyle(
                        color: AppTheme.brandColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find products & services in your kasi',
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

                    // Section Heading: Local Businesses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory == 'ALL'
                              ? 'Local Businesses'
                              : BusinessCategory.fromString(_selectedCategory).displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            '${filteredBusinesses.length} ${filteredBusinesses.length == 1 ? 'business' : 'businesses'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Error banner
                    if (errorMessage != null && rawBusinesses.isNotEmpty)
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

            // Content List (Local Businesses)
            if (isLoading && rawBusinesses.isEmpty)
              const SliverFillRemaining(
                child: MarketplaceSkeletonList(),
              )
            else if (filteredBusinesses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: BkEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No businesses found',
                  message: _searchQuery.isNotEmpty || _selectedCategory != 'ALL'
                      ? 'No registered businesses match your search or category filter.'
                      : 'No businesses registered yet in this category.',
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
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final business = filteredBusinesses[index];
                      final bUnits = unitsByBusiness[business.id] ?? [];
                      return _buildBusinessCard(business, bUnits);
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

  Widget _buildBusinessCard(Business business, [List<RentalUnit>? businessUnits]) {
    final businessIcon = business.category.icon;
    final typeLabel = business.category.displayName;
    final itemCount = businessUnits?.length ?? 0;

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
                    Text(
                      itemCount > 0 ? '$itemCount items • View Catalogue' : 'View Catalogue',
                      style: const TextStyle(
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
