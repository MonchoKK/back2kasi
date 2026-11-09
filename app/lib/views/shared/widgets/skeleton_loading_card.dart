// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';

/**
 * Reusable pulsing skeleton loading card for marketplace items and inventory cards.
 */
class SkeletonLoadingCard extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SkeletonLoadingCard({
    super.key,
    this.height = 180,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  State<SkeletonLoadingCard> createState() => _SkeletonLoadingCardState();
}

class _SkeletonLoadingCardState extends State<SkeletonLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF161524).withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        );
      },
    );
  }
}

/**
 * Skeleton list simulating a grid or list of marketplace cards during loading.
 */
class MarketplaceSkeletonList extends StatelessWidget {
  final int itemCount;

  const MarketplaceSkeletonList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoadingCard(
                height: 180,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SkeletonLoadingCard(
                    height: 18,
                    width: 140,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const Spacer(),
                  SkeletonLoadingCard(
                    height: 18,
                    width: 80,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SkeletonLoadingCard(
                height: 14,
                width: 200,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        );
      },
    );
  }
}
