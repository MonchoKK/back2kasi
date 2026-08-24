-- -------------------------------------------------------
-- Baseline database schema for Back2Kasi
-- -------------------------------------------------------

-- Create Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Create Businesses table
CREATE TABLE businesses (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255) NOT NULL,
    business_type VARCHAR(255) NOT NULL,
    owner_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_businesses_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create Rental Units table
CREATE TABLE rental_units (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price_per_day DECIMAL(10, 2) NOT NULL,
    capacity INTEGER NOT NULL,
    rental_unit_type VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    business_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_rental_units_business FOREIGN KEY (business_id) REFERENCES businesses(id) ON DELETE CASCADE
);

-- Create Bookings table
CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    rental_unit_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(255) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_bookings_rental_unit FOREIGN KEY (rental_unit_id) REFERENCES rental_units(id) ON DELETE CASCADE,
    CONSTRAINT fk_bookings_customer FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance optimizations on Foreign Keys
CREATE INDEX idx_businesses_owner ON businesses(owner_id);
CREATE INDEX idx_rental_units_business ON rental_units(business_id);
CREATE INDEX idx_bookings_rental_unit ON bookings(rental_unit_id);
CREATE INDEX idx_bookings_customer ON bookings(customer_id);
