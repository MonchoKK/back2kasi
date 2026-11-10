// ignore_for_file: slash_for_doc_comments, prefer_conditional_assignment
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rental_unit.dart';
import '../models/rental_unit_image.dart';

/**
 * State provider managing rental unit inventories.
 *
 * <p>Exposes operations to fetch units by business ID, register new items,
 * modify maintenance status, or delete records from the backend API.</p>
 */
class RentalUnitProvider extends ChangeNotifier {
  final Map<int, List<RentalUnit>> _businessUnits = {};
  List<RentalUnit> _allUnits = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<int, List<RentalUnit>> get businessUnits => _businessUnits;
  List<RentalUnit> get allUnits => _allUnits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RentalUnit> getUnitsForBusiness(int businessId) {
    return _businessUnits[businessId] ?? [];
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /**
   * Fetch all available rental units across all businesses (public browse).
   * Calls GET /api/v1/rental-units with no businessId filter.
   */
  Future<void> fetchAllAvailableUnits() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.rentalUnits),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> listJson = jsonDecode(response.body);
        _allUnits = listJson.map((json) => RentalUnit.fromJson(json)).toList();
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to load units';
      }
    } catch (e) {
      _errorMessage = 'Connection error: unable to reach host';
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Fetch all units registered under a given business.
   * Note: This is a public API endpoint; no auth token is required.
   */
  Future<void> fetchUnitsForBusiness(int businessId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.rentalUnits}?businessId=$businessId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> listJson = jsonDecode(response.body);
        _businessUnits[businessId] = listJson.map((json) => RentalUnit.fromJson(json)).toList();
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to load units';
      }
    } catch (e) {
      _errorMessage = 'Connection error: unable to reach host';
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Register a new catalogue item (product or service).
   */
  Future<void> createRentalUnit({
    required int businessId,
    required String name,
    String? description,
    required double pricePerDay,
    double? price,
    bool isPriceOnRequest = false,
    String? priceUnit,
    ItemType itemType = ItemType.SERVICE,
    int capacity = 1,
    RentalUnitType type = RentalUnitType.GENERAL_SERVICE,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rentalUnits),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'businessId': businessId,
          'name': name,
          'description': description,
          'pricePerDay': pricePerDay,
          'price': price ?? pricePerDay,
          'isPriceOnRequest': isPriceOnRequest,
          'priceUnit': priceUnit,
          'itemType': itemType.toString().split('.').last,
          'capacity': capacity,
          'rentalUnitType': type.toString().split('.').last,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final newUnit = RentalUnit.fromJson(responseBody);
        if (_businessUnits[businessId] == null) {
          _businessUnits[businessId] = [];
        }
        _businessUnits[businessId]!.add(newUnit);
      } else {
        if (responseBody['fieldErrors'] != null) {
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          _errorMessage = errors.values.join(', ');
        } else {
          _errorMessage = responseBody['message'] ?? 'Failed to create item';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to save item';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Update an existing catalogue item profile.
   */
  Future<void> updateRentalUnit(
    int id, {
    required int businessId,
    required String name,
    String? description,
    required double pricePerDay,
    double? price,
    bool isPriceOnRequest = false,
    String? priceUnit,
    ItemType itemType = ItemType.SERVICE,
    int capacity = 1,
    RentalUnitType type = RentalUnitType.GENERAL_SERVICE,
    required RentalUnitStatus status,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.rentalUnits}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'pricePerDay': pricePerDay,
          'price': price ?? pricePerDay,
          'isPriceOnRequest': isPriceOnRequest,
          'priceUnit': priceUnit,
          'itemType': itemType.toString().split('.').last,
          'capacity': capacity,
          'rentalUnitType': type.toString().split('.').last,
          'status': status.toString().split('.').last,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final updatedUnit = RentalUnit.fromJson(responseBody);
        final list = _businessUnits[businessId] ?? [];
        final index = list.indexWhere((element) => element.id == id);
        if (index != -1) {
          list[index] = updatedUnit;
        }
      } else {
        if (responseBody['fieldErrors'] != null) {
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          _errorMessage = errors.values.join(', ');
        } else {
          _errorMessage = responseBody['message'] ?? 'Failed to update item';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to update item';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Delete a rental unit.
   */
  Future<void> deleteRentalUnit(int id, int businessId, String token) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.rentalUnits}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        final list = _businessUnits[businessId];
        if (list != null) {
          list.removeWhere((element) => element.id == id);
        }
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to delete unit';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to delete unit';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Uploads a new photo attachment for a rental unit listing.
   */
  Future<RentalUnitImage> uploadUnitImage({
    required int unitId,
    required int businessId,
    required String filePath,
    required String token,
    bool isPrimary = false,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.rentalUnitImages(unitId)),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      if (isPrimary) {
        request.fields['isPrimary'] = 'true';
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 201) {
        final imageJson = jsonDecode(responseBody) as Map<String, dynamic>;
        final newImage = RentalUnitImage.fromJson(imageJson);

        _updateUnitInMemory(unitId, businessId, (unit) {
          final updatedImages = List<RentalUnitImage>.from(unit.images);
          if (newImage.isPrimary) {
            for (var i = 0; i < updatedImages.length; i++) {
              final old = updatedImages[i];
              updatedImages[i] = RentalUnitImage(
                id: old.id,
                rentalUnitId: old.rentalUnitId,
                imageUrl: old.imageUrl,
                contentType: old.contentType,
                fileSize: old.fileSize,
                isPrimary: false,
                displayOrder: old.displayOrder,
                createdAt: old.createdAt,
              );
            }
          }
          updatedImages.add(newImage);

          return unit.copyWith(
            images: updatedImages,
            primaryImageUrl: newImage.isPrimary ? newImage.imageUrl : unit.primaryImageUrl ?? newImage.imageUrl,
          );
        });

        notifyListeners();
        return newImage;
      } else {
        final err = jsonDecode(responseBody);
        _errorMessage = err['message'] ?? 'Failed to upload photo';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to upload image';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Promotes an existing photo to primary display photo for a rental unit.
   */
  Future<void> setPrimaryUnitImage({
    required int unitId,
    required int imageId,
    required int businessId,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.rentalUnitImagePrimary(unitId, imageId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _updateUnitInMemory(unitId, businessId, (unit) {
          String? newPrimaryUrl;
          final updatedImages = unit.images.map((img) {
            final isTarget = img.id == imageId;
            if (isTarget) newPrimaryUrl = img.imageUrl;
            return RentalUnitImage(
              id: img.id,
              rentalUnitId: img.rentalUnitId,
              imageUrl: img.imageUrl,
              contentType: img.contentType,
              fileSize: img.fileSize,
              isPrimary: isTarget,
              displayOrder: img.displayOrder,
              createdAt: img.createdAt,
            );
          }).toList();

          return unit.copyWith(
            images: updatedImages,
            primaryImageUrl: newPrimaryUrl ?? unit.primaryImageUrl,
          );
        });

        notifyListeners();
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['message'] ?? 'Failed to set primary image';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to update primary image';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Deletes a photo from a rental unit listing.
   */
  Future<void> deleteUnitImage({
    required int unitId,
    required int imageId,
    required int businessId,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.rentalUnitImageDelete(unitId, imageId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _updateUnitInMemory(unitId, businessId, (unit) {
          final updatedImages = unit.images.where((img) => img.id != imageId).toList();
          final String? newPrimary = updatedImages.isNotEmpty
              ? updatedImages.firstWhere((img) => img.isPrimary, orElse: () => updatedImages.first).imageUrl
              : null;

          return unit.copyWith(
            images: updatedImages,
            primaryImageUrl: newPrimary,
          );
        });

        notifyListeners();
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['message'] ?? 'Failed to delete photo';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to delete photo';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _updateUnitInMemory(
    int unitId,
    int businessId,
    RentalUnit Function(RentalUnit current) transform,
  ) {
    // Update in businessUnits map
    final list = _businessUnits[businessId];
    if (list != null) {
      final index = list.indexWhere((u) => u.id == unitId);
      if (index != -1) {
        list[index] = transform(list[index]);
      }
    }

    // Update in allUnits list
    final allIndex = _allUnits.indexWhere((u) => u.id == unitId);
    if (allIndex != -1) {
      _allUnits[allIndex] = transform(_allUnits[allIndex]);
    }
  }
}
