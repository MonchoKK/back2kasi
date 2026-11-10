// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../config/api_config.dart';
import '../../../config/app_theme.dart';

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
          color: const Color(0xFFEFECE3),
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: child ??
            Icon(
              fallbackIcon,
              color: const Color(0xFF9E9B90),
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
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => placeholderContainer(
        Icon(
          Icons.broken_image_outlined,
          color: const Color(0xFF94A3B8),
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

