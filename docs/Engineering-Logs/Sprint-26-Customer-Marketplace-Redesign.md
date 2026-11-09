# Sprint 26 — Customer Marketplace Redesign

## Overview
Sprint 26 transformed Back2Kasi's customer-facing experience from a basic business list into a rich, modern, image-driven rental marketplace. Customers can now discover equipment with photos, filter by township hire categories, search in real-time, explore full photo galleries with zoomable lightbox views, and seamlessly request bookings.

---

## Key Features & Implementations

### 1. Marketplace Home & Search Experience (`views/customer/browse_screen.dart`)
* **Real-Time Search Bar**: Live filtering across equipment name, description, category, and township address without full-page reloads.
* **Category Filter Bar**: Horizontally scrollable filter chips:
  * `All Categories`
  * `VIP Trailers` (VIP Toilet trailers)
  * `Standard Toilets`
  * `Chemical Toilets`
  * `Cold Storage` (Standard & mobile cold rooms)
* **Segmented Discovery Tabs**:
  * **Available Rentals**: Highlights image-rich rental unit cards with availability pills, capacity specs, and direct booking actions.
  * **Local Providers**: Highlights verified local rental businesses with business profiles, location addresses, and inventory deep links.

### 2. Image-Rich Rental Unit Cards
* Render primary cover photos with fallback category icons using [`CachedImageView`](../../app/lib/views/shared/widgets/cached_image_view.dart).
* Status pills indicating immediate availability.
* Photo count badges indicating multi-angle galleries.
* Highlighted daily rates in Warm Kasi Gold (`#FFB74D`).
* Dual action buttons: "Details" (opens full gallery) and "Book Now" (direct to booking form).

### 3. Rental Unit Detail & Photo Gallery (`views/customer/rental_unit_detail_screen.dart`)
* **Interactive Photo Carousel**: Swipeable hero carousel with page dots and image counter badges (`1 / N`).
* **Zoomable Lightbox**: Tap any photo to open a full-screen `InteractiveViewer` with pinch-to-zoom and pan support.
* **Specifications & Highlights**: Capacity badge, sanitized quality assurance badges, and full unit description.
* **Provider Profile Box**: Direct provider card with business address, phone, and deep link to all business inventory.
* **Sticky Bottom Booking Bar**: Displays price-per-day preview and prominent "Book Unit" CTA transitioning directly to `CreateBookingScreen`.

---

## Verification & Test Results
* **Static Analysis**: `dart analyze lib` passed with **No issues found!**
* **Test Suite Verification**: **22/22 Flutter tests passing** (`flutter test`):
  * 16/16 foundation and booking lifecycle tests passing without regressions.
  * 4/4 image model and URL resolution tests passing.
  * 2/2 new Sprint 26 widget tests passing in [`customer_marketplace_test.dart`](../../app/test/customer_marketplace_test.dart):
    * `BrowseScreen` search bar, category chips, and segmented tab rendering.
    * `RentalUnitDetailScreen` photo carousel, specifications, and sticky booking bar CTA.
