# Engineering Log: Sprint 30 — Booking-Gated WhatsApp & Business Contact Integration

## Overview
Implemented the **Booking-Gated WhatsApp & Business Contact Integration** for Back2Kasi in accordance with the revised technical specification.

Direct contact (both WhatsApp Click-to-Chat and ordinary telephone calls) is strictly **booking-gated**: communication options are only unlocked after the business owner accepts the customer's booking request (`ACCEPTED` / `CONFIRMED` status). General profile pages and catalogue items remain pure discovery surfaces without pre-booking contact exposure.

---

## 1. Key Business Rules & Security

| Business Rule | Implementation |
|---|---|
| **Contact Unlock Trigger** | Only after booking acceptance (`CONFIRMED` / `ACCEPTED` status). |
| **Revocation** | When a booking leaves accepted status (`CANCELLED`, `COMPLETED`, `PENDING`), contact is immediately revoked and blocked by the backend. |
| **Bidirectional Access** | Both **Customer** and **Business Owner** can initiate WhatsApp chats or phone calls once the booking is accepted. |
| **Backend Isolation** | Every contact request checks authentication, verifies requester identity against customer ID or business owner ID, and validates booking lifecycle state. |
| **SA Phone Standard** | Input and display use 10-digit South African local format (`0764321245`). Phone calls use `tel:0764321245`. WhatsApp links use international conversion `https://wa.me/27764321245?text=...`. |

---

## 2. Backend Architecture (Cloudflare Workers + D1)

- **Database Migration** (`worker/migrations/0003_whatsapp_contact.sql`):
  - Adds `whatsapp_number TEXT`, `whatsapp_enabled INTEGER NOT NULL DEFAULT 0`, `whatsapp_message TEXT` to `businesses`.
  - Creates index `idx_businesses_whatsapp_enabled`.
- **Phone Utilities** (`worker/src/lib/phone.ts`):
  - `toLocalSaPhone`: Formats phone to standard 10-digit `0XXXXXXXXX`.
  - `toInternationalSaPhone`: Formats phone to international format without `+` (`27XXXXXXXXX`) for `wa.me`.
  - `validateAndNormalizeSaLocalPhone`: Validates 10-digit South African mobile numbers starting with `0`.
- **Booking-Gated Contact Route** (`worker/src/routes/bookings.ts`):
  - `GET /api/v1/bookings/:id/contact` (JWT required):
    - Verifies booking exists.
    - Verifies caller is either the customer who booked or the owner of the business.
    - Verifies status is `CONFIRMED` or `ACCEPTED`; otherwise returns `403 Forbidden`.
    - If customer: returns business phone, WhatsApp (if enabled), and customer prefilled enquiry.
    - If owner: returns customer registered phone as contact and owner prefilled outreach.
- **Owner Contact Settings Routes** (`worker/src/routes/businesses.ts`):
  - `GET /api/v1/businesses/:id/contact-settings`: Retrieve owner's contact and WhatsApp preferences.
  - `PUT /api/v1/businesses/:id/contact-settings`: Update owner's WhatsApp number and toggle.

---

## 3. Flutter Application & UX Architecture

- **Models**:
  - `BookingContact` (`app/lib/models/booking_contact.dart`): Data contract for authorized booking contacts.
  - `Business` (`app/lib/models/business.dart`): Added `whatsappNumber`, `whatsappEnabled`, and `whatsappMessage`.
- **Contact Helper** (`app/lib/core/contact_helper.dart`):
  - `cleanWhatsAppPhone` / `toInternationalSaPhone`: Generates `wa.me/27...` links.
  - `toLocalSaPhone`: Generates `tel:0...` dialer URIs.
  - `buildBookingCustomerMessage` & `buildBookingOwnerMessage`: Context-aware message generators.
  - Universal web/native URL launcher strategy (`app/lib/core/url_strategy/`).
- **Screen Implementations**:
  - `customer_business_detail_screen.dart`: Removed public phone numbers and general contact buttons; added verified booking-gated badge.
  - `rental_unit_detail_screen.dart`: Clean catalogue browsing driving directly to booking creation without pre-acceptance contact leaks.
  - `booking_details_screen.dart`:
    - Shows **Direct Provider Contact** card when booking is accepted (`CONFIRMED`).
    - Provides **WhatsApp Provider** and **Call Provider** actions with prefilled booking reference.
    - Shows informative lock badge when booking is `PENDING`.
  - `owner_booking_details_screen.dart`:
    - Shows **Client Contact Details** card when booking is `CONFIRMED`.
    - Provides **WhatsApp Client** and **Call Client** actions.
    - Automatically loads client contact upon owner approving a pending request.
  - `create_edit_business_screen.dart`:
    - Added WhatsApp Direct Contact card with enable/disable switch.
    - "Use Business Phone Number" autofill shortcut.
    - 10-digit South African local format validation (`0764321245`).
  - `business_detail_screen.dart`:
    - Added WhatsApp status pill (Active / Disabled) and quick profile edit button.

---

## 4. Verification & Testing

- Worker typecheck: `tsc --noEmit` passed with 0 errors.
- Unit tests: `app/test/contact_helper_test.dart` covering local SA formatting, international conversion, SA phone validation, and URL construction.

