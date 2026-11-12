// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/rental_unit.dart';
import '../../models/rental_unit_image.dart';
import '../shared/components/bk_components.dart';
import '../shared/widgets/image_upload_grid.dart';

/**
 * Screen presenting a form to create a new rental unit or modify an existing one,
 * with full catalogue photo management (upload, preview, delete, primary selection).
 */
class CreateEditUnitScreen extends StatefulWidget {
  final int businessId;
  final RentalUnit? unit;

  const CreateEditUnitScreen({super.key, required this.businessId, this.unit});

  @override
  State<CreateEditUnitScreen> createState() => _CreateEditUnitScreenState();
}

class _CreateEditUnitScreenState extends State<CreateEditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _priceUnitController;

  late ItemType _selectedItemType;
  late bool _isPriceOnRequest;
  late RentalUnitStatus _selectedStatus;

  List<RentalUnitImage> _remoteImages = [];
  final List<File> _pendingLocalFiles = [];
  bool _isUploadingPhoto = false;

  String? _errorMessage;

  bool get isEditMode => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _descController = TextEditingController(text: widget.unit?.description ?? '');
    _priceController = TextEditingController(
        text: widget.unit?.price != null ? widget.unit!.price.toString() : '');
    _capacityController = TextEditingController(
        text: widget.unit?.capacity != null ? widget.unit!.capacity.toString() : '1');
    _priceUnitController = TextEditingController(text: widget.unit?.priceUnit ?? '');

    _selectedItemType = widget.unit?.itemType ?? ItemType.SERVICE;
    _isPriceOnRequest = widget.unit?.isPriceOnRequest ?? false;
    _selectedStatus = widget.unit?.status ?? RentalUnitStatus.AVAILABLE;

    _remoteImages = List.from(widget.unit?.images ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _priceUnitController.dispose();
    super.dispose();
  }

  Future<void> _handleRemoteImageAdded(File file, bool isPrimary) async {
    final token = context.read<AuthService>().token;
    if (token == null || widget.unit == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<RentalUnitProvider>();
      final newImage = await provider.uploadUnitImage(
        unitId: widget.unit!.id,
        businessId: widget.businessId,
        filePath: file.path,
        token: token,
        isPrimary: isPrimary,
      );

      setState(() {
        if (newImage.isPrimary) {
          _remoteImages = _remoteImages
              .map((img) => RentalUnitImage(
                    id: img.id,
                    rentalUnitId: img.rentalUnitId,
                    imageUrl: img.imageUrl,
                    contentType: img.contentType,
                    fileSize: img.fileSize,
                    isPrimary: false,
                    displayOrder: img.displayOrder,
                    createdAt: img.createdAt,
                  ))
              .toList();
        }
        _remoteImages.add(newImage);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo uploaded successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _handleRemoteSetPrimary(RentalUnitImage image) async {
    final token = context.read<AuthService>().token;
    if (token == null || widget.unit == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _errorMessage = null;
    });

    try {
      await context.read<RentalUnitProvider>().setPrimaryUnitImage(
            unitId: widget.unit!.id,
            imageId: image.id,
            businessId: widget.businessId,
            token: token,
          );

      setState(() {
        _remoteImages = _remoteImages.map((img) {
          final isPrimary = img.id == image.id;
          return RentalUnitImage(
            id: img.id,
            rentalUnitId: img.rentalUnitId,
            imageUrl: img.imageUrl,
            contentType: img.contentType,
            fileSize: img.fileSize,
            isPrimary: isPrimary,
            displayOrder: img.displayOrder,
            createdAt: img.createdAt,
          );
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primary cover photo updated'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _handleRemoteDelete(RentalUnitImage image) async {
    final token = context.read<AuthService>().token;
    if (token == null || widget.unit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploadingPhoto = true;
      _errorMessage = null;
    });

    try {
      await context.read<RentalUnitProvider>().deleteUnitImage(
            unitId: widget.unit!.id,
            imageId: image.id,
            businessId: widget.businessId,
            token: token,
          );

      setState(() {
        _remoteImages.removeWhere((img) => img.id == image.id);
        if (image.isPrimary && _remoteImages.isNotEmpty) {
          _remoteImages[0] = RentalUnitImage(
            id: _remoteImages[0].id,
            rentalUnitId: _remoteImages[0].rentalUnitId,
            imageUrl: _remoteImages[0].imageUrl,
            contentType: _remoteImages[0].contentType,
            fileSize: _remoteImages[0].fileSize,
            isPrimary: true,
            displayOrder: _remoteImages[0].displayOrder,
            createdAt: _remoteImages[0].createdAt,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo deleted'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final token = context.read<AuthService>().token;
    if (token == null) return;

    try {
      final provider = context.read<RentalUnitProvider>();
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price = _isPriceOnRequest ? 0.0 : (double.tryParse(_priceController.text) ?? 0.0);
      final priceUnit = _isPriceOnRequest || _priceUnitController.text.trim().isEmpty
          ? null
          : _priceUnitController.text.trim();
      final cap = int.tryParse(_capacityController.text) ?? 1;

      if (isEditMode) {
        await provider.updateRentalUnit(
          widget.unit!.id,
          businessId: widget.businessId,
          name: name,
          description: desc,
          pricePerDay: price,
          price: price,
          isPriceOnRequest: _isPriceOnRequest,
          priceUnit: priceUnit,
          itemType: _selectedItemType,
          capacity: cap,
          type: _selectedItemType == ItemType.PRODUCT
              ? RentalUnitType.GENERAL_PRODUCT
              : RentalUnitType.GENERAL_SERVICE,
          status: _selectedStatus,
          token: token,
        );
      } else {
        await provider.createRentalUnit(
          businessId: widget.businessId,
          name: name,
          description: desc,
          pricePerDay: price,
          price: price,
          isPriceOnRequest: _isPriceOnRequest,
          priceUnit: priceUnit,
          itemType: _selectedItemType,
          capacity: cap,
          type: _selectedItemType == ItemType.PRODUCT
              ? RentalUnitType.GENERAL_PRODUCT
              : RentalUnitType.GENERAL_SERVICE,
          token: token,
        );

        // Upload any pending photos selected during creation
        if (_pendingLocalFiles.isNotEmpty) {
          final units = provider.getUnitsForBusiness(widget.businessId);
          if (units.isNotEmpty) {
            final newlyCreated = units.last;
            for (var i = 0; i < _pendingLocalFiles.length; i++) {
              final file = _pendingLocalFiles[i];
              try {
                await provider.uploadUnitImage(
                  unitId: newlyCreated.id,
                  businessId: widget.businessId,
                  filePath: file.path,
                  token: token,
                  isPrimary: i == 0,
                );
              } catch (_) {
                // Keep moving for other photos
              }
            }
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Catalogue offering updated successfully'
                : 'Catalogue offering created successfully',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<RentalUnitProvider>().isLoading;

    final Map<RentalUnitStatus, String> statusNames = {
      RentalUnitStatus.AVAILABLE: 'Available (Active)',
      RentalUnitStatus.RENTED: 'Unavailable (Out of Stock)',
      RentalUnitStatus.UNDER_MAINTENANCE: 'Paused / Deactivated',
    };

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: isEditMode ? 'Edit Catalogue Item' : 'Add Catalogue Item',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photos Management Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ImageUploadGrid(
                        remoteImages: _remoteImages,
                        localPendingFiles: _pendingLocalFiles,
                        isUploading: _isUploadingPhoto,
                        onLocalImageAdded: (file, isPrimary) {
                          if (isEditMode) {
                            _handleRemoteImageAdded(file, isPrimary);
                          } else {
                            setState(() {
                              _pendingLocalFiles.add(file);
                            });
                          }
                        },
                        onLocalImageRemoved: (index) {
                          setState(() {
                            _pendingLocalFiles.removeAt(index);
                          });
                        },
                        onRemoteDelete: _handleRemoteDelete,
                        onRemoteSetPrimary: _handleRemoteSetPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),

                    // Specifications Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            isEditMode ? 'Modify Catalogue Offering' : 'Add Product or Service',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Classify as a product or service, set pricing, and details.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // Classification Selection (Product vs Service)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catalogue Classification',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      selected: _selectedItemType == ItemType.SERVICE,
                                      showCheckmark: false,
                                      avatar: Icon(
                                        Icons.handyman_outlined,
                                        size: 16,
                                        color: _selectedItemType == ItemType.SERVICE
                                            ? AppTheme.white
                                            : AppTheme.textSecondaryColor,
                                      ),
                                      label: const Text('Service Offering'),
                                      labelStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedItemType == ItemType.SERVICE
                                            ? AppTheme.white
                                            : AppTheme.textSecondaryColor,
                                      ),
                                      backgroundColor: AppTheme.surfaceColor,
                                      selectedColor: AppTheme.brandColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                        side: BorderSide(
                                          color: _selectedItemType == ItemType.SERVICE
                                              ? AppTheme.brandColor
                                              : AppTheme.borderColor,
                                        ),
                                      ),
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedItemType = ItemType.SERVICE;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ChoiceChip(
                                      selected: _selectedItemType == ItemType.PRODUCT,
                                      showCheckmark: false,
                                      avatar: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 16,
                                        color: _selectedItemType == ItemType.PRODUCT
                                            ? AppTheme.white
                                            : AppTheme.textSecondaryColor,
                                      ),
                                      label: const Text('Physical Product'),
                                      labelStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedItemType == ItemType.PRODUCT
                                            ? AppTheme.white
                                            : AppTheme.textSecondaryColor,
                                      ),
                                      backgroundColor: AppTheme.surfaceColor,
                                      selectedColor: AppTheme.brandColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                        side: BorderSide(
                                          color: _selectedItemType == ItemType.PRODUCT
                                              ? AppTheme.brandColor
                                              : AppTheme.borderColor,
                                        ),
                                      ),
                                      onSelected: (val) {
                                        setState(() {
                                          _selectedItemType = ItemType.PRODUCT;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Name
                          BkTextField(
                            controller: _nameController,
                            label: 'Title / Item Name',
                            hintText: _selectedItemType == ItemType.SERVICE
                                ? 'e.g. Fade Haircut, Plumbing Callout, Catering Setup'
                                : 'e.g. Wedding Cake, Sneakers, VIP Portable Toilet',
                            prefixIcon: _selectedItemType == ItemType.SERVICE
                                ? Icons.handyman_outlined
                                : Icons.shopping_bag_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Item name is required' : null,
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Pricing Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isPriceOnRequest = !_isPriceOnRequest;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Price on Request / Custom Quote',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimaryColor,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Customer will discuss pricing on WhatsApp',
                                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Switch.adaptive(
                                          value: _isPriceOnRequest,
                                          activeColor: AppTheme.brandColor,
                                          onChanged: (val) {
                                            setState(() {
                                              _isPriceOnRequest = val;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!_isPriceOnRequest) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: AppTheme.borderColor),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: BkTextField(
                                          controller: _priceController,
                                          label: 'Price (ZAR)',
                                          hintText: 'e.g. 150.00',
                                          prefixIcon: Icons.payments_outlined,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textInputAction: TextInputAction.next,
                                          validator: (val) {
                                            if (_isPriceOnRequest) return null;
                                            if (val == null || val.trim().isEmpty) {
                                              return 'Required';
                                            }
                                            final price = double.tryParse(val);
                                            if (price == null || price <= 0) {
                                              return 'Invalid price';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.space12),
                                      Expanded(
                                        flex: 2,
                                        child: BkTextField(
                                          controller: _priceUnitController,
                                          label: 'Unit (Optional)',
                                          hintText: 'e.g. per day, each',
                                          prefixIcon: Icons.straighten_outlined,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Description
                          BkTextField(
                            controller: _descController,
                            label: 'Description (Optional)',
                            hintText: 'Describe turnaround times, package details, materials, or special offers...',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _save(),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Status Dropdown (Only in Edit mode)
                          if (isEditMode) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Availability Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space8),
                                DropdownButtonFormField<RentalUnitStatus>(
                                  value: _selectedStatus,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.info_outline,
                                      color: AppTheme.textSecondaryColor,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      borderSide: const BorderSide(color: AppTheme.borderColor, width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
                                    ),
                                  ),
                                  dropdownColor: AppTheme.surfaceColor,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                  items: RentalUnitStatus.values.map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Text(statusNames[status] ?? 'Status'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedStatus = val;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(AppTheme.space12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: AppTheme.errorColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                          ],

                          // Save Action Button
                          BkPrimaryButton(
                            label: isEditMode ? 'Save Catalogue Item' : 'Add to Catalogue',
                            isLoading: isLoading || _isUploadingPhoto,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
