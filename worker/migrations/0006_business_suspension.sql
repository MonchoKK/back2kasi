-- Migration: 0006_business_suspension.sql
-- Description: Adds business suspension support to guarantee suspended businesses are not publicly discoverable

PRAGMA foreign_keys = ON;

-- 1. Add is_suspended column to businesses table
ALTER TABLE businesses ADD COLUMN is_suspended INTEGER NOT NULL DEFAULT 0;

-- 2. Index for optimal filtering in public marketplace discovery queries
CREATE INDEX IF NOT EXISTS idx_businesses_is_suspended ON businesses(is_suspended);
