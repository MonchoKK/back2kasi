-- Migration: 0008_image_data_fallback.sql
-- Description: Adds image_data column to rental_unit_images for resilient direct storage when R2 is unconfigured

ALTER TABLE rental_unit_images ADD COLUMN image_data TEXT;

