import 'package:flutter_test/flutter_test.dart';
import 'package:back2kasi_app/core/contact_helper.dart';

void main() {
  group('ContactHelper - South African Local & WhatsApp Formatting', () {
    test('toLocalSaPhone converts international +27 to 10-digit 0 format', () {
      expect(ContactHelper.toLocalSaPhone('+27764321245'), '0764321245');
      expect(ContactHelper.toLocalSaPhone('27764321245'), '0764321245');
      expect(ContactHelper.toLocalSaPhone('076 432 1245'), '0764321245');
      expect(ContactHelper.toLocalSaPhone('0764321245'), '0764321245');
    });

    test('toInternationalSaPhone converts 10-digit 0 format to wa.me 27 format', () {
      expect(ContactHelper.toInternationalSaPhone('0764321245'), '27764321245');
      expect(ContactHelper.toInternationalSaPhone('+27764321245'), '27764321245');
      expect(ContactHelper.toInternationalSaPhone('27764321245'), '27764321245');
      expect(ContactHelper.toInternationalSaPhone('082 123 4567'), '27821234567');
    });

    test('isValidSaLocalPhone validates standard 10-digit SA numbers', () {
      expect(ContactHelper.isValidSaLocalPhone('0764321245'), isTrue);
      expect(ContactHelper.isValidSaLocalPhone('0821234567'), isTrue);
      expect(ContactHelper.isValidSaLocalPhone('0612345678'), isTrue);
      expect(ContactHelper.isValidSaLocalPhone('+27764321245'), isTrue);

      // Invalid lengths or characters
      expect(ContactHelper.isValidSaLocalPhone('12345'), isFalse);
      expect(ContactHelper.isValidSaLocalPhone('076432124'), isFalse); // 9 digits
      expect(ContactHelper.isValidSaLocalPhone('07643212455'), isFalse); // 11 digits
      expect(ContactHelper.isValidSaLocalPhone('abcdefghij'), isFalse);
    });

    test('buildWhatsAppUrl constructs wa.me URL with converted 27 prefix and encoded message', () {
      final url = ContactHelper.buildWhatsAppUrl('0764321245', 'Hi! Interested in booking.');
      expect(url, 'https://wa.me/27764321245?text=Hi!%20Interested%20in%20booking.');
    });

    test('buildPhoneCallUrl constructs tel: URI with local 0-prefix number', () {
      final url = ContactHelper.buildPhoneCallUrl('0764321245');
      expect(url, 'tel:0764321245');

      final urlFromIntl = ContactHelper.buildPhoneCallUrl('+27764321245');
      expect(urlFromIntl, 'tel:0764321245');
    });

    test('buildBusinessEnquiryMessage generates canonical profile enquiry', () {
      final defaultMsg = ContactHelper.buildBusinessEnquiryMessage();
      expect(defaultMsg.contains('Hi! I found your business on Back2Kasi.'), isTrue);
      expect(defaultMsg.contains("I'd like to find out more about your services and pricing."), isTrue);
      expect(defaultMsg.contains('Thank you!'), isTrue);

      final customMsg = ContactHelper.buildBusinessEnquiryMessage(
        customWelcomeMessage: 'Welcome to our portable toilet rental service! How can we help?',
      );
      expect(customMsg, 'Welcome to our portable toilet rental service! How can we help?');
    });

    test('buildCatalogueItemMessage generates service enquiry when isProduct is false', () {
      final msg = ContactHelper.buildCatalogueItemMessage(
        itemName: 'VIP Executive Mobile Toilet',
        isProduct: false,
      );
      expect(msg.contains('Hi! I found your business on Back2Kasi.'), isTrue);
      expect(msg.contains("I'm interested in your VIP Executive Mobile Toilet service."), isTrue);
      expect(msg.contains('Could you please provide more information?'), isTrue);
      expect(msg.contains('Thank you!'), isTrue);
    });

    test('buildCatalogueItemMessage generates product enquiry when isProduct is true', () {
      final msg = ContactHelper.buildCatalogueItemMessage(
        itemName: 'Red Velvet Birthday Cake',
        isProduct: true,
      );
      expect(msg.contains('Hi! I found your business on Back2Kasi.'), isTrue);
      expect(msg.contains("I'm interested in your Red Velvet Birthday Cake."), isTrue);
      expect(msg.contains('Could you please let me know availability and pricing?'), isTrue);
      expect(msg.contains('Thank you!'), isTrue);
    });

    test('buildBookingCustomerMessage generates context-aware enquiry', () {
      final msg = ContactHelper.buildBookingCustomerMessage(
        businessName: 'Kasi Sanitation',
        bookingId: 42,
        unitName: 'VIP Mobile Toilet',
        startDate: '2026-11-12',
        endDate: '2026-11-14',
      );
      expect(msg.contains('#42'), isTrue);
      expect(msg.contains('Kasi Sanitation'), isTrue);
      expect(msg.contains('VIP Mobile Toilet'), isTrue);
    });

    test('buildBookingOwnerMessage generates context-aware owner outreach', () {
      final msg = ContactHelper.buildBookingOwnerMessage(
        customerName: 'Thabo',
        businessName: 'Kasi Sanitation',
        bookingId: 42,
        unitName: 'VIP Mobile Toilet',
      );
      expect(msg.contains('Thabo'), isTrue);
      expect(msg.contains('#42'), isTrue);
      expect(msg.contains('delivery and setup'), isTrue);
    });
  });
}

