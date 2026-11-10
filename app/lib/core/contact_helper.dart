// ignore_for_file: slash_for_doc_comments
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'url_strategy/url_launcher_platform.dart' as platform_launcher;

/**
 * Utility helper for WhatsApp Click-to-Chat and direct telephone contacts in Back2Kasi.
 *
 * Adheres strictly to South African local mobile formatting rules:
 * - User input & display: 0764321245 (10-digit number starting with 0).
 * - Phone calls: tel:0764321245.
 * - WhatsApp Click-to-Chat URL: https://wa.me/27764321245?text=... (leading 0 converted to 27).
 * - Communication is booking-gated: only available when the booking status is ACCEPTED/CONFIRMED.
 */
class ContactHelper {
  /**
   * Normalizes a phone number to local South African format (0XXXXXXXXX).
   * e.g., '27764321245'   -> '0764321245'
   * e.g., '+27764321245'  -> '0764321245'
   * e.g., '076 432 1245'  -> '0764321245'
   */
  static String toLocalSaPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('27') && digits.length == 11) {
      return '0${digits.substring(2)}';
    }
    if (digits.startsWith('0') && digits.length == 10) {
      return digits;
    }
    return rawPhone.trim();
  }

  /**
   * Normalizes a phone number to the international format required by WhatsApp wa.me.
   * WhatsApp requires no '+', no spaces, no dashes, and an international country code without leading zeroes.
   * e.g., '0764321245'    -> '27764321245'
   * e.g., '+27764321245'  -> '27764321245'
   */
  static String toInternationalSaPhone(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0') && digits.length == 10) {
      return '27${digits.substring(1)}';
    }
    if (digits.startsWith('27') && digits.length == 11) {
      return digits;
    }
    return digits;
  }

  /**
   * Validates if a phone number is a valid 10-digit South African number starting with 0.
   */
  static bool isValidSaLocalPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^0[0-9]{9}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^\+27[0-9]{9}$').hasMatch(cleaned)) return true;
    return false;
  }

  /**
   * Constructs the wa.me Click-to-Chat URL with encoded message payload.
   */
  static String buildWhatsAppUrl(String phone, String message) {
    final intlNumber = toInternationalSaPhone(phone);
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$intlNumber?text=$encoded';
  }

  /**
   * Constructs the tel: URI for direct telephone calls using the local number.
   */
  static String buildPhoneCallUrl(String phone) {
    final localNumber = toLocalSaPhone(phone);
    return 'tel:$localNumber';
  }

  // --- Booking-Gated Context-Aware Messages ---

  /**
   * Message sent from Customer to Business Owner for an ACCEPTED booking.
   */
  static String buildBookingCustomerMessage({
    required String businessName,
    required int bookingId,
    required String unitName,
    required String startDate,
    required String endDate,
  }) {
    return 'Hi! I have an accepted booking (#$bookingId) with $businessName on Back2Kasi '
        'for $unitName ($startDate to $endDate). '
        'I would like to coordinate details regarding my booking.';
  }

  /**
   * Message sent from Business Owner to Customer for an ACCEPTED booking.
   */
  static String buildBookingOwnerMessage({
    required String customerName,
    required String businessName,
    required int bookingId,
    required String unitName,
  }) {
    return 'Hi $customerName! This is $businessName regarding your accepted Back2Kasi booking (#$bookingId) '
        'for $unitName. Reaching out to coordinate delivery and setup.';
  }

  // --- Launch Actions ---

  /**
   * Launches WhatsApp Click-to-Chat in a new browser tab or native app.
   */
  static Future<bool> launchWhatsApp(
    BuildContext context, {
    required String phone,
    required String message,
  }) async {
    if (phone.trim().isEmpty) {
      _showFeedback(context, 'No WhatsApp number available', isError: true);
      return false;
    }

    final url = buildWhatsAppUrl(phone, message);
    try {
      final success = await platform_launcher.openUrl(url);
      if (!success && context.mounted) {
        _showFeedback(context, 'Could not open WhatsApp', isError: true);
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        _showFeedback(context, 'Could not launch WhatsApp: $e', isError: true);
      }
      return false;
    }
  }

  /**
   * Launches the native telephone dialer with the local phone number.
   */
  static Future<bool> launchCall(
    BuildContext context, {
    required String phone,
  }) async {
    if (phone.trim().isEmpty) {
      _showFeedback(context, 'No phone number available', isError: true);
      return false;
    }

    final url = buildPhoneCallUrl(phone);
    try {
      final success = await platform_launcher.openUrl(url);
      if (!success && context.mounted) {
        _showFeedback(context, 'Could not launch phone dialer', isError: true);
      }
      return success;
    } catch (e) {
      if (context.mounted) {
        _showFeedback(context, 'Could not launch dialer: $e', isError: true);
      }
      return false;
    }
  }

  static void _showFeedback(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
