// ignore_for_file: constant_identifier_names, slash_for_doc_comments
import 'rental_unit_image.dart';

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
  final List<RentalUnitImage> images;
  final String? primaryImageUrl;

  RentalUnit({
    required this.id,
    required this.name,
    this.description,
    required this.pricePerDay,
    required this.capacity,
    required this.rentalUnitType,
    required this.status,
    required this.businessId,
    this.images = const [],
    this.primaryImageUrl,
  });

  String? get displayImageUrl =>
      primaryImageUrl ?? (images.isNotEmpty ? images.first.imageUrl : null);

  factory RentalUnit.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>?;
    final parsedImages = rawImages != null
        ? rawImages
            .map((e) => RentalUnitImage.fromJson(e as Map<String, dynamic>))
            .toList()
        : <RentalUnitImage>[];

    final primaryUrl = json['primaryImageUrl'] as String? ??
        (parsedImages.isNotEmpty
            ? parsedImages
                .firstWhere((img) => img.isPrimary, orElse: () => parsedImages.first)
                .imageUrl
            : null);

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
      images: parsedImages,
      primaryImageUrl: primaryUrl,
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
      'images': images.map((e) => e.toJson()).toList(),
      if (primaryImageUrl != null) 'primaryImageUrl': primaryImageUrl,
    };
  }

  RentalUnit copyWith({
    int? id,
    String? name,
    String? description,
    double? pricePerDay,
    int? capacity,
    RentalUnitType? rentalUnitType,
    RentalUnitStatus? status,
    int? businessId,
    List<RentalUnitImage>? images,
    String? primaryImageUrl,
  }) {
    return RentalUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      capacity: capacity ?? this.capacity,
      rentalUnitType: rentalUnitType ?? this.rentalUnitType,
      status: status ?? this.status,
      businessId: businessId ?? this.businessId,
      images: images ?? this.images,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
    );
  }
}
