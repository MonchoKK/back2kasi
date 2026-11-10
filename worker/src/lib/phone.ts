/**
 * Utility functions for South African phone numbers:
 * - Local mobile number format (display/input/calls): e.g. 0764321245 (10 digits starting with 0)
 * - WhatsApp wa.me URL format (international without +): e.g. 27764321245
 */

export function toLocalSaPhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const digits = phone.replace(/\D/g, '');
  if (digits.startsWith('27') && digits.length === 11) {
    return '0' + digits.substring(2);
  }
  if (digits.startsWith('0') && digits.length === 10) {
    return digits;
  }
  return phone;
}

export function toInternationalSaPhone(phone: string | null | undefined): string | null {
  if (!phone) return null;
  const digits = phone.replace(/\D/g, '');
  if (digits.startsWith('0') && digits.length === 10) {
    return '27' + digits.substring(1);
  }
  if (digits.startsWith('27') && digits.length === 11) {
    return digits;
  }
  return digits;
}

export function validateAndNormalizeSaLocalPhone(phone: string | null | undefined): {
  normalized: string | null;
  error?: string;
} {
  if (!phone || !phone.trim()) {
    return { normalized: null };
  }
  const cleaned = phone.trim().replace(/[\s\-\(\)]/g, '');
  if (/^0[0-9]{9}$/.test(cleaned)) {
    return { normalized: cleaned };
  }
  if (/^\+27[0-9]{9}$/.test(cleaned)) {
    return { normalized: '0' + cleaned.substring(3) };
  }
  return {
    normalized: null,
    error: 'Please enter a valid 10-digit South African phone number starting with 0 (e.g. 0764321245)',
  };
}
