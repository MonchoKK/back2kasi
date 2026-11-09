// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';

/**
 * Reusable cached network image widget with graceful fallbacks and loading states.
 */
class CachedImageView extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final double iconSize;

  const CachedImageView({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConfig.resolveImageUrl(imageUrl);

    Widget placeholderContainer([Widget? child]) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1D2E),
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: child ??
            Icon(
              fallbackIcon,
              color: Colors.white24,
              size: iconSize,
            ),
      );
    }

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return placeholderContainer();
    }

    final imageWidget = CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholderContainer(
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
          ),
        ),
      ),
      errorWidget: (context, url, error) => placeholderContainer(
        Icon(
          Icons.broken_image_outlined,
          color: Colors.white24,
          size: iconSize,
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

