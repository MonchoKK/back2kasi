-- Migration: 0005_seed_starter_marketplace.sql
-- Description: Seed realistic starter businesses and catalogue items across all 6 township sectors

PRAGMA foreign_keys = ON;

-- 1. Ensure master merchant user exists
INSERT OR IGNORE INTO users (id, first_name, last_name, email, password, phone_number, role)
VALUES (
    10,
    'Kasi',
    'Merchant',
    'merchant@back2kasi.co.za',
    '$2a$10$hstPq4pRfr3RBEpDQBMw1eQkcHGPmFMl5bmL5g/HS7hDWNssx5vxK',
    '+27712345601',
    'OWNER'
);

-- 2. Update existing legacy businesses with proper category and verified status
UPDATE businesses SET category = 'EVENTS_RENTALS', is_verified = 1 WHERE id IN (1, 2, 4);

-- 3. Seed starter businesses across all 6 sectors
-- Category: FOOD
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    101,
    'Mam'' Kasi Shisanyama & Braai Lounge',
    'Authentic township flame-grilled chuck, spicy boerewors, BBQ wings, chakalaka, and pap. Open daily for dine-in, takeaway, and event platters.',
    'Shop 14, Zone 3, Diepkloof, Soweto',
    '+27712345601',
    'FOOD',
    10,
    'FOOD',
    1,
    '+27712345601',
    1,
    'Hi Mam'' Kasi! I found your Shisanyama on Back2Kasi. I''d like to place an order or enquire about today''s braai menu.'
);

INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    102,
    'Gauteng Kota & Burger Corner',
    'The crispiest, freshest kasi kotas in town. Loaded with fresh chips, polony, Russian sausage, egg, melted cheese, and our signature atchar sauce.',
    '820 Block F, Soshanguve, Pretoria',
    '+27762345602',
    'FOOD',
    10,
    'FOOD',
    1,
    '+27762345602',
    1,
    'Hi Gauteng Kota Corner! I found you on Back2Kasi. Can I place an order for collection?'
);

-- Category: BEAUTY
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    103,
    'Glam Kasi Braids & Hair Lounge',
    'Specialists in neat Knotless Braids, Bohemian Curls, Wig revamps & glue installations, and healthy natural hair scalp treatments.',
    '542 Mabopane Square, Mabopane, Pretoria',
    '+27782345603',
    'BEAUTY',
    10,
    'BEAUTY',
    1,
    '+27782345603',
    1,
    'Hi Glam Kasi! I found your salon on Back2Kasi. I''d like to book an appointment for hair braiding.'
);

INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    104,
    'Fresh Fade Barber Lounge',
    'Top-tier tapers, clean skin fades, beard grooming, hot towel steam treatments, and precision hair art in Soweto.',
    'Shop 4, Vilakazi St, Orlando West, Soweto',
    '+27732345604',
    'BEAUTY',
    10,
    'BEAUTY',
    1,
    '+27732345604',
    1,
    'Hi Fresh Fade! I found your barbershop on Back2Kasi. Can I book a chair for today?'
);

-- Category: AUTOMOTIVE
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    105,
    'Ekasi Sparkle Car Wash & Detailing',
    'High-pressure snow foam wash, undercarriage cleaning, interior shampoo valet, and engine bay steam cleaning.',
    'Corner 12th Ave & Tsamaya Rd, Mamelodi East, Pretoria',
    '+27792345605',
    'AUTOMOTIVE',
    10,
    'AUTOMOTIVE',
    1,
    '+27792345605',
    1,
    'Hi Ekasi Sparkle! I found your car wash on Back2Kasi. What time are you open until today?'
);

INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    106,
    'Kasi Tyre Doctor & Wheel Clinic',
    'New and quality retread tyres, fast puncture plugs, high-speed computer wheel balancing, and roadside puncture rescue.',
    'Plot 24, Golden Highway, Sebokeng, Vaal',
    '+27722345606',
    'AUTOMOTIVE',
    10,
    'AUTOMOTIVE',
    1,
    '+27722345606',
    1,
    'Hi Tyre Doctor! I found you on Back2Kasi. Do you have tyre stock available?'
);

-- Category: RETAIL
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    107,
    'Kasi Corner Fresh & Spaza Market',
    'Your neighbourhood spaza shop for daily fresh bread, milk, ice-cold drinks, 10kg maize meal, airtime, and groceries.',
    'Stand 1102, Extension 4, Alexandra, Johannesburg',
    '+27812345607',
    'RETAIL',
    10,
    'RETAIL',
    1,
    '+27812345607',
    1,
    'Hi Kasi Corner Spaza! I found your shop on Back2Kasi.'
);

INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    108,
    'Mzansi Streetwear & Kasi Apparel',
    'Original South African street culture fashion: printed bucket hats, heavyweight hoodies, graphic tees, and local accessories.',
    'Shop 12, Dobsonville Mall, Soweto',
    '+27842345608',
    'RETAIL',
    10,
    'RETAIL',
    1,
    '+27842345608',
    1,
    'Hi Mzansi Streetwear! I saw your clothing on Back2Kasi. Is this item available in my size?'
);

-- Category: HOME_SERVICES
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    109,
    'Soweto Quick-Fix Plumbing & Geysers',
    '24/7 licensed emergency plumbers: burst pipes, blocked drain rodding, geyser repairs, and complete bathroom piping.',
    '411 Phiri St, Soweto',
    '+27822345609',
    'HOME_SERVICES',
    10,
    'HOME_SERVICES',
    1,
    '+27822345609',
    1,
    'Hi Soweto Quick-Fix! I have a plumbing emergency and found you on Back2Kasi. Can a plumber assist?'
);

INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    110,
    'Kasi Strong Welding & Security Gates',
    'Heavy-duty custom burglar gates, window grilles, boundary fencing, and automated sliding driveway gate motor installations.',
    'Stand 77, Zone 1, Meadowlands, Soweto',
    '+27762345610',
    'HOME_SERVICES',
    10,
    'HOME_SERVICES',
    1,
    '+27762345610',
    1,
    'Hi Kasi Strong Welding! I found you on Back2Kasi. I would like a quote for security gates.'
);

-- Category: EVENTS_RENTALS
INSERT OR IGNORE INTO businesses (id, name, description, address, phone_number, business_type, owner_id, category, is_verified, whatsapp_number, whatsapp_enabled, whatsapp_message)
VALUES (
    111,
    'Royal Kasi Tents & VIP Sanitation',
    'Waterproof Bedouin stretch tents, luxury mobile flush toilets, gold Tiffany chairs, and complete event staging.',
    '896 Block BB, Soshanguve, Pretoria',
    '+27659405819',
    'EVENTS_RENTALS',
    10,
    'EVENTS_RENTALS',
    1,
    '+27659405819',
    1,
    'Hi Royal Kasi Events! I found you on Back2Kasi. I''d like to check date availability for equipment hire.'
);

-- 4. Seed Catalogue Items (Products & Services)
-- Mam' Kasi Shisanyama (101)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (201, 'Full Shisanyama Platter (Chuck, Wors & Wings)', 'Succulent flame-grilled beef chuck, spicy boerewors, BBQ wings with pap, chakalaka, and fresh salsa salad.', 185.0, 1, 'PRODUCT', 'AVAILABLE', 101, 'PRODUCT', 0, 'per platter', 185.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (202, 'Kasi Quarter Leg & Slap Chips Meal', 'Grilled peri-peri chicken quarter leg served with freshly fried slap chips and a hot roll.', 65.0, 1, 'PRODUCT', 'AVAILABLE', 101, 'PRODUCT', 0, 'per meal', 65.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (203, 'Spit-Braai Master & Event Catering Service', 'Full on-site braai masters, charcoal, gas spit, and chef team for birthday celebrations, weddings, and family gatherings.', 1200.0, 1, 'SERVICE', 'AVAILABLE', 101, 'SERVICE', 0, 'per event', 1200.0);

