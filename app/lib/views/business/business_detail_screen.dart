// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../rental_unit/create_edit_unit_screen.dart';
import '../shared/widgets/cached_image_view.dart';

/**
 * Screen displaying details of a specific business profile and listing its
 * registered rental units (toilets, cold rooms).
 */
class BusinessDetailScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  RentalUnitStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<RentalUnitProvider>().fetchUnitsForBusiness(widget.business.id);
  }

  Future<void> _toggleUnitStatus(RentalUnit unit) async {
    final token = context.read<AuthService>().token;
    if (token == null) return;

    final newStatus = unit.status == RentalUnitStatus.AVAILABLE
        ? RentalUnitStatus.UNDER_MAINTENANCE
        : RentalUnitStatus.AVAILABLE;

    try {
      await context.read<RentalUnitProvider>().updateRentalUnit(
            unit.id,
            businessId: widget.business.id,
            name: unit.name,
            description: unit.description,
            pricePerDay: unit.pricePerDay,
            capacity: unit.capacity,
            type: unit.rentalUnitType,
            status: newStatus,
            token: token,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == RentalUnitStatus.AVAILABLE
                ? 'Unit marked as Available'
                : 'Unit moved to Maintenance',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteUnit(RentalUnit unit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Are you sure you want to permanently delete "${unit.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token != null) {
        try {
          await context.read<RentalUnitProvider>().deleteRentalUnit(unit.id, widget.business.id, token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rental unit deleted successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(String label, RentalUnitStatus? status) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
      ),
      backgroundColor: const Color(0xFF161524),
      selectedColor: const Color(0xFF5D5FEF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5D5FEF) : Colors.white.withOpacity(0.06),
        ),
      ),
      onSelected: (val) {
        setState(() {
          _statusFilter = status;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalUnitProvider>();
    final units = provider.getUnitsForBusiness(widget.business.id);
    final filteredUnits = _statusFilter == null
        ? units
        : units.where((u) => u.status == _statusFilter).toList();
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Meta Header Card
          _buildBusinessHeaderCard(),

          // Error message banner
          if (errorMessage != null && units.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.redAccent.withOpacity(0.1),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rental Units Inventory',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${filteredUnits.length} of ${units.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          if (units.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${units.length})', null),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Available (${units.where((u) => u.status == RentalUnitStatus.AVAILABLE).length})',
                      RentalUnitStatus.AVAILABLE,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Rented (${units.where((u) => u.status == RentalUnitStatus.RENTED).length})',
                      RentalUnitStatus.RENTED,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Maintenance (${units.where((u) => u.status == RentalUnitStatus.UNDER_MAINTENANCE).length})',
                      RentalUnitStatus.UNDER_MAINTENANCE,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: isLoading && units.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadData(),
                    child: filteredUnits.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredUnits.length,
                            itemBuilder: (context, index) {
                              final item = filteredUnits[index];
                              return _buildUnitCard(item);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D5FEF),
        foregroundColor: Colors.white,
        tooltip: 'Add Rental Unit',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEditUnitScreen(businessId: widget.business.id),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBusinessHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161524),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF5D5FEF), size: 24),
              const SizedBox(width: 8),
              Text(
                widget.business.businessType == BusinessType.TOILET_RENTAL
                    ? 'Toilet Rental Agency'
                    : 'Cold Storage Provider',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.business.description != null && widget.business.description!.isNotEmpty)
            Text(
              widget.business.description!,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.business.address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.wc_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No units listed yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add standard toilets, VIP trailers, or cold rooms to display them to customers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditUnitScreen(businessId: widget.business.id),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Rental Unit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(RentalUnit unit) {
    // Determine status badge color
    Color badgeColor;
    Color textColor;
    String statusLabel;

    switch (unit.status) {
      case RentalUnitStatus.AVAILABLE:
        badgeColor = const Color(0xFF66BB6A).withOpacity(0.15);
        textColor = const Color(0xFF81C784);
        statusLabel = 'Available';
        break;
      case RentalUnitStatus.RENTED:
        badgeColor = const Color(0xFF5D5FEF).withOpacity(0.15);
        textColor = const Color(0xFF8C8DFF);
        statusLabel = 'Rented';
        break;
      case RentalUnitStatus.UNDER_MAINTENANCE:
        badgeColor = const Color(0xFFEF5350).withOpacity(0.15);
        textColor = const Color(0xFFE57373);
        statusLabel = 'Maintenance';
        break;
    }

    final String typeLabel = unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEditUnitScreen(
                businessId: widget.business.id,
                unit: unit,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    typeLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  // Photo Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          unit.images.isEmpty ? Icons.no_photography_outlined : Icons.photo_library_outlined,
                          size: 13,
                          color: unit.images.isEmpty ? Colors.grey : const Color(0xFF8C8DFF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${unit.images.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: unit.images.isEmpty ? Colors.grey : const Color(0xFF8C8DFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Unit Options Dropdown
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEditUnitScreen(
                              businessId: widget.business.id,
                              unit: unit,
                            ),
                          ),
                        );
                      } else if (value == 'toggle_status') {
                        _toggleUnitStatus(unit);
                      } else if (value == 'delete') {
                        _deleteUnit(unit);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit / Photos'),
                          ],
                        ),
                      ),
                      if (unit.status != RentalUnitStatus.RENTED)
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                unit.status == RentalUnitStatus.AVAILABLE
                                    ? Icons.build_outlined
                                    : Icons.check_circle_outline,
                                size: 20,
                                color: const Color(0xFFFFB74D),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                unit.status == RentalUnitStatus.AVAILABLE
                                    ? 'Set Maintenance'
                                    : 'Set Available',
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Thumbnail
                  CachedImageView(
                    imageUrl: unit.displayImageUrl,
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: unit.rentalUnitType == RentalUnitType.STANDARD_COLD_ROOM ||
                            unit.rentalUnitType == RentalUnitType.MOBILE_COLD_ROOM
                        ? Icons.ac_unit
                        : Icons.wc,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unit.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (unit.description != null && unit.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            unit.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Capacity: ${unit.capacity}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    'R ${unit.pricePerDay.toStringAsFixed(2)} / day',
                    style: const TextStyle(
                      color: Color(0xFFFFB74D),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
