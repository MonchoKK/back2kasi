// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../models/rental_unit.dart';
import 'booking_confirmation_screen.dart';

/**
 * Screen for selecting dates and adding notes for a booking.
 *
 * <p>Validates that date ranges are in the future and satisfy duration rules,
 * calculates an estimated price, and transitions to the confirmation view.</p>
 */
class CreateBookingScreen extends StatefulWidget {
  final RentalUnit unit;

  const CreateBookingScreen({super.key, required this.unit});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  DateTimeRange? _selectedRange;
  final TextEditingController _notesController = TextEditingController();

  int get _numberOfDays {
    if (_selectedRange == null) return 0;
    return _selectedRange!.end.difference(_selectedRange!.start).inDays;
  }

  double get _totalPrice {
    return widget.unit.pricePerDay * _numberOfDays;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    // Validate: start date must be tomorrow or later (future dates only)
    final tomorrow = DateTime(now.year, dateMonthTomorrow(now), dateDayTomorrow(now));
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5D5FEF),
              onPrimary: Colors.white,
              surface: Color(0xFF161524),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Validate: end date must be after start date (min 1 day duration)
      if (picked.end.difference(picked.start).inDays < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking duration must be at least 1 day')),
        );
        return;
      }
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  int dateDayTomorrow(DateTime now) {
    return now.add(const Duration(days: 1)).day;
  }

  int dateMonthTomorrow(DateTime now) {
    return now.add(const Duration(days: 1)).month;
  }

  void _reviewBooking() {
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          unit: widget.unit,
          startDate: _selectedRange!.start,
          endDate: _selectedRange!.end,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.unit;
    final String typeLabel = unit.rentalUnitType.toString().split('.').last.replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Rental Unit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unit Summary Card
            Container(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D5FEF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Color(0xFF8C8DFF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    unit.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.description != null && unit.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      unit.description!,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
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

            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Select Rental Dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF161524),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedRange != null
                        ? const Color(0xFF5D5FEF)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF5D5FEF)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _selectedRange == null
                          ? const Text(
                              'Tap to select start & end dates',
                              style: TextStyle(color: Colors.grey),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatDate(_selectedRange!.start)} → ${_formatDate(_selectedRange!.end)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_numberOfDays day${_numberOfDays == 1 ? '' : 's'}',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                ),
                              ],
                            ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes Field
            const Text(
              'Notes (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requirements...',
              ),
            ),

            const SizedBox(height: 32),

            // Price Summary
            if (_selectedRange != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161524),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5D5FEF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Price per day', 'R ${unit.pricePerDay.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Number of days', '$_numberOfDays'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.white10),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R ${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB74D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Review Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _reviewBooking,
                child: const Text('Review Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
