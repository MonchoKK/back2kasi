// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/business_provider.dart';
import '../../core/contact_helper.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/cached_image_view.dart';
import 'customer_business_detail_screen.dart';

/**
 * Screen presenting comprehensive rental unit details and an interactive photo gallery.
 *
 * <p>Emerald Light Marketplace design:
 * - High-resolution hero photo carousel with dot indicators
 * - Pinch-to-zoom interactive lightbox
 * - Key specification tiles with clean white cards
 * - Sticky bottom WhatsApp enquiry bar with Emerald CTA button.</p>
 */
class RentalUnitDetailScreen extends StatefulWidget {
  final RentalUnit unit;
  final Business? business;

  const RentalUnitDetailScreen({
    super.key,
    required this.unit,
    this.business,
  });

  @override
  State<RentalUnitDetailScreen> createState() => _RentalUnitDetailScreenState();
}

class _RentalUnitDetailScreenState extends State<RentalUnitDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Business? _findBusiness(BuildContext context) {
    if (widget.business != null) return widget.business;
    final all = context.read<BusinessProvider>().allBusinesses;
    try {
      return all.firstWhere((b) => b.id == widget.unit.businessId);
    } catch (_) {
      return null;
    }
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedImageView(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: AppTheme.darkColor.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.white, size: 24),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = _findBusiness(context);
    final images = widget.unit.images;
    final typeLabel = widget.unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo Gallery Hero Carousel
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.surfaceColor.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: AppTheme.backgroundColor,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.unit.rentalUnitType == RentalUnitType.STANDARD_COLD_ROOM ||
                                    widget.unit.rentalUnitType == RentalUnitType.MOBILE_COLD_ROOM
                                ? Icons.ac_unit
                                : Icons.wc,
                            size: 64,
                            color: AppTheme.textSecondaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No listing photos uploaded',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentImageIndex = idx;
                            });
                          },
                          itemBuilder: (context, index) {
                            final img = images[index];
                            return GestureDetector(
                              onTap: () => _openFullScreenImage(img.imageUrl),
                              child: CachedImageView(
                                imageUrl: img.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 320,
                              ),
                            );
                          },
                        ),

                        // Image Counter Badge (bottom right)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.darkColor.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 14, color: AppTheme.white),
                                const SizedBox(width: 6),
                                Text(
                                  '${_currentImageIndex + 1} / ${images.length}',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dot indicators (bottom center)
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: i == _currentImageIndex ? 20 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: i == _currentImageIndex
                                        ? AppTheme.brandColor
                                        : Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // Unit Specifications & Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 13, color: AppTheme.brandColor),
                            SizedBox(width: 4),
                            Text(
                              'Available Now',
                              style: TextStyle(
                                color: AppTheme.brandColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.darkColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Unit Name & Daily Price
                  Text(
                    widget.unit.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  BkPriceDisplay(
                    pricePerDay: widget.unit.pricePerDay,
                    fontSize: 26,
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 16),

                  // Key Highlights
                  Row(
                    children: [
                      _buildFeatureTile(
                        icon: Icons.people_outline,
                        title: 'Capacity',
                        subtitle: '${widget.unit.capacity} Users / Units',
                      ),
                      const SizedBox(width: 14),
                      _buildFeatureTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Quality',
                        subtitle: 'Cleaned & Serviced',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About this rental',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (widget.unit.description != null && widget.unit.description!.isNotEmpty)
                        ? widget.unit.description!
                        : 'No detailed description provided for this listing. Contact provider for specific custom requirements.',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Business Provider Card
                  if (business != null) ...[
                    const Text(
                      'Listed By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  child: const Icon(Icons.storefront, color: AppTheme.brandColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        business.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        business.address,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Trust & Safety Badges
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(color: AppTheme.borderColor, width: 1.0),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: const Column(
                      children: [
                        _TrustItem(
                          icon: Icons.verified_user_outlined,
                          text: 'Direct communication with verified local township business owner.',
                        ),
                        SizedBox(height: 12),
                        _TrustItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: 'Fast WhatsApp response for quotes, availability, and event dates.',
                        ),
                        SizedBox(height: 12),
                        _TrustItem(
                          icon: Icons.local_shipping_outlined,
                          text: 'Delivery, positioning, and site servicing arranged directly with provider.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80), // Padding for sticky bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom WhatsApp Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: const Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price per day', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                  BkPriceDisplay(
                    pricePerDay: widget.unit.pricePerDay,
                    fontSize: 20,
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: BkPrimaryButton(
                  label: 'Enquire on WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () {
                    final targetBusiness = business;
                    if (targetBusiness == null) return;
                    final phone = targetBusiness.whatsappNumber ?? targetBusiness.phoneNumber;
                    final msg = ContactHelper.buildCatalogueItemMessage(
                      itemName: widget.unit.name,
                    );
                    ContactHelper.launchWhatsApp(context, phone: phone, message: msg);
                  },
                ),
              ),
              if (business != null && business.phoneNumber.isNotEmpty) ...[
                const SizedBox(width: 8),
                BkSecondaryButton(
                  label: 'Call',
                  icon: Icons.phone_forwarded_outlined,
                  onPressed: () {
                    ContactHelper.launchCall(context, phone: business.phoneNumber);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: AppTheme.borderColor, width: 1.0),
          boxShadow: AppTheme.cardShadow,
        ),
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.brandColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4),
          ),
        ),
      ],
    );
  }
}
