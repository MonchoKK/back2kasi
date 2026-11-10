// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

/**
 * Macro business categories supported by the Back2Kasi multi-sector township marketplace.
 */
enum BusinessCategory {
  BEAUTY,
  FOOD,
  AUTOMOTIVE,
  RETAIL,
  HOME_SERVICES,
  EVENTS_RENTALS;

  String get key => toString().split('.').last;

  String get displayName {
    switch (this) {
      case BusinessCategory.BEAUTY:
        return 'Beauty & Personal Care';
      case BusinessCategory.FOOD:
        return 'Food & Catering';
      case BusinessCategory.AUTOMOTIVE:
        return 'Automotive Services';
      case BusinessCategory.RETAIL:
        return 'Retail & Products';
      case BusinessCategory.HOME_SERVICES:
        return 'Home & Construction';
      case BusinessCategory.EVENTS_RENTALS:
        return 'Events & Rentals';
    }
  }

  String get shortName {
    switch (this) {
      case BusinessCategory.BEAUTY:
        return 'Beauty';
      case BusinessCategory.FOOD:
        return 'Food';
      case BusinessCategory.AUTOMOTIVE:
        return 'Auto';
      case BusinessCategory.RETAIL:
        return 'Retail';
      case BusinessCategory.HOME_SERVICES:
        return 'Home';
      case BusinessCategory.EVENTS_RENTALS:
        return 'Events & Hire';
    }
  }

  String get emoji {
    switch (this) {
      case BusinessCategory.BEAUTY:
        return '💇';
      case BusinessCategory.FOOD:
        return '🍔';
      case BusinessCategory.AUTOMOTIVE:
        return '🚗';
      case BusinessCategory.RETAIL:
        return '🛍️';
      case BusinessCategory.HOME_SERVICES:
        return '🛠️';
      case BusinessCategory.EVENTS_RENTALS:
        return '🎪';
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessCategory.BEAUTY:
        return Icons.content_cut_outlined;
      case BusinessCategory.FOOD:
        return Icons.restaurant_outlined;
      case BusinessCategory.AUTOMOTIVE:
        return Icons.directions_car_outlined;
      case BusinessCategory.RETAIL:
        return Icons.shopping_bag_outlined;
      case BusinessCategory.HOME_SERVICES:
        return Icons.home_repair_service_outlined;
      case BusinessCategory.EVENTS_RENTALS:
        return Icons.celebration_outlined;
    }
  }

  String get description {
    switch (this) {
      case BusinessCategory.BEAUTY:
        return 'Salons, barbershops, nail technicians, makeup artists';
      case BusinessCategory.FOOD:
        return 'Bakeries, event caterers, braai spots, food vendors';
      case BusinessCategory.AUTOMOTIVE:
        return 'Mechanics, mobile car washes, panel beaters, tyres';
      case BusinessCategory.RETAIL:
        return 'Streetwear, furniture, electronics, crafts, homeware';
      case BusinessCategory.HOME_SERVICES:
        return 'Plumbers, electricians, painters, welders, handymen';
      case BusinessCategory.EVENTS_RENTALS:
        return 'Decor, marquee tents, equipment hire, cold rooms, toilets';
    }
  }

  static BusinessCategory fromString(String? val) {
    if (val == null || val.trim().isEmpty) {
      return BusinessCategory.EVENTS_RENTALS;
    }
    final clean = val.trim().toUpperCase();
    switch (clean) {
      case 'BEAUTY':
      case 'BEAUTY & PERSONAL CARE':
        return BusinessCategory.BEAUTY;
      case 'FOOD':
      case 'FOOD & CATERING':
        return BusinessCategory.FOOD;
      case 'AUTOMOTIVE':
      case 'AUTOMOTIVE SERVICES':
        return BusinessCategory.AUTOMOTIVE;
      case 'RETAIL':
      case 'RETAIL & PRODUCTS':
        return BusinessCategory.RETAIL;
      case 'HOME_SERVICES':
      case 'HOME & CONSTRUCTION':
        return BusinessCategory.HOME_SERVICES;
      case 'EVENTS_RENTALS':
      case 'EVENTS & RENTALS':
      case 'TOILET_RENTAL':
      case 'COLD_ROOM_RENTAL':
      default:
        return BusinessCategory.EVENTS_RENTALS;
    }
  }
}

