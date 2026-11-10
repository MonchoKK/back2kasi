// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../booking/create_booking_screen.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/cached_image_view.dart';
import 'rental_unit_detail_screen.dart';

/**
 * Screen presenting details of a selected business and its available rental units
 * from a customer perspective.
 *
 * <p>Styled according to the Emerald Light Marketplace identity.</p>
 */
class CustomerBusinessDetailScreen extends StatefulWidget {
  final Business business;

  const CustomerBusinessDetailScreen({super.key, required this.business});

  @override
  State<CustomerBusinessDetailScreen> createState() => _CustomerBusinessDetailScreenState();
}

class _CustomerBusinessDetailScreenState extends State<CustomerBusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnits();
    });
  }

  void _loadUnits() {
    context.read<RentalUnitProvider>().fetchUnitsForBusiness(widget.business.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalUnitProvider>();
    final units = provider.getUnitsForBusiness(widget.business.id);
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    // Customers only browse AVAILABLE units for booking
    final availableUnits = units.where((u) => u.status == RentalUnitStatus.AVAILABLE).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: widget.business.name,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Profile Header Card
          _buildBusinessHeaderCard(),

          // Error banner
          if (errorMessage != null && availableUnits.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.errorColor.withOpacity(0.08),
              child: Text(
                errorMessage,
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Available Inventory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.2,
              ),
            ),
          ),

          Expanded(
            child: isLoading && availableUnits.isEmpty
                ? const BkLoadingIndicator(message: 'Loading inventory...')
                : RefreshIndicator(
                    color: AppTheme.brandColor,
                    onRefresh: () async => _loadUnits(),
                    child: availableUnits.isEmpty
                        ? BkEmptyState(
                            icon: errorMessage != null ? Icons.wifi_off : Icons.inventory_2_outlined,
                            title: errorMessage != null ? 'Unable to load inventory' : 'No units available',
                            message: errorMessage ?? 'All units from this provider are currently booked or offline.',
                            actionLabel: 'Refresh',
                            onAction: _loadUnits,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: availableUnits.length,
                            itemBuilder: (context, index) {
                              final unit = availableUnits[index];
                              return _buildUnitCard(unit);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
                child: const Icon(Icons.storefront, color: AppTheme.brandColor, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                widget.business.businessType == BusinessType.TOILET_RENTAL
                    ? 'Sanitation & Toilet Rental'
                    : 'Cold Storage Provider',
                style: const TextStyle(
                  color: AppTheme.brandColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(RentalUnit unit) {
    final String typeLabel = unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit Cover Photo or Icon Header
          if (unit.displayImageUrl != null)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RentalUnitDetailScreen(
                      unit: unit,
                      business: widget.business,
                    ),
                  ),
                );
              },
              child: CachedImageView(
                imageUrl: unit.displayImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(color: AppTheme.brandColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
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
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  unit.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                if (unit.description != null && unit.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    unit.description!,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${unit.capacity}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    const Spacer(),
                    BkPriceDisplay(
                      pricePerDay: unit.pricePerDay,
                      fontSize: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: BkSecondaryButton(
                        label: 'View Details',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RentalUnitDetailScreen(
                                unit: unit,
                                business: widget.business,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BkPrimaryButton(
                        label: 'Book Now',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateBookingScreen(unit: unit),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
