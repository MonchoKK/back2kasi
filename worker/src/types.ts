export type BusinessCategory =
  | 'BEAUTY'
  | 'FOOD'
  | 'AUTOMOTIVE'
  | 'RETAIL'
  | 'HOME_SERVICES'
  | 'EVENTS_RENTALS';

export type BusinessType =
  | 'TOILET_RENTAL'
  | 'COLD_ROOM_RENTAL'
  | BusinessCategory;

export type CatalogueItemType = 'PRODUCT' | 'SERVICE';

export type RentalUnitType =
  | 'STANDARD_TOILET'
  | 'VIP_TOILET'
  | 'CHEMICAL_TOILET'
  | 'STANDARD_COLD_ROOM'
  | 'MOBILE_COLD_ROOM'
  | 'GENERAL_PRODUCT'
  | 'GENERAL_SERVICE';

export type RentalUnitStatus = 'AVAILABLE' | 'RENTED' | 'UNDER_MAINTENANCE';

export type BookingStatus = 'PENDING' | 'CONFIRMED' | 'COMPLETED' | 'CANCELLED';

export type Role = 'USER' | 'ADMIN';

export interface Env {
  DB: D1Database;
  IMAGES_BUCKET?: R2Bucket;
  JWT_SECRET?: string;
  DEFAULT_JWT_SECRET?: string;
  JWT_EXPIRATION_SECONDS?: string;
  REFRESH_TOKEN_EXPIRATION_DAYS?: string;
}

export interface AuthUser {
  id: number;
  email: string;
  role: Role;
}

export interface JwtPayload {
  [key: string]: any;
  sub: string;
  userId: number;
  role: Role;
  iat: number;
  exp: number;
}

// Database Rows
export interface UserRow {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  password: string;
  phone_number: string;
  role: Role;
  created_at: string;
  updated_at: string;
}

export interface SessionRow {
  id: number;
  user_id: number;
  refresh_token_hash: string;
  user_agent: string | null;
  ip_address: string | null;
  is_revoked: number;
  expires_at: string;
  created_at: string;
  updated_at: string;
}

export interface BusinessRow {
  id: number;
  name: string;
  description: string | null;
  address: string;
  phone_number: string;
  business_type: BusinessType;
  category?: string;
  is_verified?: number;
  is_suspended?: number;
  owner_id: number;
  whatsapp_number?: string | null;
  whatsapp_enabled?: number;
  whatsapp_message?: string | null;
  created_at: string;
  updated_at: string;
}

export interface RentalUnitRow {
  id: number;
  name: string;
  description: string | null;
  price_per_day: number;
  capacity: number;
  rental_unit_type: RentalUnitType | string;
  status: RentalUnitStatus;
  business_id: number;
  item_type?: string;
  is_price_on_request?: number;
  price_unit?: string | null;
  price?: number;
  created_at: string;
  updated_at: string;
}

export interface RentalUnitImageRow {
  id: number;
  rental_unit_id: number;
  r2_key: string;
  image_url: string;
  content_type: string;
  file_size: number;
  is_primary: number;
  display_order: number;
  image_data?: string | null;
  created_at: string;
  updated_at: string;
}

export interface BookingRow {
  id: number;
  rental_unit_id: number;
  customer_id: number;
  start_date: string;
  end_date: string;
  total_price: number;
  status: BookingStatus;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// API Outbound DTOs
export interface AuthResponse {
  token: string;
  refreshToken?: string;
  tokenType: string;
  expiresIn: number;
  user?: {
    id: number;
    email: string;
    firstName: string;
    lastName: string;
    role: Role;
  };
}

export interface SessionResponse {
  id: number;
  userAgent: string | null;
  ipAddress: string | null;
  isRevoked: boolean;
  expiresAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface BusinessResponse {
  id: number;
  name: string;
  description: string | null;
  address: string;
  phoneNumber: string;
  businessType: BusinessType;
  category: string;
  isVerified: boolean;
  isSuspended?: boolean;
  ownerId: number;
  whatsappNumber?: string | null;
  whatsappEnabled?: boolean;
  whatsappMessage?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface BookingContactResponse {
  bookingId: number;
  bookingStatus: string;
  role: 'BUSINESS' | 'CUSTOMER';
  contactName: string;
  phoneNumber: string;
  whatsappNumber: string | null;
  whatsappInternationalNumber: string | null;
  whatsappEnabled: boolean;
  prefilledMessage: string;
}

export interface BusinessContactResponse {
  businessId: number;
  businessName: string;
  phoneNumber: string;
  whatsappNumber: string | null;
  whatsappEnabled: boolean;
  whatsappMessage: string | null;
}

export interface UpdateBusinessContactRequest {
  whatsappNumber?: string | null;
  whatsappEnabled: boolean;
  whatsappMessage?: string | null;
}

export interface RentalUnitImageResponse {
  id: number;
  rentalUnitId: number;
  imageUrl: string;
  contentType: string;
  fileSize: number;
  isPrimary: boolean;
  displayOrder: number;
  createdAt: string;
}

export interface RentalUnitResponse {
  id: number;
  name: string;
  description: string | null;
  pricePerDay: number;
  price: number;
  isPriceOnRequest: boolean;
  priceUnit: string | null;
  itemType: CatalogueItemType;
  capacity: number;
  rentalUnitType: RentalUnitType | string;
  status: RentalUnitStatus;
  businessId: number;
  images?: RentalUnitImageResponse[];
  primaryImageUrl?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface BookingResponse {
  id: number;
  rentalUnitId: number;
  rentalUnitName: string;
  businessName: string;
  customerId: number;
  startDate: string;
  endDate: string;
  totalPrice: number;
  status: BookingStatus;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}
