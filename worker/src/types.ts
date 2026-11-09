export type BusinessType = 'TOILET_RENTAL' | 'COLD_ROOM_RENTAL';

export type RentalUnitType =
  | 'STANDARD_TOILET'
  | 'VIP_TOILET'
  | 'CHEMICAL_TOILET'
  | 'STANDARD_COLD_ROOM'
  | 'MOBILE_COLD_ROOM';

export type RentalUnitStatus = 'AVAILABLE' | 'RENTED' | 'UNDER_MAINTENANCE';

export type BookingStatus = 'PENDING' | 'CONFIRMED' | 'COMPLETED' | 'CANCELLED';

export type Role = 'USER' | 'ADMIN';

export interface Env {
  DB: D1Database;
  IMAGES_BUCKET: R2Bucket;
  JWT_SECRET?: string;
  DEFAULT_JWT_SECRET?: string;
  JWT_EXPIRATION_SECONDS?: string;
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

export interface BusinessRow {
  id: number;
  name: string;
  description: string | null;
  address: string;
  phone_number: string;
  business_type: BusinessType;
  owner_id: number;
  created_at: string;
  updated_at: string;
}

export interface RentalUnitRow {
  id: number;
  name: string;
  description: string | null;
  price_per_day: number;
  capacity: number;
  rental_unit_type: RentalUnitType;
  status: RentalUnitStatus;
  business_id: number;
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
  tokenType: string;
  expiresIn: number;
}

export interface BusinessResponse {
  id: number;
  name: string;
  description: string | null;
  address: string;
  phoneNumber: string;
  businessType: BusinessType;
  ownerId: number;
  createdAt: string;
  updatedAt: string;
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
  capacity: number;
  rentalUnitType: RentalUnitType;
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
