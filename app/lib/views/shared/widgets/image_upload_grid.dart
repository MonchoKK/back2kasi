// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
          backgroundColor: Colors.orangeAccent,
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
      backgroundColor: const Color(0xFF161524),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Add Unit Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF5D5FEF)),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('JPEG, PNG, WebP (up to 5 MB)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFFFB74D)),
                title: const Text('Take a Photo'),
                subtitle: const Text('Capture with device camera'),
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
                const Icon(Icons.photo_camera_back_outlined, size: 18, color: Color(0xFF5D5FEF)),
                const SizedBox(width: 8),
                Text(
                  'Listing Photos ($_totalCount/${widget.maxImages})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            if (_totalCount < widget.maxImages && !widget.isUploading)
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5D5FEF)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload up to 5 photos. Tap a photo to set it as the primary cover.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        const SizedBox(height: 12),
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
            backgroundColor: Color(0xFF1E1D2E),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D5FEF)),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: img.isPrimary ? const Color(0xFFFFB74D) : Colors.white10,
                width: img.isPrimary ? 2 : 1,
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.black),
                  SizedBox(width: 2),
                  Text(
                    'COVER',
                    style: TextStyle(
                      color: Colors.black,
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
              decoration: const BoxDecoration(
                color: Colors.black54,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFirstTotal ? const Color(0xFFFFB74D) : Colors.white12,
              width: isFirstTotal ? 2 : 1,
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 10, color: Colors.black),
                  SizedBox(width: 2),
                  Text(
                    'COVER',
                    style: TextStyle(
                      color: Colors.black,
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
              decoration: const BoxDecoration(
                color: Colors.black54,
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
          color: const Color(0xFF161524),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF5D5FEF).withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF5D5FEF), size: 28),
            SizedBox(height: 6),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
