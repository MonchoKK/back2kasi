-- Migration: 0004_generic_marketplace.sql
-- Description: Multi-category township marketplace schema expansion

-- 1. Add category and verification status to businesses table
ALTER TABLE businesses ADD COLUMN category TEXT NOT NULL DEFAULT 'EVENTS_RENTALS';
ALTER TABLE businesses ADD COLUMN is_verified INTEGER NOT NULL DEFAULT 0;

-- Backfill legacy records to EVENTS_RENTALS
UPDATE businesses SET category = 'EVENTS_RENTALS' WHERE category IS NULL OR category = '';

-- 2. Expand rental_units table to support generic Products and Services
ALTER TABLE rental_units ADD COLUMN item_type TEXT NOT NULL DEFAULT 'SERVICE';
ALTER TABLE rental_units ADD COLUMN is_price_on_request INTEGER NOT NULL DEFAULT 0;
ALTER TABLE rental_units ADD COLUMN price_unit TEXT DEFAULT '';
ALTER TABLE rental_units ADD COLUMN price REAL DEFAULT 0.0;

-- Backfill price from legacy price_per_day
UPDATE rental_units SET price = price_per_day WHERE price IS NULL OR price = 0.0;
UPDATE rental_units SET price_unit = 'per day' WHERE price_unit IS NULL OR price_unit = '';
