// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../booking/create_booking_screen.dart';
import '../shared/widgets/cached_image_view.dart';
import 'customer_business_detail_screen.dart';

/**
 * Screen presenting comprehensive rental unit details and an interactive photo gallery.
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
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
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
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo Gallery Hero Carousel
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF0F0E17).withOpacity(0.7),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                      color: const Color(0xFF161524),
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
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No listing photos uploaded',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
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
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '${_currentImageIndex + 1} / ${images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                (i) => Container(
                                  width: i == _currentImageIndex ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: i == _currentImageIndex
                                        ? const Color(0xFF5D5FEF)
                                        : Colors.white38,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF81C784)),
                            SizedBox(width: 4),
                            Text(
                              'Available Now',
                              style: TextStyle(
                                color: Color(0xFF81C784),
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
                          color: const Color(0xFF5D5FEF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Color(0xFF8C8DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Unit Name & Daily Price
                  Text(
                    widget.unit.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'R ${widget.unit.pricePerDay.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB74D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ day',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Key Highlights
                  Row(
                    children: [
                      _buildFeatureTile(
                        icon: Icons.people_outline,
                        title: 'Capacity',
                        subtitle: '${widget.unit.capacity} Users / Units',
                      ),
                      const SizedBox(width: 16),
                      _buildFeatureTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Quality',
                        subtitle: 'Cleaned & Tested',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About this rental',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (widget.unit.description != null && widget.unit.description!.isNotEmpty)
                        ? widget.unit.description!
                        : 'No detailed description provided for this listing. Contact provider for specific custom requirements.',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 28),

                  // Business Provider Card
                  if (business != null) ...[
                    const Text(
                      'Listed By',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerBusinessDetailScreen(business: business),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161524),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF5D5FEF).withOpacity(0.15),
                              child: const Icon(Icons.storefront, color: Color(0xFF5D5FEF)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    business.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    business.address,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Trust & Safety Badges
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161524).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: const Column(
                      children: [
                        _TrustItem(
                          icon: Icons.security_outlined,
                          text: 'Direct booking requests reviewed by business owner.',
                        ),
                        SizedBox(height: 10),
                        _TrustItem(
                          icon: Icons.cancel_outlined,
                          text: 'Free cancellation until booking request is confirmed.',
                        ),
                        SizedBox(height: 10),
                        _TrustItem(
                          icon: Icons.local_shipping_outlined,
                          text: 'Delivery and site servicing arranged with provider.',
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

      // Sticky Bottom Booking Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161524),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Price per day', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    'R ${widget.unit.pricePerDay.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateBookingScreen(unit: widget.unit),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Book Unit'),
                ),
              ),
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
          color: const Color(0xFF161524),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5D5FEF), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
        Icon(icon, size: 16, color: const Color(0xFF66BB6A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}

