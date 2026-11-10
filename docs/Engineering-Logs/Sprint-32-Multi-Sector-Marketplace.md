# Sprint 32: Multi-Sector Township Marketplace — One Marketplace, Many Businesses

**Status:** ✅ Complete  
**Date:** 2026-11-10  
**Theme:** Strategic Expansion from Rental Niche to Universal Kasi Marketplace

---

## 1. Executive Summary & Strategic Rationale

Back2Kasi has expanded from a vertical equipment rental tool (toilets & cold rooms) into **Back2Kasi 2.0: "One marketplace. Many businesses. Discover local businesses, explore their offerings and connect directly with them."**

The platform now unites township entrepreneurs across **6 macro industry categories**:
1. 💇 **Beauty & Personal Care** (`BEAUTY`): Salons, barbers, nail technicians, makeup artists.
2. 🍔 **Food & Catering** (`FOOD`): Bakeries, caterers, food vendors, restaurants.
3. 🚗 **Automotive Services** (`AUTOMOTIVE`): Mechanics, car washes, panel beaters, tyre shops.
4. 🛍️ **Retail & Products** (`RETAIL`): Clothing, furniture, electronics, homeware.
5. 🛠️ **Home & Construction** (`HOME_SERVICES`): Plumbers, electricians, painters, contractors.
6. 🎪 **Events & Rentals** (`EVENTS_RENTALS`): Decorators, equipment hire, cold rooms, toilets.

---

## 2. Strategic Governance & Architecture Decisions

| Area | Decision | Implementation |
| :--- | :--- | :--- |
| **Merchant Onboarding** | Self-Registration + Verified Badge | Frictionless self-service merchant signup with zero initial administrative bottleneck. Businesses start unverified and earn a golden **Verified Kasi Business** trust badge (`is_verified = 1`) after admin verification. |
| **Catalogue Hierarchy** | 3-Tier Generic Model | `Business` (profile, contact, verification) &rarr; `Category` (6 industries) &rarr; `Catalogue Item` (Product vs Service). |
| **Product vs Service** | Universal Offerings | `item_type` is either `PRODUCT` (physical item sold/hired) or `SERVICE` (skilled task performed). |
| **Flexible Pricing Model** | Fixed or "Price on Request" | Supports fixed price (`price REAL`, `price_unit TEXT`) or Quote-based (`is_price_on_request = 1` displaying *"Price on Request"*). |
| **Backwards Compatibility** | Non-Destructive D1 Migration | Existing rental units default to `EVENTS_RENTALS`, `SERVICE`, and copy `price_per_day` to `price`. Aliased `CatalogueItem = RentalUnit` in Flutter. |
| **Context-Aware WhatsApp** | Dynamic Prefilled Templates | - **Product Enquiry:** `"Hi! I found your business on Back2Kasi.\n\nI'm interested in purchasing/hiring: [Item Name].\n\nCould you please let me know about availability and pricing?\n\nThank you!"`<br>- **Service Enquiry:** `"Hi! I found your business on Back2Kasi.\n\nI'm interested in booking your service: [Item Name].\n\nCould you please let me know about availability, pricing, or appointment slots?\n\nThank you!"` |

---

## 3. Database Migration (D1)

Migration: `worker/migrations/0004_generic_marketplace.sql`

```sql
-- Add category and verification to businesses
ALTER TABLE businesses ADD COLUMN category TEXT NOT NULL DEFAULT 'EVENTS_RENTALS';
ALTER TABLE businesses ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0;
CREATE INDEX IF NOT EXISTS idx_businesses_category ON businesses(category);

-- Add universal catalogue attributes to rental_units
ALTER TABLE rental_units ADD COLUMN item_type TEXT NOT NULL DEFAULT 'SERVICE';
ALTER TABLE rental_units ADD COLUMN is_price_on_request INTEGER NOT NULL DEFAULT 0;
ALTER TABLE rental_units ADD COLUMN price_unit TEXT DEFAULT '';
ALTER TABLE rental_units ADD COLUMN price REAL DEFAULT 0.0;

-- Backfill price from price_per_day
UPDATE rental_units SET price = price_per_day WHERE price = 0.0 OR price IS NULL;
```

---

## 4. Cloudflare Worker API

- **Types (`worker/src/types.ts`):** Added `BusinessCategory`, `CatalogueItemType`, extended `BusinessType` and updated `BusinessResponse` / `RentalUnitResponse`.
- **Router (`worker/src/index.ts`):** Bound `/api/v1/catalogue-items` directly to `rentalUnitRoutes`.
- **Businesses Route (`worker/src/routes/businesses.ts`):** Added query param `?category=...` for instant filtering; accepts `category` in `POST` and `PUT`.
- **Catalogue Items Route (`worker/src/routes/rental-units.ts`):** Accepts `itemType`, `isPriceOnRequest`, `priceUnit`, `price` in `POST` and `PUT`.

---

## 5. Flutter Frontend Components

- **`models/business_category.dart`:** Macro-categories with display names, short badges, emojis, and Material icons.
- **`models/business.dart`:** Added `category` and `isVerified`.
- **`models/rental_unit.dart`:** Added `ItemType`, `isPriceOnRequest`, `priceUnit`, `formattedPrice`, `typedef CatalogueItem = RentalUnit`.
- **`core/contact_helper.dart`:** Dynamic `buildCatalogueItemMessage` for Product vs Service.
- **`views/customer/browse_screen.dart`:** Horizontal category pills (All + 6 categories), segmented tab view ("Products & Services" / "Local Businesses"), Verified badge, and context-aware WhatsApp triggers.
- **`views/customer/customer_business_detail_screen.dart`:** Verified Kasi Business badge, category icon, and mixed product/service catalogue display.
- **`views/customer/rental_unit_detail_screen.dart`:** Product vs Service hero tags, flexible pricing, and item-specific WhatsApp action.
- **`views/business/create_edit_business_screen.dart`:** 6-category industry selector.
- **`views/rental_unit/create_edit_unit_screen.dart`:** Product/Service chip selector, "Price on Request" switch, unit price fields, and Cloudflare R2 photos.
- **`views/business/dashboard_screen.dart`:** Multi-business switcher with emojis and category tags, live catalogue preview, and stats.
- **`views/business/business_detail_screen.dart`:** Verified badge, category header, and Product/Service catalogue item cards.
