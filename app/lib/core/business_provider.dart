// ignore_for_file: slash_for_doc_comments, prefer_conditional_assignment
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/business.dart';

/**
 * State provider managing the business profiles registered by the owner.
 *
 * <p>Handles calling the Spring Boot backend REST endpoints, caching the owned
 * businesses list in memory, and updating interested UI components.</p>
 */
class BusinessProvider extends ChangeNotifier {
  List<Business> _myBusinesses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Business> get myBusinesses => _myBusinesses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /**
   * Helper to set loading state and notify.
   */
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /**
   * Fetch all businesses owned by the authenticated caller.
   */
  Future<void> fetchMyBusinesses(String token) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.businesses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> listJson = jsonDecode(response.body);
        _myBusinesses = listJson.map((json) => Business.fromJson(json)).toList();
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to load businesses';
      }
    } catch (e) {
      _errorMessage = 'Connection error: unable to reach host';
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Register a new business profile.
   */
  Future<void> createBusiness({
    required String name,
    String? description,
    required String address,
    required String phoneNumber,
    required BusinessType type,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.businesses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessType': type.toString().split('.').last,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final newBiz = Business.fromJson(responseBody);
        _myBusinesses.add(newBiz);
      } else {
        if (responseBody['fieldErrors'] != null) {
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          _errorMessage = errors.values.join(', ');
        } else {
          _errorMessage = responseBody['message'] ?? 'Failed to create business';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to save profile';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Update an existing business profile.
   */
  Future<void> updateBusiness(
    int id, {
    required String name,
    String? description,
    required String address,
    required String phoneNumber,
    required BusinessType type,
    required String token,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.businesses}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'address': address,
          'phoneNumber': phoneNumber,
          'businessType': type.toString().split('.').last,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final updatedBiz = Business.fromJson(responseBody);
        final index = _myBusinesses.indexWhere((element) => element.id == id);
        if (index != -1) {
          _myBusinesses[index] = updatedBiz;
        }
      } else {
        if (responseBody['fieldErrors'] != null) {
          final Map<String, dynamic> errors = responseBody['fieldErrors'];
          _errorMessage = errors.values.join(', ');
        } else {
          _errorMessage = responseBody['message'] ?? 'Failed to update business';
        }
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to update profile';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /**
   * Delete a business profile.
   */
  Future<void> deleteBusiness(int id, String token) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.businesses}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        _myBusinesses.removeWhere((element) => element.id == id);
      } else {
        final responseBody = jsonDecode(response.body);
        _errorMessage = responseBody['message'] ?? 'Failed to delete business';
        throw Exception(_errorMessage);
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Connection error: unable to delete profile';
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
