// ignore_for_file: constant_identifier_names, slash_for_doc_comments
enum BookingStatus {
  PENDING,
  CONFIRMED,
  COMPLETED,
  CANCELLED,
}

/**
 * Client-side model representing a Booking reservation.
 */
class Booking {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final BookingStatus status;
  final int rentalUnitId;
  final int customerId;

  Booking({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.rentalUnitId,
    required this.customerId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BookingStatus.PENDING,
      ),
      rentalUnitId: json['rentalUnitId'] as int,
      customerId: json['customerId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // API expects ISO-8601 date string format (YYYY-MM-DD)
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate.toIso8601String().substring(0, 10),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'rentalUnitId': rentalUnitId,
      'customerId': customerId,
    };
  }
}
