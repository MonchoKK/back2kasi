import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/business.dart';
import '../../../models/rental_unit.dart';
import '../widgets/cached_image_view.dart';
import 'bk_chips.dart';

/**
 * Image-rich catalogue card representing a rental unit listing.
 */
class BkCatalogueCard extends StatelessWidget {
  final RentalUnit unit;
  final VoidCallback onTap;
  final String? businessName;

  const BkCatalogueCard({
    super.key,
    required this.unit,
    required this.onTap,
    this.businessName,
  });

  String _formatType(RentalUnitType type) {
    switch (type) {
      case RentalUnitType.VIP_TOILET:
        return 'VIP Toilet';
      case RentalUnitType.STANDARD_TOILET:
        return 'Standard Toilet';
      case RentalUnitType.CHEMICAL_TOILET:
        return 'Chemical Toilet';
      case RentalUnitType.MOBILE_COLD_ROOM:
        return 'Mobile Cold Room';
      case RentalUnitType.STANDARD_COLD_ROOM:
        return 'Standard Cold Room';
      case RentalUnitType.GENERAL_PRODUCT:
        return 'Product';
      case RentalUnitType.GENERAL_SERVICE:
        return 'Service';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = unit.status == RentalUnitStatus.AVAILABLE;
    final primaryImageUrl = unit.primaryImageUrl;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header with overlay badges
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: primaryImageUrl != null
                        ? CachedImageView(
                            imageUrl: primaryImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppTheme.backgroundColor,
                            child: Icon(
                              unit.rentalUnitType.toString().contains('COLD')
                                  ? Icons.ac_unit_outlined
                                  : Icons.wc_outlined,
                              size: 48,
                              color: AppTheme.textSecondaryColor.withOpacity(0.4),
                            ),
                          ),
                  ),
                  // Availability badge
                  Positioned(
                    top: AppTheme.space12,
                    right: AppTheme.space12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppTheme.brandColor
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        isAvailable ? 'AVAILABLE' : 'RENTED',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Category Tag
                  Positioned(
                    bottom: AppTheme.space12,
                    left: AppTheme.space12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _formatType(unit.rentalUnitType),
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Unit Details Body
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (businessName != null) ...[
                      Text(
                        businessName!,
                        style: const TextStyle(
                          color: AppTheme.brandColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.space4),
                    ],
                    Text(
                      unit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 15,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          'Capacity: ${unit.capacity} units',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BkPriceDisplay(pricePerDay: unit.pricePerDay),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.brandColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
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

/**
 * Clean white business discovery card for local service providers.
 */
class BkBusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BkBusinessCard({
    super.key,
    required this.business,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isColdRoom = business.businessType == BusinessType.COLD_ROOM_RENTAL;
    final typeLabel = isColdRoom ? 'Cold Storage Provider' : 'Sanitation & Toilets';

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
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        isColdRoom ? Icons.ac_unit : Icons.clean_hands_outlined,
                        color: AppTheme.brandColor,
                        size: 24,
                      ),
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
                          Text(
                            typeLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.brandColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ],
                ),
                if (business.description != null && business.description!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space12),
                  Text(
                    business.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppTheme.space12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        business.address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

