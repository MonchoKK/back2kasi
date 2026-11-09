-- Migration: 0002_rental_unit_images.sql
-- Description: Adds rental_unit_images table for Cloudflare R2 image metadata and primary image flags

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS rental_unit_images (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rental_unit_id INTEGER NOT NULL REFERENCES rental_units(id) ON DELETE CASCADE,
    r2_key TEXT NOT NULL,
    image_url TEXT NOT NULL,
    content_type TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    is_primary INTEGER NOT NULL DEFAULT 0,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_rental_unit_images_unit ON rental_unit_images(rental_unit_id);
CREATE INDEX IF NOT EXISTS idx_rental_unit_images_primary ON rental_unit_images(rental_unit_id, is_primary);

