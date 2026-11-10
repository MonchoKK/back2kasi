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
  final String? whatsappNumber;
  final bool whatsappEnabled;
  final String? whatsappMessage;

  Business({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.phoneNumber,
    required this.businessType,
    required this.ownerId,
    this.whatsappNumber,
    this.whatsappEnabled = false,
    this.whatsappMessage,
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
      whatsappNumber: json['whatsappNumber'] as String?,
      whatsappEnabled: json['whatsappEnabled'] == true || json['whatsapp_enabled'] == 1,
      whatsappMessage: (json['whatsappMessage'] ?? json['whatsapp_message']) as String?,
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
      'whatsappNumber': whatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      'whatsappMessage': whatsappMessage,
    };
  }

  Business copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    BusinessType? businessType,
    int? ownerId,
    String? whatsappNumber,
    bool? whatsappEnabled,
    String? whatsappMessage,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessType: businessType ?? this.businessType,
      ownerId: ownerId ?? this.ownerId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      whatsappMessage: whatsappMessage ?? this.whatsappMessage,
    );
  }
}

/**
 * Public/owner contact information payload.
 */
class BusinessContact {
  final int businessId;
  final String businessName;
  final String phoneNumber;
  final String? whatsappNumber;
  final bool whatsappEnabled;
  final String? whatsappMessage;

  BusinessContact({
    required this.businessId,
    required this.businessName,
    required this.phoneNumber,
    this.whatsappNumber,
    this.whatsappEnabled = false,
    this.whatsappMessage,
  });

  factory BusinessContact.fromJson(Map<String, dynamic> json) {
    return BusinessContact(
      businessId: json['businessId'] as int,
      businessName: json['businessName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      whatsappNumber: json['whatsappNumber'] as String?,
      whatsappEnabled: json['whatsappEnabled'] == true,
      whatsappMessage: json['whatsappMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      'whatsappMessage': whatsappMessage,
    };
  }
}
