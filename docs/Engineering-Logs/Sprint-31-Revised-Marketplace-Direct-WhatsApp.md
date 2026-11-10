# Sprint 31: Revised Marketplace Specification — Direct WhatsApp Inquiry Model

**Status:** ✅ Complete  
**Date:** 2026-11-10  
**Theme:** Strategic Marketplace Simplification & WhatsApp-Led Customer Inquiries

---

## 1. Executive Summary & Strategic Direction

Following deep user testing and operational alignment for township rental enterprises, Back2Kasi has transitioned from an in-app booking management paradigm to an **image-led discovery and direct WhatsApp enquiry marketplace**.

### Core Customer Journey
1. **Browse Businesses & Catalogues:** The customer discovers local businesses and inspects rental equipment (toilets, cold rooms, VIP trailers) with high-res photos and transparent pricing.
2. **Tap WhatsApp Chat / Enquire:** The customer initiates an enquiry directly from a business profile or catalogue item.
3. **Automated Prefilled Message:** The app generates a context-aware message with the business name and/or selected item name.
4. **Handoff to WhatsApp:** WhatsApp opens with the message ready to send.
5. **Customer Journey in Back2Kasi Ends Here:** Back2Kasi does not manage ongoing chats, scheduling, contracts, or payments.

---

## 2. Strategic Changes & Architectural Boundaries

| Feature Area | Decision | Implementation Details |
| :--- | :--- | :--- |
| **Customer Journey** | Simplified | 2 clean bottom navigation tabs: **Marketplace** (`BrowseScreen`) & **My Business** (`DashboardScreen`). |
| **In-App Booking Forms** | Removed from customer flow | Customer booking creation, date pickers, and booking history screens removed from primary customer navigation. |
| **Historical Data Preservation** | Preserved | Cloudflare D1 `bookings` table, past booking records, and Worker booking endpoints remain intact for audit and historical integrity. |
| **WhatsApp Prefilled Messages** | Canonical Spec | - **Business Profile:** `"Hi! I found your business on Back2Kasi.\n\nI'd like to find out more about your services and pricing.\n\nThank you!"`<br>- **Catalogue Item:** `"Hi! I found your business on Back2Kasi.\n\nI'm interested in your [Item Name] service.\n\nCould you please provide more information?\n\nThank you!"` |
| **Phone Format Standardization** | SA Local `0XXXXXXXXX` | Owner inputs and displays standard 10-digit SA number (`0764321245`). Backend & helper convert to `27764321245` for `https://wa.me/27...` Click-to-Chat. Normal calls use `tel:0764321245`. |
| **Business Owner Experience** | Streamlined | Dashboard features catalogue stats, WhatsApp contact status card (with test link), listing preview, and catalogue management. |

---

## 3. Code Modifications Summary

1. **`app/lib/core/contact_helper.dart`:**
   - Added canonical `buildBusinessEnquiryMessage({String? customWelcomeMessage})`
   - Added canonical `buildCatalogueItemMessage({required String itemName})`
   - Updated phone normalization logic for seamless local display and international wa.me links.
2. **`app/lib/views/customer/customer_business_detail_screen.dart`:**
   - Prominent **"Chat with Business"** button (`BkPrimaryButton` with chat bubble) and **"Call"** button (`BkSecondaryButton`).
   - Catalogue cards display **"Enquire on WhatsApp"** button.
   - Removed `CreateBookingScreen` dependency.
3. **`app/lib/views/customer/rental_unit_detail_screen.dart`:**
   - Replaced "Book Unit" sticky bar with **"Enquire on WhatsApp"** and **"Call"** actions.
   - Trust highlights updated to emphasize verified owners and direct WhatsApp quotes.
4. **`app/lib/views/customer/browse_screen.dart`:**
   - Catalogue item cards offer direct **"Enquire on WhatsApp"** CTA.
   - Business cards show a green "WhatsApp" badge when active and open `CustomerBusinessDetailScreen`.
5. **`app/lib/views/shared/main_navigation_shell.dart`:**
   - Streamlined from 3 navigation tabs to 2 clean tabs: **Marketplace** and **My Business**.
6. **`app/lib/views/business/dashboard_screen.dart`:**
   - Removed booking requests/counters.
   - Added **Catalogue Items** stat, **WhatsApp Contact Status Card** (active toggle, phone number, direct test link), and quick management actions.

---

## 4. Verification & Testing

- **Worker TypeScript:** `npm --prefix worker run typecheck` (`tsc --noEmit`) passes with 0 errors.
- **Unit Testing:** `app/test/contact_helper_test.dart` verifies phone formatting (`0...` <-> `27...`), URL generation, and canonical prefilled enquiry generation.
- **Platform Compatibility:** Universal launcher handles web (`window.open`) and mobile (`canLaunchUrl` / `launchUrl`) without runtime exceptions.
