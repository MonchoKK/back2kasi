// ignore_for_file: slash_for_doc_comments

/**
 * Model representing authorized contact information for an ACCEPTED / CONFIRMED booking.
 *
 * In accordance with Back2Kasi booking-gated security rules:
 * - South African numbers are presented in local format (e.g. 0764321245) for display and phone calls (tel:).
 * - WhatsApp international numbers (e.g. 27764321245) are used for Click-to-Chat (wa.me).
 * - Contact information is only unlocked when booking status is CONFIRMED / ACCEPTED.
 */
class BookingContact {
  final int bookingId;
  final String bookingStatus;
  final String role; // 'BUSINESS' or 'CUSTOMER'
  final String contactName;
  final String phoneNumber; // 0764321245
  final String? whatsappNumber; // 0764321245
  final String? whatsappInternationalNumber; // 27764321245
  final bool whatsappEnabled;
  final String prefilledMessage;

  BookingContact({
    required this.bookingId,
    required this.bookingStatus,
    required this.role,
    required this.contactName,
    required this.phoneNumber,
    this.whatsappNumber,
    this.whatsappInternationalNumber,
    required this.whatsappEnabled,
    required this.prefilledMessage,
  });

  factory BookingContact.fromJson(Map<String, dynamic> json) {
    return BookingContact(
      bookingId: json['bookingId'] as int,
      bookingStatus: json['bookingStatus'] as String,
      role: json['role'] as String,
      contactName: json['contactName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      whatsappNumber: json['whatsappNumber'] as String?,
      whatsappInternationalNumber: json['whatsappInternationalNumber'] as String?,
      whatsappEnabled: json['whatsappEnabled'] == true,
      prefilledMessage: json['prefilledMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'bookingStatus': bookingStatus,
      'role': role,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'whatsappInternationalNumber': whatsappInternationalNumber,
      'whatsappEnabled': whatsappEnabled,
      'prefilledMessage': prefilledMessage,
    };
  }
}
