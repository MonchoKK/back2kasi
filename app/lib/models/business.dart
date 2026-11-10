// ignore_for_file: constant_identifier_names, slash_for_doc_comments
export 'business_category.dart';
import 'business_category.dart';

enum BusinessType { TOILET_RENTAL, COLD_ROOM_RENTAL }

/**
 * Client-side model representing a township Business profile across all 6 sectors.
 */
class Business {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String phoneNumber;
  final BusinessType businessType;
  final BusinessCategory category;
  final bool isVerified;
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
    this.businessType = BusinessType.TOILET_RENTAL,
    this.category = BusinessCategory.EVENTS_RENTALS,
    this.isVerified = false,
    required this.ownerId,
    this.whatsappNumber,
    this.whatsappEnabled = false,
    this.whatsappMessage,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final catRaw = (json['category'] ?? json['businessType'] ?? json['business_type']) as String?;
    final resolvedCategory = BusinessCategory.fromString(catRaw);

    return Business(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String,
      phoneNumber: (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
      businessType: (json['businessType'] ?? json['business_type']) == 'COLD_ROOM_RENTAL'
          ? BusinessType.COLD_ROOM_RENTAL
          : BusinessType.TOILET_RENTAL,
      category: resolvedCategory,
      isVerified: json['isVerified'] == true || json['is_verified'] == 1,
      ownerId: (json['ownerId'] ?? json['owner_id'] ?? 0) as int,
      whatsappNumber: (json['whatsappNumber'] ?? json['whatsapp_number']) as String?,
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
      'category': category.key,
      'isVerified': isVerified,
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
    BusinessCategory? category,
    bool? isVerified,
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
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      ownerId: ownerId ?? this.ownerId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      whatsappMessage: whatsappMessage ?? this.whatsappMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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
