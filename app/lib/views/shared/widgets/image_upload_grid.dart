// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_theme.dart';
import '../../../models/rental_unit_image.dart';
import 'cached_image_view.dart';

/**
 * Interactive 5-slot photo upload grid for Rental Units.
 *
 * Enforces product rules:
 * - Max 5 photos per unit
 * - Max 5 MB per photo
 * - JPEG, PNG, WebP
 * - Select / toggle primary photo
 * - Delete and preview photos
 */
class ImageUploadGrid extends StatefulWidget {
  final List<RentalUnitImage> remoteImages;
  final List<File> localPendingFiles;
  final int maxImages;
  final bool isUploading;
  final Function(File file, bool isPrimary)? onLocalImageAdded;
  final Function(int index)? onLocalImageRemoved;
  final Function(RentalUnitImage image)? onRemoteDelete;
  final Function(RentalUnitImage image)? onRemoteSetPrimary;

  const ImageUploadGrid({
    super.key,
    this.remoteImages = const [],
    this.localPendingFiles = const [],
    this.maxImages = 5,
    this.isUploading = false,
    this.onLocalImageAdded,
    this.onLocalImageRemoved,
    this.onRemoteDelete,
    this.onRemoteSetPrimary,
  });

  @override
  State<ImageUploadGrid> createState() => _ImageUploadGridState();
}

class _ImageUploadGridState extends State<ImageUploadGrid> {
  final ImagePicker _picker = ImagePicker();

  int get _totalCount =>
      widget.remoteImages.length + widget.localPendingFiles.length;

  Future<void> _pickImage(ImageSource source) async {
    if (_totalCount >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum of ${widget.maxImages} photos reached'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final sizeInBytes = await file.length();
      const maxBytes = 5 * 1024 * 1024; // 5 MB

      if (sizeInBytes > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo exceeds maximum 5 MB limit. Please select a smaller photo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final isFirst = _totalCount == 0;
      widget.onLocalImageAdded?.call(file, isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Unit Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkTextColor)),
                subtitle: const Text('JPEG, PNG, WebP (up to 5 MB)', style: TextStyle(color: AppTheme.secondaryTextColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.accentColor),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkTextColor)),
                subtitle: const Text('Capture with device camera', style: TextStyle(color: AppTheme.secondaryTextColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera_back_outlined, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Listing Photos ($_totalCount/${widget.maxImages})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkTextColor,
                  ),
                ),
              ],
            ),
            if (_totalCount < widget.maxImages && !widget.isUploading)
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload up to 5 photos. Tap a photo to set it as the primary cover.',
          style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _totalCount + (_totalCount < widget.maxImages ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              // Remote images first
              if (index < widget.remoteImages.length) {
                final img = widget.remoteImages[index];
                return _buildRemoteSlot(img);
              }

              // Then pending local files
              final localIndex = index - widget.remoteImages.length;
              if (localIndex < widget.localPendingFiles.length) {
                final file = widget.localPendingFiles[localIndex];
                return _buildLocalSlot(file, localIndex);
              }

              // Add slot button
              return _buildAddButton();
            },
          ),
        ),
        if (widget.isUploading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ],
    );
  }

  Widget _buildRemoteSlot(RentalUnitImage img) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (!img.isPrimary) {
              widget.onRemoteSetPrimary?.call(img);
            }
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: img.isPrimary ? AppTheme.accentColor : AppTheme.borderColor,
                width: img.isPrimary ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedImageView(
                imageUrl: img.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Primary Badge
        if (img.isPrimary)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'COVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onRemoteDelete?.call(img),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalSlot(File file, int localIndex) {
    final isFirstTotal = localIndex == 0 && widget.remoteImages.isEmpty;

    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFirstTotal ? AppTheme.accentColor : AppTheme.borderColor,
              width: isFirstTotal ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(
              file,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),

        if (isFirstTotal)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'COVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Remove local
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onLocalImageRemoved?.call(localIndex),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.35),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor, size: 28),
            SizedBox(height: 6),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
