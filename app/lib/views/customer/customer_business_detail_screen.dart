// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/contact_helper.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
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

    // Customers browse AVAILABLE catalogue items
    final availableUnits = units.where((u) => u.status == RentalUnitStatus.AVAILABLE).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: widget.business.name,
      ),
      body: RefreshIndicator(
        color: AppTheme.brandColor,
        onRefresh: () async => _loadUnits(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Business Profile Header Card
            SliverToBoxAdapter(
              child: _buildBusinessHeaderCard(),
            ),

            // Error banner
            if (errorMessage != null && availableUnits.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Products & Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (availableUnits.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          '${availableUnits.length} ${availableUnits.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Catalogue Content
            if (isLoading && availableUnits.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: BkLoadingIndicator(message: 'Loading catalogue...'),
              )
            else if (availableUnits.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: BkEmptyState(
                  icon: errorMessage != null ? Icons.wifi_off : Icons.inventory_2_outlined,
                  title: errorMessage != null ? 'Unable to load catalogue' : 'No items listed yet',
                  message: errorMessage ??
                      'This business has not added any products or services to their catalogue yet.',
                  actionLabel: 'Refresh',
                  onAction: _loadUnits,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final unit = availableUnits[index];
                      return _buildUnitCard(unit);
                    },
                    childCount: availableUnits.length,
                  ),
                ),
              ),
          ],
        ),
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
                child: Icon(widget.business.category.icon, color: AppTheme.brandColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.business.category.displayName,
                        style: const TextStyle(
                          color: AppTheme.brandColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.business.isVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.accentColor.withOpacity(0.4), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 11, color: Color(0xFFB45309)),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
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
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Main Contact Action Row
          Row(
            children: [
              Expanded(
                child: BkPrimaryButton(
                  label: 'Chat with Business',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () {
                    final phone = widget.business.whatsappNumber ?? widget.business.phoneNumber;
                    final msg = ContactHelper.buildBusinessEnquiryMessage(
                      customWelcomeMessage: widget.business.whatsappMessage,
                    );
                    ContactHelper.launchWhatsApp(context, phone: phone, message: msg);
                  },
                ),
              ),
              const SizedBox(width: 10),
              BkSecondaryButton(
                label: 'Call',
                icon: Icons.phone_forwarded_outlined,
                onPressed: () {
                  ContactHelper.launchCall(context, phone: widget.business.phoneNumber);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(RentalUnit unit) {
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
                      child: Text(
                        unit.isProduct ? 'Product' : 'Service',
                        style: const TextStyle(color: AppTheme.brandColor, fontSize: 11, fontWeight: FontWeight.bold),
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
                    Icon(
                      unit.isProduct ? Icons.inventory_2_outlined : Icons.build_outlined,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unit.isProduct ? 'Physical Item' : 'Service Offering',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    const Spacer(),
                    Text(
                      unit.formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
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
                      flex: 6,
                      child: BkPrimaryButton(
                        label: 'Enquire on WhatsApp',
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () {
                          final phone = widget.business.whatsappNumber ?? widget.business.phoneNumber;
                          final msg = ContactHelper.buildCatalogueItemMessage(
                            itemName: unit.name,
                            isProduct: unit.isProduct,
                          );
                          ContactHelper.launchWhatsApp(context, phone: phone, message: msg);
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
