import 'package:flutter_test/flutter_test.dart';
import 'package:back2kasi_app/models/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('fromJson should correctly map fields from JSON', () {
      final json = {
        'id': 101,
        'startDate': '2026-08-20',
        'endDate': '2026-08-22',
        'totalPrice': 300.00,
        'status': 'PENDING',
        'rentalUnitId': 200,
        'customerId': 5,
        'notes': 'Test notes',
        'createdAt': '2026-08-19T10:00:00Z',
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 101);
      expect(booking.startDate, DateTime(2026, 8, 20));
      expect(booking.endDate, DateTime(2026, 8, 22));
      expect(booking.totalPrice, 300.00);
      expect(booking.status, BookingStatus.PENDING);
      expect(booking.rentalUnitId, 200);
      expect(booking.customerId, 5);
      expect(booking.notes, 'Test notes');
      expect(booking.createdAt, DateTime.parse('2026-08-19T10:00:00Z'));
    });

    test('toJson should correctly format fields into JSON MAP', () {
      final booking = Booking(
        id: 101,
        startDate: DateTime(2026, 8, 20),
        endDate: DateTime(2026, 8, 22),
        totalPrice: 300.00,
        status: BookingStatus.PENDING,
        rentalUnitId: 200,
        customerId: 5,
        notes: 'Test notes',
      );

      final json = booking.toJson();

      expect(json['id'], 101);
      expect(json['startDate'], '2026-08-20');
      expect(json['endDate'], '2026-08-22');
      expect(json['totalPrice'], 300.00);
      expect(json['status'], 'PENDING');
      expect(json['rentalUnitId'], 200);
      expect(json['customerId'], 5);
      expect(json['notes'], 'Test notes');
    });
  });
}