-- Gauteng Kota Corner (102)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (204, 'Executive Monster Kota', 'Fresh loaf loaded with crispy chips, Russian sausage, fried egg, double melted cheese, polony, and mango atchar.', 55.0, 1, 'PRODUCT', 'AVAILABLE', 102, 'PRODUCT', 0, 'each', 55.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (205, 'Kasi Double-Decker Cheeseburger', 'Two 100% pure beef patties, melted cheddar cheese slices, tomato, caramelized onion, and peri-mayo on a toasted sesame bun.', 60.0, 1, 'PRODUCT', 'AVAILABLE', 102, 'PRODUCT', 0, 'each', 60.0);

-- Glam Kasi Braids (103)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (206, 'Knotless Braids (Medium Length)', 'Clean, lightweight, scalp-friendly parting knotless braids. Hair extensions included with styling oil finish.', 350.0, 1, 'SERVICE', 'AVAILABLE', 103, 'SERVICE', 0, 'per style', 350.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (207, 'Lace Frontal Wig Revamp & Installation', 'Clarifying wig wash, deep moisture mask, customized hairline plucking, knot bleaching, and HD lace adhesive installation.', 400.0, 1, 'SERVICE', 'AVAILABLE', 103, 'SERVICE', 0, 'per installation', 400.0);

-- Fresh Fade Barber Lounge (104)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (208, 'Executive Skin Fade & Razor Edge', 'Low, mid, or high skin taper fade with a sharp straight-razor hairline lineup and soothing aftershave lotion.', 80.0, 1, 'SERVICE', 'AVAILABLE', 104, 'SERVICE', 0, 'per cut', 80.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (209, 'Beard Sculpting & Hot Towel Treatment', 'Precision beard shaping, essential oil massage, and hot eucalyptus steam towel to soften whiskers and open pores.', 60.0, 1, 'SERVICE', 'AVAILABLE', 104, 'SERVICE', 0, 'per session', 60.0);

-- Ekasi Sparkle Car Wash (105)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (210, 'Full Snow Foam Wash & High-Gloss Tyre Shine', 'High-pressure undercarriage spray, thick snow foam hand mitt wash, rim wash, chamois dry, and tyre dressing.', 70.0, 1, 'SERVICE', 'AVAILABLE', 105, 'SERVICE', 0, 'per car', 70.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (211, 'Interior Upholstery Shampoo & Deep Valet', 'Wet-vacuum deep extraction for seats, carpets, and boot, plus dashboard anti-UV conditioning and air freshener.', 350.0, 1, 'SERVICE', 'AVAILABLE', 105, 'SERVICE', 0, 'per vehicle', 350.0);

-- Kasi Tyre Doctor (106)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (212, 'Tubeless Puncture Plug Repair', 'Rapid on-rim puncture vulcanizing plug repair with valve inspection and tire pressure calibration.', 50.0, 1, 'SERVICE', 'AVAILABLE', 106, 'SERVICE', 0, 'per tyre', 50.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (213, 'Computerized Wheel Balancing (Set of 4)', 'High-accuracy digital spin balancing to stop steering vibration and maximize tread longevity.', 160.0, 1, 'SERVICE', 'AVAILABLE', 106, 'SERVICE', 0, 'set of 4', 160.0);

-- Kasi Corner Spaza (107)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (214, 'Township Fresh Bread & Full Cream Milk Combo', 'Freshly delivered superior sliced white bread plus a 2-litre fresh full-cream milk bottle.', 32.0, 1, 'PRODUCT', 'AVAILABLE', 107, 'PRODUCT', 0, 'per combo', 32.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (215, 'Super Maize Meal (10kg Bag)', 'Premium milled super white maize meal for fluffy and traditional South African pap.', 115.0, 1, 'PRODUCT', 'AVAILABLE', 107, 'PRODUCT', 0, '10kg bag', 115.0);

-- Mzansi Streetwear (108)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (216, '''Back To Kasi'' Heavyweight Heritage Hoodie', 'Premium 340gsm brushed cotton fleece pullover hoodie with embroidered brand emblem and kangaroo pocket. Sizes S–XXL.', 380.0, 1, 'PRODUCT', 'AVAILABLE', 108, 'PRODUCT', 0, 'each', 380.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (217, 'Classic Kasi Corduroy Bucket Hat', 'Vintage-wash corduroy festival bucket hat with breathable eyelets and woven heritage badge.', 150.0, 1, 'PRODUCT', 'AVAILABLE', 108, 'PRODUCT', 0, 'each', 150.0);

-- Soweto Quick-Fix Plumbing (109)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (218, 'Burst Pipe & Drain Unblocking Callout', 'Fast on-site diagnostic, professional drain snake clearing, and pipe repair by qualified plumbers.', 350.0, 1, 'SERVICE', 'AVAILABLE', 109, 'SERVICE', 0, 'callout fee', 350.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (219, 'Geyser Heating Element & Thermostat Replacement', 'Supply and fitting of high-efficiency 3kW or 4kW geyser heating element and safety thermostat.', 650.0, 1, 'SERVICE', 'AVAILABLE', 109, 'SERVICE', 0, 'per installation', 650.0);

-- Kasi Strong Welding (110)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (220, 'Heavy Duty Custom Security Gate', 'Galvanized 25mm square tube security gate with double slam-lock system and anti-rust primer finish.', 1800.0, 1, 'PRODUCT', 'AVAILABLE', 110, 'PRODUCT', 0, 'per gate', 1800.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (221, 'Sliding Driveway Gate Motor Installation', 'Complete installation of Centurion D5 smart motor kit including steel rack, 2 remote transmitters, and battery backup.', 3200.0, 1, 'SERVICE', 'AVAILABLE', 110, 'SERVICE', 0, 'per installation', 3200.0);

-- Royal Kasi Tents & VIP Sanitation (111)
INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (222, 'VIP Mobile Executive Flush Toilet Trailer', 'Dual-cubicle flush toilet trailer with vanity mirror, ceramic bowl, solar interior lighting, and water basin.', 950.0, 1, 'SERVICE', 'AVAILABLE', 111, 'SERVICE', 0, 'per day', 950.0);

INSERT OR IGNORE INTO rental_units (id, name, description, price_per_day, capacity, rental_unit_type, status, business_id, item_type, is_price_on_request, price_unit, price)
VALUES (223, 'All-Weather White Stretch Tent (10m x 15m)', 'Waterproof commercial stretch marquee with aluminum poles and rigging for weddings, funerals, and parties.', 2500.0, 1, 'SERVICE', 'AVAILABLE', 111, 'SERVICE', 0, 'per event', 2500.0);

