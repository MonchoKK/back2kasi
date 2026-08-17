// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';

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
  late BusinessType _selectedType;

  String? _errorMessage;

  bool get isEditMode => widget.business != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business?.name ?? '');
    _descController = TextEditingController(text: widget.business?.description ?? '');
    _addressController = TextEditingController(text: widget.business?.address ?? '');
    _phoneController = TextEditingController(text: widget.business?.phoneNumber ?? '');
    _selectedType = widget.business?.businessType ?? BusinessType.TOILET_RENTAL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final token = context.read<AuthService>().token;
    if (token == null) return;

    try {
      final provider = context.read<BusinessProvider>();
      if (isEditMode) {
        await provider.updateBusiness(
          widget.business!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          type: _selectedType,
          token: token,
        );
      } else {
        await provider.createBusiness(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          type: _selectedType,
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
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Business' : 'Register Business'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditMode ? 'Update Profile' : 'Business Listing Info',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This information is visible to clients when viewing your items.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    prefixIcon: Icon(Icons.storefront),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Business name is required';
                    if (val.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Business Type Dropdown
                DropdownButtonFormField<BusinessType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Business Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: const Color(0xFF161524),
                  items: const [
                    DropdownMenuItem(
                      value: BusinessType.TOILET_RENTAL,
                      child: Text('Toilet Hire Services'),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.COLD_ROOM_RENTAL,
                      child: Text('Cold Storage Services'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Phone (+27 Format)
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+27712345678',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Phone number is required';
                    if (!RegExp(r'^\+27[0-9]{9}$').hasMatch(val.trim())) {
                      return 'Enter SA format: +27 followed by 9 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Address
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Operational Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Save Button
                ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(isEditMode ? 'Save Changes' : 'Register Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
