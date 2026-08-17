// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/rental_unit.dart';

/**
 * Screen presenting a form to create a new rental unit or modify an existing one.
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
  
  late RentalUnitType _selectedType;
  late RentalUnitStatus _selectedStatus;

  String? _errorMessage;

  bool get isEditMode => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _descController = TextEditingController(text: widget.unit?.description ?? '');
    _priceController = TextEditingController(text: widget.unit?.pricePerDay.toString() ?? '');
    _capacityController = TextEditingController(text: widget.unit?.capacity.toString() ?? '1');
    
    _selectedType = widget.unit?.rentalUnitType ?? RentalUnitType.STANDARD_TOILET;
    _selectedStatus = widget.unit?.status ?? RentalUnitStatus.AVAILABLE;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
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
      final provider = context.read<RentalUnitProvider>();
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final price = double.parse(_priceController.text);
      final cap = int.parse(_capacityController.text);

      if (isEditMode) {
        await provider.updateRentalUnit(
          widget.unit!.id,
          businessId: widget.businessId,
          name: name,
          description: desc,
          pricePerDay: price,
          capacity: cap,
          type: _selectedType,
          status: _selectedStatus,
          token: token,
        );
      } else {
        await provider.createRentalUnit(
          businessId: widget.businessId,
          name: name,
          description: desc,
          pricePerDay: price,
          capacity: cap,
          type: _selectedType,
          token: token,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Rental unit details updated'
                : 'Rental unit registered successfully',
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
    final isLoading = context.watch<RentalUnitProvider>().isLoading;

    // Helper maps to format UI dropdown texts
    final Map<RentalUnitType, String> typeNames = {
      RentalUnitType.STANDARD_TOILET: 'Standard Toilet',
      RentalUnitType.VIP_TOILET: 'VIP Toilet Trailer',
      RentalUnitType.CHEMICAL_TOILET: 'Chemical Toilet',
      RentalUnitType.STANDARD_COLD_ROOM: 'Standard Cold Room',
      RentalUnitType.MOBILE_COLD_ROOM: 'Mobile Cold Room',
    };

    final Map<RentalUnitStatus, String> statusNames = {
      RentalUnitStatus.AVAILABLE: 'Available for Bookings',
      RentalUnitStatus.RENTED: 'Currently Rented out',
      RentalUnitStatus.UNDER_MAINTENANCE: 'Under Maintenance / Deactivated',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Rental Unit' : 'Add Rental Unit'),
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
                  isEditMode ? 'Modify Specifications' : 'List New Inventory Unit',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set the price, unit class type, and occupancy details.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Unit Identifier / Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'e.g. VIP Trailer Unit 1',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Unit name is required' : null,
                ),
                const SizedBox(height: 20),

                // Rental Unit Type Selection
                DropdownButtonFormField<RentalUnitType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Inventory Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: const Color(0xFF161524),
                  items: RentalUnitType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(typeNames[type] ?? 'Unit'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Price Per Day (Rands)
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Day (ZAR)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    hintText: 'e.g. 150.00',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Price per day is required';
                    final price = double.tryParse(val);
                    if (price == null || price <= 0) {
                      return 'Price must be a positive number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Capacity
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Storage Capacity / Occupants',
                    prefixIcon: Icon(Icons.people_outline),
                    hintText: 'e.g. 1',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Capacity is required';
                    final cap = int.tryParse(val);
                    if (cap == null || cap <= 0) {
                      return 'Capacity must be an integer greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Status Dropdown (Only in Edit mode)
                if (isEditMode) ...[
                  DropdownButtonFormField<RentalUnitStatus>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Current Availability Status',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    dropdownColor: const Color(0xFF161524),
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
                  const SizedBox(height: 20),
                ],

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
                      : Text(isEditMode ? 'Save Unit Specifications' : 'Register Unit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
