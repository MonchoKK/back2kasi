# Sprint 29 – Emerald Dark Mode UI/UX Redesign & Shared Component System

> **Date:** 2026-11-10  
> **Status:** Complete  
> **Target:** Back2Kasi Flutter Application (`app/`)

---

## 1. Overview & Objective

Following user feedback that the pure light mode was overly bright, Back2Kasi transitioned to a sleek, eye-comfort **Emerald Dark Theme** built around high-contrast Emerald Green (`#10B981`) and deep charcoal obsidian backgrounds (`#0D0E15`).

The goals of this redesign sprint:
1. **Color Palette & Visual Tokens**:
   - Primary Brand: Emerald Green (`#10B981`)
   - Accent / Warning: Warm Amber (`#F59E0B`)
   - Deep Background: Charcoal Obsidian (`#0D0E15`)
   - Card / Surface: Slate Dark (`#161922`)
   - Text Primary: Crisp Off-White (`#F8FAFC`)
   - Text Secondary: Muted Slate (`#94A3B8`)
   - Borders: Dark Slate (`#262D3D`)
   - Error: Red (`#EF4444`)
2. **Standardized Reusable Component System (`Bk*` Prefix)**:
   - `BkPrimaryButton`: Standard 50px call-to-action with spinner, icon, and dark text on emerald.
   - `BkSecondaryButton`: Clean outlined action button.
   - `BkTextField`: 52-56px input with dark surface, slate borders, label, prefix icon, and action handling.
   - `BkAppBar`: Minimalist dark surface header with subtle bottom border.
   - `BkBookingStatusChip`: Circular dot indicator with status-specific background tint and text.
   - `BkPriceDisplay`: Standardized ZAR daily pricing badge.
   - `BkEmptyState`: Circular tinted brand icon with headline, copy, and action button.
   - `BkLoadingIndicator`: Centered spinner with progress copy.
   - `BkCatalogueCard` & `BkBusinessCard`: Image-led marketplace cards.
   - `bk_components.dart`: Centralized barrel export.
3. **Screen Redesign Scope**:
   - Customer Experience: `BrowseScreen`, `RentalUnitDetailScreen`, `CustomerBusinessDetailScreen`, `CreateBookingScreen`, `BookingConfirmationScreen`, `BookingSuccessScreen`, `BookingDetailsScreen`, `MyBookingsScreen`.
   - Business Owner Experience: `DashboardScreen`, `BusinessDetailScreen`, `BusinessListScreen`, `CreateEditBusinessScreen`, `CreateEditUnitScreen`, `OwnerBookingRequestsScreen`, `OwnerBookingDetailsScreen`.
   - Authentication: `LoginScreen`, `RegisterScreen`.
   - Shell: `MainNavigationShell` with dark navigation bar and emerald active indicator.

---

## 2. Technical Architecture & Component Tokenization

All UI components and screens reference centralized design tokens via `AppTheme`:

```dart
class AppTheme {
  static const Color brandColor = Color(0xFF10B981);
  static const Color primaryColor = brandColor;
  static const Color successColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFF59E0B);
  static const Color darkColor = Color(0xFF0D0E15);

  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFF0D0E15);
  static const Color surfaceColor = Color(0xFF161922);
  static const Color textPrimaryColor = Color(0xFFF8FAFC);
  static const Color textSecondaryColor = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFF262D3D);
  static const Color errorColor = Color(0xFFEF4444);
  ...
}
```

---

## 3. Automated Verification

- Added `app/test/bk_components_test.dart` testing button states, loading spinners, text fields, chips, price displays, app bars, and empty states.
- Verified existing test suite across all screens.
