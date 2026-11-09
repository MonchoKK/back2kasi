// ignore_for_file: slash_for_doc_comments

/**
 * Model representing an image attachment for a Rental Unit.
 */
class RentalUnitImage {
  final int id;
  final int rentalUnitId;
  final String imageUrl;
  final String contentType;
  final int fileSize;
  final bool isPrimary;
  final int displayOrder;
  final DateTime? createdAt;

  RentalUnitImage({
    required this.id,
    required this.rentalUnitId,
    required this.imageUrl,
    this.contentType = 'image/jpeg',
    this.fileSize = 0,
    this.isPrimary = false,
    this.displayOrder = 0,
    this.createdAt,
  });

  factory RentalUnitImage.fromJson(Map<String, dynamic> json) {
    return RentalUnitImage(
      id: json['id'] as int,
      rentalUnitId: json['rentalUnitId'] as int,
      imageUrl: json['imageUrl'] as String,
      contentType: json['contentType'] as String? ?? 'image/jpeg',
      fileSize: json['fileSize'] as int? ?? 0,
      isPrimary: json['isPrimary'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rentalUnitId': rentalUnitId,
      'imageUrl': imageUrl,
      'contentType': contentType,
      'fileSize': fileSize,
      'isPrimary': isPrimary,
      'displayOrder': displayOrder,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}

