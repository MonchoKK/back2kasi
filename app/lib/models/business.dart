// ignore_for_file: constant_identifier_names, slash_for_doc_comments
enum BusinessType { TOILET_RENTAL, COLD_ROOM_RENTAL }

/**
 * Client-side model representing a township rental Business profile.
 */
class Business {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String phoneNumber;
  final BusinessType businessType;
  final int ownerId;

  Business({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.phoneNumber,
    required this.businessType,
    required this.ownerId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      phoneNumber: json['phoneNumber'] as String,
      businessType: json['businessType'] == 'COLD_ROOM_RENTAL'
          ? BusinessType.COLD_ROOM_RENTAL
          : BusinessType.TOILET_RENTAL,
      ownerId: json['ownerId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'businessType': businessType.toString().split('.').last,
      'ownerId': ownerId,
    };
  }
}
