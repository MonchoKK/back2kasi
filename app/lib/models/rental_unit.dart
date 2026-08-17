// ignore_for_file: constant_identifier_names, slash_for_doc_comments
enum RentalUnitType {
  STANDARD_TOILET,
  VIP_TOILET,
  CHEMICAL_TOILET,
  STANDARD_COLD_ROOM,
  MOBILE_COLD_ROOM,
}

enum RentalUnitStatus {
  AVAILABLE,
  RENTED,
  UNDER_MAINTENANCE,
}

/**
 * Client-side model representing an individual Rental Unit listing.
 */
class RentalUnit {
  final int id;
  final String name;
  final String? description;
  final double pricePerDay;
  final int capacity;
  final RentalUnitType rentalUnitType;
  final RentalUnitStatus status;
  final int businessId;

  RentalUnit({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerDay,
    required this.capacity,
    required this.rentalUnitType,
    required this.status,
    required this.businessId,
  });

  factory RentalUnit.fromJson(Map<String, dynamic> json) {
    return RentalUnit(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      capacity: json['capacity'] as int,
      rentalUnitType: RentalUnitType.values.firstWhere(
        (e) => e.toString().split('.').last == json['rentalUnitType'],
        orElse: () => RentalUnitType.STANDARD_TOILET,
      ),
      status: RentalUnitStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RentalUnitStatus.AVAILABLE,
      ),
      businessId: json['businessId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pricePerDay': pricePerDay,
      'capacity': capacity,
      'rentalUnitType': rentalUnitType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'businessId': businessId,
    };
  }
}
