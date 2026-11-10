# Sprint 29 – Emerald + Warm Ivory + Charcoal + Gold Redesign

> **Date:** 2026-11-10  
> **Status:** Complete  
> **Target:** Back2Kasi Flutter Application (`app/`)

---

## 1. Final Brand Identity

Back2Kasi's design direction combines warmth, dignity, and trustworthiness without clinical glare:

| Colour | Hex | Purpose |
|---|---|---|
| **Emerald** | `#059669` | Primary Brand identity & action buttons |
| **Warm Ivory** | `#F8F5EE` | Scaffold background (organic, warm paper tone) |
| **Charcoal** | `#252B27` | Primary text and dark surfaces |
| **Champagne Gold** | `#D6A84F` | Premium accents, VIP chips, and highlights |
| **Crisp White** | `#FFFFFF` | Card surfaces floating on ivory |
| **Muted Charcoal** | `#5C6660` | Secondary copy (WCAG AAA compliant) |
| **Warm Ivory Border** | `#E7E2D6` | Subtle, warm separators |

Why this works: It feels established and premium without being overly corporate. The ivory softens the emerald, while gold adds warmth and prestige.

---

## 2. Reusable Component System (`Bk*`)

- `BkPrimaryButton`: 50px height, Emerald background (`#059669`), white text.
- `BkSecondaryButton`: Clean outlined action button.
- `BkTextField`: 52-56px input with crisp white surface, warm ivory borders, charcoal text.
- `BkAppBar`: Minimalist white/ivory header with subtle border.
- `BkBookingStatusChip`: Circular dot indicator with status-specific background tint:
  - Confirmed: Emerald (`#059669`)
  - Pending: Champagne Gold (`#D6A84F` / `#B48329`)
  - Completed: Royal Blue (`#1D4ED8`)
  - Cancelled: Red (`#DC2626`)
- `BkPriceDisplay`: Standardized ZAR daily pricing badge.
- `BkEmptyState`: Circular tinted brand icon with headline, copy, and action button.
- `BkLoadingIndicator`: Centered spinner with progress copy.
- `BkCatalogueCard` & `BkBusinessCard`: Image-led marketplace cards.

---

## 3. Scope of Modernized Screens

- Customer Experience: `BrowseScreen`, `RentalUnitDetailScreen`, `CustomerBusinessDetailScreen`, `CreateBookingScreen`, `BookingConfirmationScreen`, `BookingSuccessScreen`, `BookingDetailsScreen`, `MyBookingsScreen`.
- Business Owner Experience: `DashboardScreen`, `BusinessDetailScreen`, `BusinessListScreen`, `CreateEditBusinessScreen`, `CreateEditUnitScreen`, `OwnerBookingRequestsScreen`, `OwnerBookingDetailsScreen`.
- Authentication: `LoginScreen`, `RegisterScreen`.
- Shell: `MainNavigationShell` with ivory/white navigation bar and emerald active indicator.

---

## 4. Verification

- Added `app/test/bk_components_test.dart` verifying all `Bk*` components in the Emerald + Warm Ivory theme.

