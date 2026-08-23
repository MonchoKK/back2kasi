// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/rental_unit_provider.dart';
import '../../models/business.dart';
import '../../models/rental_unit.dart';
import '../booking/create_booking_screen.dart';

/**
 * Screen presenting details of a selected business and its available rental units
 * from a customer perspective.
 *
 * <p>Retrieves rental units via {@link RentalUnitProvider} and lets the customer
 * book them.</p>
 */
class CustomerBusinessDetailScreen extends StatefulWidget {
  final Business business;

  const CustomerBusinessDetailScreen({super.key, required this.business});

  @override
  State<CustomerBusinessDetailScreen> createState() => _CustomerBusinessDetailScreenState();
}

class _CustomerBusinessDetailScreenState extends State<CustomerBusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnits();
    });
  }

  void _loadUnits() {
    context.read<RentalUnitProvider>().fetchUnitsForBusiness(widget.business.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalUnitProvider>();
    final units = provider.getUnitsForBusiness(widget.business.id);
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    // Customers only browse AVAILABLE units for booking
    final availableUnits = units.where((u) => u.status == RentalUnitStatus.AVAILABLE).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.business.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Profile Header Card
          _buildBusinessHeaderCard(),

          // Error banner
          if (errorMessage != null && availableUnits.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.redAccent.withOpacity(0.1),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Available Inventory',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Expanded(
            child: isLoading && availableUnits.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _loadUnits(),
                    child: availableUnits.isEmpty
                        ? _buildEmptyState(errorMessage)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: availableUnits.length,
                            itemBuilder: (context, index) {
                              final unit = availableUnits[index];
                              return _buildUnitCard(unit);
                            },
                          ),
                  ),
          ),
        ],
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                widget.business.phoneNumber,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? errorMessage) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              errorMessage != null ? Icons.wifi_off : Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage != null ? 'Unable to load inventory' : 'No units available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'All units from this provider are currently booked or offline.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(RentalUnit unit) {
    final String typeLabel = unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(color: Color(0xFF81C784), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              unit.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (unit.description != null && unit.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                unit.description!,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateBookingScreen(unit: unit),
                    ),
                  );
                },
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
