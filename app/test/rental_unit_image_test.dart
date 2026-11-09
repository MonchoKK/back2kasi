import 'package:flutter_test/flutter_test.dart';
import 'package:back2kasi_app/models/rental_unit.dart';
import 'package:back2kasi_app/models/rental_unit_image.dart';
import 'package:back2kasi_app/config/api_config.dart';

void main() {
  group('Sprint 25 - RentalUnitImage and Image Config Tests', () {
    test('RentalUnitImage.fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'rentalUnitId': 42,
        'imageUrl': 'https://back2kasi.workers.dev/api/v1/images/rental-units/42/sample.jpg',
        'contentType': 'image/jpeg',
        'fileSize': 1048576,
        'isPrimary': true,
        'displayOrder': 0,
        'createdAt': '2026-11-09T12:00:00Z',
      };

      final image = RentalUnitImage.fromJson(json);

      expect(image.id, 1);
      expect(image.rentalUnitId, 42);
      expect(image.imageUrl, 'https://back2kasi.workers.dev/api/v1/images/rental-units/42/sample.jpg');
      expect(image.contentType, 'image/jpeg');
      expect(image.fileSize, 1048576);
      expect(image.isPrimary, true);
      expect(image.displayOrder, 0);
      expect(image.createdAt, DateTime.parse('2026-11-09T12:00:00Z'));
    });

    test('RentalUnitImage.toJson exports expected structure', () {
      final image = RentalUnitImage(
        id: 5,
        rentalUnitId: 10,
        imageUrl: '/api/v1/images/test.webp',
        contentType: 'image/webp',
        fileSize: 2048,
        isPrimary: false,
        displayOrder: 1,
      );

      final json = image.toJson();
      expect(json['id'], 5);
      expect(json['rentalUnitId'], 10);
      expect(json['imageUrl'], '/api/v1/images/test.webp');
      expect(json['contentType'], 'image/webp');
      expect(json['fileSize'], 2048);
      expect(json['isPrimary'], false);
      expect(json['displayOrder'], 1);
    });

    test('RentalUnit.fromJson parses images array and sets primary cover', () {
      final unitJson = {
        'id': 10,
        'name': 'Executive VIP Toilet',
        'description': 'Luxury unit with solar power',
        'pricePerDay': 650.0,
        'capacity': 1,
        'rentalUnitType': 'VIP_TOILET',
        'status': 'AVAILABLE',
        'businessId': 1,
        'primaryImageUrl': 'https://back2kasi.workers.dev/api/v1/images/cover.jpg',
        'images': [
          {
            'id': 101,
            'rentalUnitId': 10,
            'imageUrl': 'https://back2kasi.workers.dev/api/v1/images/cover.jpg',
            'isPrimary': true,
          },
          {
            'id': 102,
            'rentalUnitId': 10,
            'imageUrl': 'https://back2kasi.workers.dev/api/v1/images/interior.jpg',
            'isPrimary': false,
          },
        ],
      };

      final unit = RentalUnit.fromJson(unitJson);

      expect(unit.id, 10);
      expect(unit.name, 'Executive VIP Toilet');
      expect(unit.images.length, 2);
      expect(unit.primaryImageUrl, 'https://back2kasi.workers.dev/api/v1/images/cover.jpg');
      expect(unit.displayImageUrl, 'https://back2kasi.workers.dev/api/v1/images/cover.jpg');
    });

    test('ApiConfig.resolveImageUrl resolves relative and absolute paths', () {
      expect(ApiConfig.resolveImageUrl(null), isNull);
      expect(ApiConfig.resolveImageUrl(''), isNull);

      const absolute = 'https://images.unsplash.com/photo-sample';
      expect(ApiConfig.resolveImageUrl(absolute), absolute);

      const relative = '/api/v1/images/test.jpg';
      final resolved = ApiConfig.resolveImageUrl(relative);
      expect(resolved, contains('/api/v1/images/test.jpg'));
      expect(resolved, startsWith('http'));
    });
  });
}

