// ignore_for_file: constant_identifier_names, slash_for_doc_comments
import 'rental_unit_image.dart';

enum ItemType {
  PRODUCT,
  SERVICE,
}

enum RentalUnitType {
  STANDARD_TOILET,
  VIP_TOILET,
  CHEMICAL_TOILET,
  STANDARD_COLD_ROOM,
  MOBILE_COLD_ROOM,
  GENERAL_PRODUCT,
  GENERAL_SERVICE,
}

enum RentalUnitStatus {
  AVAILABLE,
  RENTED,
  UNDER_MAINTENANCE,
}

/**
 * Universal Catalogue Item model representing a product or service offered by a township business.
 * (Forward and backward compatible alias of RentalUnit).
 */
class RentalUnit {
  final int id;
  final String name;
  final String? description;
  final double pricePerDay;
  final double? price;
  final bool isPriceOnRequest;
  final String? priceUnit;
  final ItemType itemType;
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
    double? price,
    this.isPriceOnRequest = false,
    this.priceUnit,
    this.itemType = ItemType.SERVICE,
    this.capacity = 1,
    this.rentalUnitType = RentalUnitType.STANDARD_TOILET,
    required this.status,
    required this.businessId,
    this.images = const [],
    this.primaryImageUrl,
  }) : price = price ?? pricePerDay;

  bool get isProduct => itemType == ItemType.PRODUCT;
  bool get isService => itemType == ItemType.SERVICE;

  String get formattedPrice {
    if (isPriceOnRequest) return 'Price on Request';
    final effectivePrice = price ?? pricePerDay;
    final formattedNum = effectivePrice % 1 == 0
        ? effectivePrice.toInt().toString()
        : effectivePrice.toStringAsFixed(2);
    if (priceUnit != null && priceUnit!.trim().isNotEmpty) {
      return 'R $formattedNum / ${priceUnit!.trim()}';
    }
    return 'R $formattedNum';
  }

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

    final rawPrice = (json['price'] ?? json['pricePerDay'] ?? 0) as num;
    final isPoa = json['isPriceOnRequest'] == true || json['is_price_on_request'] == 1;
    final rawType = (json['itemType'] ?? json['item_type']) as String?;
    final resolvedItemType = rawType == 'PRODUCT' ? ItemType.PRODUCT : ItemType.SERVICE;

    return RentalUnit(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      pricePerDay: rawPrice.toDouble(),
      price: rawPrice.toDouble(),
      isPriceOnRequest: isPoa,
      priceUnit: (json['priceUnit'] ?? json['price_unit']) as String?,
      itemType: resolvedItemType,
      capacity: (json['capacity'] as int?) ?? 1,
      rentalUnitType: RentalUnitType.values.firstWhere(
        (e) => e.toString().split('.').last == json['rentalUnitType'],
        orElse: () => resolvedItemType == ItemType.PRODUCT
            ? RentalUnitType.GENERAL_PRODUCT
            : RentalUnitType.STANDARD_TOILET,
      ),
      status: RentalUnitStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RentalUnitStatus.AVAILABLE,
      ),
      businessId: (json['businessId'] ?? json['business_id'] ?? 0) as int,
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
      'price': price ?? pricePerDay,
      'isPriceOnRequest': isPriceOnRequest,
      'priceUnit': priceUnit,
      'itemType': itemType.toString().split('.').last,
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
    double? price,
    bool? isPriceOnRequest,
    String? priceUnit,
    ItemType? itemType,
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
      price: price ?? this.price,
      isPriceOnRequest: isPriceOnRequest ?? this.isPriceOnRequest,
      priceUnit: priceUnit ?? this.priceUnit,
      itemType: itemType ?? this.itemType,
      capacity: capacity ?? this.capacity,
      rentalUnitType: rentalUnitType ?? this.rentalUnitType,
      status: status ?? this.status,
      businessId: businessId ?? this.businessId,
      images: images ?? this.images,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
    );
  }
}

/**
 * Type alias enabling generic naming across screens.
 */
typedef CatalogueItem = RentalUnit;

