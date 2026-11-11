// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../rental_unit/create_edit_unit_screen.dart';
import 'create_edit_business_screen.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/cached_image_view.dart';

/**
 * Screen displaying details of a specific business profile and listing its
 * registered rental units (toilets, cold rooms).
 *
 * <p>Emerald Light Marketplace design:
 * - Inventory status filter chips (All, Available, Rented, Maintenance)
 * - Clean white cards with image preview and status badges
 * - One-tap status toggling and quick catalogue editing.</p>
 */
class BusinessDetailScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  RentalUnitStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<RentalUnitProvider>().fetchUnitsForBusiness(widget.business.id);
  }

  Future<void> _toggleUnitStatus(RentalUnit unit) async {
    final token = context.read<AuthService>().token;
    if (token == null) return;

    final newStatus = unit.status == RentalUnitStatus.AVAILABLE
        ? RentalUnitStatus.UNDER_MAINTENANCE
        : RentalUnitStatus.AVAILABLE;

    try {
      await context.read<RentalUnitProvider>().updateRentalUnit(
            unit.id,
            businessId: widget.business.id,
            name: unit.name,
            description: unit.description,
            pricePerDay: unit.pricePerDay,
            capacity: unit.capacity,
            type: unit.rentalUnitType,
            status: newStatus,
            token: token,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == RentalUnitStatus.AVAILABLE
                ? 'Item marked as Available'
                : 'Item marked as Paused / Unavailable',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _deleteUnit(RentalUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Unit', style: TextStyle(color: AppTheme.textPrimaryColor)),
        content: Text(
          'Are you sure you want to permanently delete "${unit.name}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token != null) {
        try {
          await context.read<RentalUnitProvider>().deleteRentalUnit(unit.id, widget.business.id, token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catalogue item deleted successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(String label, RentalUnitStatus? status) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
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
          _statusFilter = status;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalUnitProvider>();
    final units = provider.getUnitsForBusiness(widget.business.id);
    final filteredUnits = _statusFilter == null
        ? units
        : units.where((u) => u.status == _statusFilter).toList();
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: widget.business.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondaryColor),
            tooltip: 'Edit Business Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEditBusinessScreen(business: widget.business),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondaryColor),
            tooltip: 'Refresh Units',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Meta Header Card
          _buildBusinessHeaderCard(),

          // Error message banner
          if (errorMessage != null && units.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.errorColor.withOpacity(0.08),
              child: Text(
                errorMessage,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Catalogue Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '${filteredUnits.length} of ${units.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          if (units.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${units.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Available (${units.where((u) => u.status == RentalUnitStatus.AVAILABLE).length})',
                      RentalUnitStatus.AVAILABLE,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Paused / Inactive (${units.where((u) => u.status != RentalUnitStatus.AVAILABLE).length})',
                      RentalUnitStatus.UNDER_MAINTENANCE,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: isLoading && units.isEmpty
                ? const BkLoadingIndicator(message: 'Loading catalogue...')
                : RefreshIndicator(
                    color: AppTheme.brandColor,
                    onRefresh: () async => _loadData(),
                    child: filteredUnits.isEmpty
                        ? BkEmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: 'No items found',
                            message: _statusFilter != null
                                ? 'No catalogue items match this status filter.'
                                : 'Add your products or services to display them to customers and receive direct WhatsApp enquiries.',
                            actionLabel: _statusFilter != null ? 'Show All Items' : 'Add Item',
                            onAction: () {
                              if (_statusFilter != null) {
                                setState(() {
                                  _statusFilter = null;
                                });
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateEditUnitScreen(businessId: widget.business.id),
                                  ),
                                );
                              }
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredUnits.length,
                            itemBuilder: (context, index) {
                              final item = filteredUnits[index];
                              return _buildUnitCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.brandColor,
        foregroundColor: AppTheme.white,
        tooltip: 'Add Catalogue Item',
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEditUnitScreen(businessId: widget.business.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBusinessHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(widget.business.category.icon, color: AppTheme.brandColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.business.category.displayName,
                      style: const TextStyle(
                        color: AppTheme.brandColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.business.isVerified) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.verified, size: 13, color: AppTheme.accentColor),
                          SizedBox(width: 4),
                          Text(
                            'Verified Kasi Business',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.business.description != null && widget.business.description!.isNotEmpty)
            Text(
              widget.business.description!,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.4),
            ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.business.address,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 6),
              Text(
                widget.business.phoneNumber,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.business.whatsappEnabled
                      ? AppTheme.brandColor.withOpacity(0.12)
                      : AppTheme.darkColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(
                    color: widget.business.whatsappEnabled
                        ? AppTheme.brandColor.withOpacity(0.3)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.business.whatsappEnabled ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                      size: 11,
                      color: widget.business.whatsappEnabled ? AppTheme.brandColor : AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.business.whatsappEnabled ? 'WhatsApp Active' : 'WhatsApp Disabled',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: widget.business.whatsappEnabled ? AppTheme.brandColor : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(RentalUnit unit) {
    Color badgeBg;
    Color badgeFg;
    String statusLabel;

    switch (unit.status) {
      case RentalUnitStatus.AVAILABLE:
        badgeBg = AppTheme.brandColor.withOpacity(0.12);
        badgeFg = AppTheme.brandColor;
        statusLabel = 'Available';
        break;
      case RentalUnitStatus.RENTED:
        badgeBg = const Color(0xFF3B82F6).withOpacity(0.12);
        badgeFg = const Color(0xFF2563EB);
        statusLabel = 'Unavailable';
        break;
      case RentalUnitStatus.UNDER_MAINTENANCE:
        badgeBg = AppTheme.accentColor.withOpacity(0.15);
        badgeFg = const Color(0xFFD97706);
        statusLabel = 'Paused';
        break;
    }

    final isProduct = unit.itemType == ItemType.PRODUCT;

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateEditUnitScreen(
                  businessId: widget.business.id,
                  unit: unit,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail if available
              if (unit.displayImageUrl != null)
                CachedImageView(
                  imageUrl: unit.displayImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Product vs Service Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isProduct
                                ? const Color(0xFF3B82F6).withOpacity(0.12)
                                : AppTheme.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            isProduct ? 'Product' : 'Service',
                            style: TextStyle(
                              color: isProduct ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(color: badgeFg, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        if (unit.images.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.photo_library_outlined, size: 14, color: AppTheme.textSecondaryColor),
                              const SizedBox(width: 4),
                              Text(
                                '${unit.images.length}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                              ),
                            ],
                          ),
                        const SizedBox(width: 4),
                        // Quick Action Popover (Toggle status / Delete)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondaryColor),
                          color: AppTheme.surfaceColor,
                          onSelected: (value) {
                            if (value == 'toggle_status') {
                              _toggleUnitStatus(unit);
                            } else if (value == 'delete') {
                              _deleteUnit(unit);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle_status',
                              child: Row(
                                children: [
                                  Icon(
                                    unit.status == RentalUnitStatus.AVAILABLE
                                        ? Icons.pause_circle_outline
                                        : Icons.check_circle_outline,
                                    size: 18,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    unit.status == RentalUnitStatus.AVAILABLE
                                        ? 'Pause / Mark Unavailable'
                                        : 'Mark as Available',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                                  SizedBox(width: 8),
                                  Text('Delete Item', style: TextStyle(color: AppTheme.errorColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      unit.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    if (unit.description != null && unit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        unit.description!,
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (unit.capacity > 0) ...[
                          const Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Capacity: ${unit.capacity}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                          ),
                        ] else ...[
                          Icon(
                            isProduct ? Icons.inventory_2_outlined : Icons.handyman_outlined,
                            size: 15,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isProduct ? 'Item for Sale / Hire' : 'Service by Quote / Booking',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          unit.formattedPrice,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandColor,
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
}
