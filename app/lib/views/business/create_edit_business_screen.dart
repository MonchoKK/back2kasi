// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../core/contact_helper.dart';
import '../../models/business.dart';
import '../shared/components/bk_components.dart';

/**
 * Form enabling users to register a new Business profile or modify an existing one.
 *
 * <p>Uses the {@link BusinessProvider} to post changes to the REST API, and
 * enforces identical input formatting rules as the backend (e.g. SA phone patterns).</p>
 */
class CreateEditBusinessScreen extends StatefulWidget {
  final Business? business;

  const CreateEditBusinessScreen({super.key, this.business});

  @override
  State<CreateEditBusinessScreen> createState() => _CreateEditBusinessScreenState();
}

class _CreateEditBusinessScreenState extends State<CreateEditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _whatsappMessageController;
  late bool _whatsappEnabled;
  late BusinessCategory _selectedCategory;

  String? _errorMessage;

  bool get isEditMode => widget.business != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business?.name ?? '');
    _descController = TextEditingController(text: widget.business?.description ?? '');
    _addressController = TextEditingController(text: widget.business?.address ?? '');
    _phoneController = TextEditingController(text: widget.business?.phoneNumber ?? '');
    _whatsappController = TextEditingController(
      text: widget.business?.whatsappNumber ?? widget.business?.phoneNumber ?? '',
    );
    _whatsappMessageController = TextEditingController(
      text: widget.business?.whatsappMessage ?? '',
    );
    _whatsappEnabled = widget.business?.whatsappEnabled ?? false;
    _selectedCategory = widget.business?.category ?? BusinessCategory.EVENTS_RENTALS;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _whatsappMessageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final token = context.read<AuthService>().token;
    if (token == null) return;

    final whatsappNum = _whatsappEnabled && _whatsappController.text.trim().isNotEmpty
        ? _whatsappController.text.trim()
        : null;
    final welcomeMsg = _whatsappEnabled && _whatsappMessageController.text.trim().isNotEmpty
        ? _whatsappMessageController.text.trim()
        : null;

    try {
      final provider = context.read<BusinessProvider>();
      if (isEditMode) {
        await provider.updateBusiness(
          widget.business!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          category: _selectedCategory,
          whatsappNumber: whatsappNum,
          whatsappEnabled: _whatsappEnabled,
          whatsappMessage: welcomeMsg,
          token: token,
        );
      } else {
        await provider.createBusiness(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          category: _selectedCategory,
          whatsappNumber: whatsappNum,
          whatsappEnabled: _whatsappEnabled,
          whatsappMessage: welcomeMsg,
          token: token,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Business profile updated successfully'
                : 'Business registered successfully',
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
    final isLoading = context.watch<BusinessProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: isEditMode ? 'Edit Business' : 'Register Business',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppTheme.primaryColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditMode ? 'Update Business Profile' : 'Business Listing Details',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkTextColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'This profile is presented to customers discovering your rental fleet.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),

                    // Inputs Card
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
                          // Business Name
                          BkTextField(
                            controller: _nameController,
                            label: 'Business Name',
                            hintText: 'e.g. Soshanguve Sanitation Solutions',
                            prefixIcon: Icons.storefront,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Business name is required';
                              if (val.trim().length < 2) return 'Name must be at least 2 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Business Category Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              DropdownButtonFormField<BusinessCategory>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.category_outlined,
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
                                items: BusinessCategory.values.map((cat) {
                                  return DropdownMenuItem<BusinessCategory>(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(cat.displayName),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCategory = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Phone Number (10-digit SA local format)
                          BkTextField(
                            controller: _phoneController,
                            label: 'Business Phone Number',
                            hintText: '0764321245',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Phone number is required';
                              if (!ContactHelper.isValidSaLocalPhone(val.trim())) {
                                return 'Enter a valid 10-digit SA number (e.g. 0764321245)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Operational Address
                          BkTextField(
                            controller: _addressController,
                            label: 'Operational Address / Location',
                            hintText: 'e.g. Block BB, Soshanguve',
                            prefixIcon: Icons.location_on_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'Address is required' : null,
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Description
                          BkTextField(
                            controller: _descController,
                            label: 'Description (Optional)',
                            hintText: 'Describe your service offerings, delivery radius, and background...',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _save(),
                          ),
                          const SizedBox(height: AppTheme.space20),

                          // WhatsApp Integration Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: _whatsappEnabled
                                    ? AppTheme.primaryColor.withOpacity(0.5)
                                    : AppTheme.borderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'WhatsApp Direct Contact',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.darkTextColor,
                                            ),
                                          ),
                                          Text(
                                            'Allow customers to enquire via Click-to-Chat',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppTheme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _whatsappEnabled,
                                      activeColor: AppTheme.primaryColor,
                                      onChanged: (val) {
                                        setState(() {
                                          _whatsappEnabled = val;
                                          if (val && _whatsappController.text.trim().isEmpty) {
                                            _whatsappController.text = _phoneController.text.trim();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_whatsappEnabled) ...[
                                  const SizedBox(height: AppTheme.space16),
                                  const Divider(color: AppTheme.borderColor),
                                  const SizedBox(height: AppTheme.space12),

                                  // Autofill shortcut button
                                  if (_phoneController.text.trim().isNotEmpty &&
                                      _whatsappController.text.trim() != _phoneController.text.trim())
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _whatsappController.text = _phoneController.text.trim();
                                          });
                                        },
                                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryColor),
                                        label: const Text(
                                          'Use Business Phone Number',
                                          style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    ),

                                  // WhatsApp Phone Field (10-digit SA local format)
                                  BkTextField(
                                    controller: _whatsappController,
                                    label: 'WhatsApp Phone Number',
                                    hintText: '0764321245',
                                    prefixIcon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    validator: (val) {
                                      if (!_whatsappEnabled) return null;
                                      if (val == null || val.trim().isEmpty) {
                                        return 'WhatsApp number is required when enabled';
                                      }
                                      if (!ContactHelper.isValidSaLocalPhone(val.trim())) {
                                        return 'Enter a valid 10-digit SA number (e.g. 0764321245)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.space12),

                                  // Custom Welcome Message
                                  BkTextField(
                                    controller: _whatsappMessageController,
                                    label: 'Custom Greeting Message (Optional)',
                                    hintText: 'e.g. Hi! Thanks for contacting us on Back2Kasi. How can we help?',
                                    prefixIcon: Icons.message_outlined,
                                    maxLines: 2,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // Error Message Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(color: AppTheme.errorColor.withOpacity(0.25)),
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
                            label: isEditMode ? 'Save Changes' : 'Register Profile',
                            isLoading: isLoading,
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
