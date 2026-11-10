import 'package:flutter_test/flutter_test.dart';
import 'package:back2kasi_app/models/business.dart';
import 'package:back2kasi_app/models/rental_unit.dart';

void main() {
  group('BusinessCategory Model & Deserialization', () {
    test('fromString resolves all standard categories correctly', () {
      expect(BusinessCategory.fromString('BEAUTY'), BusinessCategory.BEAUTY);
      expect(BusinessCategory.fromString('FOOD'), BusinessCategory.FOOD);
      expect(BusinessCategory.fromString('AUTOMOTIVE'), BusinessCategory.AUTOMOTIVE);
      expect(BusinessCategory.fromString('RETAIL'), BusinessCategory.RETAIL);
      expect(BusinessCategory.fromString('HOME_SERVICES'), BusinessCategory.HOME_SERVICES);
      expect(BusinessCategory.fromString('EVENTS_RENTALS'), BusinessCategory.EVENTS_RENTALS);
    });

    test('fromString falls back to EVENTS_RENTALS for unknown or null strings', () {
      expect(BusinessCategory.fromString(null), BusinessCategory.EVENTS_RENTALS);
      expect(BusinessCategory.fromString('UNKNOWN_XYZ'), BusinessCategory.EVENTS_RENTALS);
      expect(BusinessCategory.fromString(''), BusinessCategory.EVENTS_RENTALS);
    });

    test('each category has valid emoji, shortName, and displayName', () {
      for (final cat in BusinessCategory.values) {
        expect(cat.emoji.isNotEmpty, isTrue);
        expect(cat.shortName.isNotEmpty, isTrue);
        expect(cat.displayName.isNotEmpty, isTrue);
        expect(cat.description.isNotEmpty, isTrue);
      }
    });

    test('Business.fromJson parses category and isVerified defaults', () {
      final json = {
        'id': 101,
        'name': 'Fresh Cuts Salon',
        'address': 'Soweto, Ward 12',
        'phone_number': '0761234567',
        'business_type': 'TOILET_RENTAL',
        'category': 'BEAUTY',
        'is_verified': 1,
        'whatsapp_enabled': 1,
        'whatsapp_number': '0761234567',
      };

      final business = Business.fromJson(json);
      expect(business.id, 101);
      expect(business.name, 'Fresh Cuts Salon');
      expect(business.category, BusinessCategory.BEAUTY);
      expect(business.isVerified, isTrue);
      expect(business.whatsappEnabled, isTrue);
    });

    test('RentalUnit.fromJson parses itemType, isPriceOnRequest, and formattedPrice', () {
      final serviceJson = {
        'id': 201,
        'business_id': 101,
        'name': 'Signature Haircut',
        'item_type': 'SERVICE',
        'price': 120.0,
        'price_unit': 'per cut',
        'is_price_on_request': 0,
        'status': 'AVAILABLE',
      };

      final service = RentalUnit.fromJson(serviceJson);
      expect(service.itemType, ItemType.SERVICE);
      expect(service.price, 120.0);
      expect(service.priceUnit, 'per cut');
      expect(service.formattedPrice, 'R 120 / per cut');

      final quoteJson = {
        'id': 202,
        'business_id': 101,
        'name': 'Full Plumbing Overhaul',
        'item_type': 'SERVICE',
        'price': 0.0,
        'is_price_on_request': 1,
        'status': 'AVAILABLE',
      };

      final quote = RentalUnit.fromJson(quoteJson);
      expect(quote.isPriceOnRequest, isTrue);
      expect(quote.formattedPrice, 'Price on Request');
    });
  });
}
