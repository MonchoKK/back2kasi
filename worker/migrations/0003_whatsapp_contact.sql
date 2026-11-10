-- Migration: 0003_whatsapp_contact.sql
-- Description: Adds WhatsApp contact number, visibility toggle, and optional welcome message to businesses

ALTER TABLE businesses ADD COLUMN whatsapp_number TEXT;
ALTER TABLE businesses ADD COLUMN whatsapp_enabled INTEGER NOT NULL DEFAULT 0;
ALTER TABLE businesses ADD COLUMN whatsapp_message TEXT;

CREATE INDEX IF NOT EXISTS idx_businesses_whatsapp_enabled ON businesses(whatsapp_enabled);

