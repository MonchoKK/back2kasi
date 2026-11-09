# Sprint 25 — Catalogue Image Management

## Overview
Sprint 25 introduced complete, end-to-end photo catalogue management across the Back2Kasi platform without disrupting existing booking workflows or authentication systems. The architecture pairs Cloudflare R2 bucket storage with Cloudflare D1 metadata storage and delivers a modern visual photo manager in the Flutter application.

---

## Architecture & Technical Implementation

```
┌────────────────────────┐         ┌─────────────────────────┐         ┌───────────────────────┐
│   Flutter Mobile App   │ ──────> │ Cloudflare Edge Worker  │ ──────> │  Cloudflare R2 Bucket │
│  (ImagePicker + Grid)  │ <────── │ (JWT & Ownership Guard) │ <────── │ (Binary Image Assets) │
└────────────────────────┘         └────────────┬────────────┘         └───────────────────────┘
                                                │
                                                ▼
                                   ┌─────────────────────────┐
                                   │   Cloudflare D1 SQLite  │
                                   │  (Image Metadata & Rel) │
                                   └─────────────────────────┘
```

### 1. Cloudflare D1 Database Schema (`0002_rental_unit_images.sql`)
Created migration `worker/migrations/0002_rental_unit_images.sql` establishing relational storage for image attachments:
* `id` (INTEGER PRIMARY KEY)
* `rental_unit_id` (FOREIGN KEY REFERENCES `rental_units(id)` ON DELETE CASCADE)
* `r2_key` (TEXT NOT NULL, uniquely partitioned under `rental-units/:id/:uuid.:ext`)
* `image_url` (TEXT NOT NULL, serving path `/api/v1/images/:key`)
* `content_type` (TEXT NOT NULL, MIME type validation)
* `file_size` (INTEGER NOT NULL, max 5MB constraint)
* `is_primary` (INTEGER DEFAULT 0, cover flag)
* `display_order` (INTEGER DEFAULT 0)
* `created_at` & `updated_at` timestamps

### 2. Cloudflare R2 Bucket Binding & Worker Endpoints
Updated `worker/wrangler.jsonc` to declare the `IMAGES_BUCKET` binding (`back2kasi-images`). Implemented the following endpoints:
* `GET /api/v1/images/*`: Public image delivery streaming from R2 with `Cache-Control: public, max-age=31536000, immutable`, `ETag`, and content MIME type.
* `GET /api/v1/rental-units/:id/images`: Retrieves all photos for a unit sorted by `is_primary DESC, display_order ASC`.
* `POST /api/v1/rental-units/:id/images`: Authenticated multipart upload enforcing:
  * Only business owners can upload photos to units they own (`403 Forbidden` guard).
  * Maximum 5 images per rental unit limit.
  * MIME formats restricted to `JPEG`, `PNG`, and `WebP`.
  * Size cap enforced at 5 MB (`5 * 1024 * 1024` bytes).
  * Automatic promotion to primary cover for first uploaded photo.
* `PATCH /api/v1/rental-units/:id/images/:imageId/primary`: Atomic toggle setting primary cover photo.
* `DELETE /api/v1/rental-units/:id/images/:imageId`: Removes asset from R2, deletes record from D1, and automatically promotes the next remaining photo if the deleted photo was the cover.
* Enriched `GET /api/v1/rental-units` and `GET /api/v1/rental-units/:id` responses with `images` array and `primaryImageUrl`.

### 3. Flutter Application Integration
* **Dependencies**: Added `image_picker: ^1.1.2` and `cached_network_image: ^3.3.1` to `pubspec.yaml`.
* **Platform Permissions**: Configured `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` in iOS `Runner/Info.plist`.
* **Data Models**:
  * Created `RentalUnitImage` (`app/lib/models/rental_unit_image.dart`).
  * Updated `RentalUnit` with `images`, `primaryImageUrl`, and `displayImageUrl` fallback getter.
* **Provider Operations** (`RentalUnitProvider`):
  * `uploadUnitImage(...)` using `http.MultipartRequest`.
  * `setPrimaryUnitImage(...)` with optimistic in-memory mirror.
  * `deleteUnitImage(...)` with automatic cover reassignment.
* **Reusable UI Components**:
  * `CachedImageView`: Smooth placeholder spinner, error fallbacks, and support for relative URL resolution via `ApiConfig.resolveImageUrl`.
  * `ImageUploadGrid`: 5-slot interactive manager supporting Gallery/Camera selection, 5MB validation, primary star badge indicator, and instant deletion.
* **Screen Upgrades**:
  * `CreateEditUnitScreen`: Integrated `ImageUploadGrid` for live photo management (immediate upload in Edit mode, batch upload on create).
  * `BusinessDetailScreen`: Added 72x72 cover image thumbnail preview and photo count pill to each unit card.
  * `CustomerBusinessDetailScreen`: Upgraded unit cards to display 160px cover photo banners and photo count badges.

---

## Verification & Test Results
* **Worker Static Analysis**: `npm run typecheck` completed with **0 errors**.
* **Dart Static Analysis**: `dart analyze lib` completed with **No issues found!**
* **Test Suite Verification**:
  * **20/20 Flutter tests passing** (`flutter test`).
  * 16/16 existing tests verified against regressions (auth, booking flow, owner dashboard).
  * 4/4 new Sprint 25 tests verified (`rental_unit_image_test.dart`):
    * `RentalUnitImage.fromJson` parsing
    * `RentalUnitImage.toJson` serialization
    * `RentalUnit.fromJson` array mapping & primary image resolution
    * `ApiConfig.resolveImageUrl` URL resolution

