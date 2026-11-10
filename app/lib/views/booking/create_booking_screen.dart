// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/rental_unit.dart';
import '../shared/components/bk_components.dart';
import 'booking_confirmation_screen.dart';

/**
 * Screen for selecting dates and adding notes for a booking.
 *
 * <p>Emerald Light Marketplace design:
 * - Interactive date range picker with Emerald brand highlights
 * - Live rental duration and cost calculation
 * - Clean input field for special delivery instructions.</p>
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
    return _selectedRange!.end.difference(_selectedRange!.start).inDays + 1;
  }

  double get _totalPrice {
    return widget.unit.pricePerDay * _numberOfDays;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
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
              primary: AppTheme.brandColor,
              onPrimary: AppTheme.darkColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked.end.isBefore(picked.start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid date range selection')),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: const BkAppBar(
        title: 'Book Rental Unit',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unit Summary Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.brandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: AppTheme.brandColor,
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
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (unit.description != null && unit.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      unit.description!,
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Capacity: ${unit.capacity} units',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                      const Spacer(),
                      BkPriceDisplay(
                        pricePerDay: unit.pricePerDay,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space24),

            // Date Selection
            const Text(
              'Select Rental Dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: _selectedRange != null ? AppTheme.brandColor : AppTheme.borderColor,
                    width: _selectedRange != null ? 1.5 : 1.0,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(Icons.calendar_today, color: AppTheme.brandColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRange == null ? 'Choose start & end dates' : 'Selected Duration',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedRange == null
                                ? 'Tap to choose dates'
                                : '${_formatDate(_selectedRange!.start)} → ${_formatDate(_selectedRange!.end)}',
                            style: TextStyle(
                              color: _selectedRange == null ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                  ],
                ),
              ),
            ),

            // Estimated Price Calculation
            if (_selectedRange != null) ...[
              const SizedBox(height: AppTheme.space20),
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R ${unit.pricePerDay.toStringAsFixed(2)} × $_numberOfDays days',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                        Text(
                          'R ${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimated Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
                        ),
                        Text(
                          'R ${_totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.space24),

            // Additional Notes / Delivery Instructions
            BkTextField(
              controller: _notesController,
              label: 'Delivery Notes / Special Instructions (Optional)',
              hintText: 'e.g. Please position unit near the rear marquee entrance...',
              maxLines: 3,
            ),

            const SizedBox(height: AppTheme.space32),

            // Review CTA Button
            BkPrimaryButton(
              label: 'Review Booking Request',
              icon: Icons.check_circle_outline,
              onPressed: _reviewBooking,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
