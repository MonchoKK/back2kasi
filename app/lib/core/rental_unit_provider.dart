// ignore_for_file: slash_for_doc_comments, prefer_conditional_assignment
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rental_unit.dart';

/**
 * State provider managing rental unit inventories.
 *
 * <p>Exposes operations to fetch units by business ID, register new items,
 * modify maintenance status, or delete records from the backend API.</p>
 */
class RentalUnitProvider extends ChangeNotifier {
  final Map<int, List<RentalUnit>> _businessUnits = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<int, List<RentalUnit>> get businessUnits => _businessUnits;
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
   * Register a new rental unit.
   */
  Future<void> createRentalUnit({
    required int businessId,
    required String name,
    String? description,
    required double pricePerDay,
    required int capacity,
    required RentalUnitType type,
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
          _errorMessage = responseBody['message'] ?? 'Failed to create unit';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to save unit';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Update an existing rental unit profile (including status transitions).
   */
  Future<void> updateRentalUnit(
    int id, {
    required int businessId,
    required String name,
    String? description,
    required double pricePerDay,
    required int capacity,
    required RentalUnitType type,
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
          _errorMessage = responseBody['message'] ?? 'Failed to update unit';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to update unit';
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
}
