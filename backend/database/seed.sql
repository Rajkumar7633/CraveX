-- Seed Data for CraveX

-- 1. Create Users
-- Customer: Rajkumar
INSERT INTO users (id, phone_number, email, password_hash, first_name, last_name, user_type, is_active, is_verified)
VALUES (
  'd4444444-4444-4444-4444-444444444444',
  '+917633023155',
  'rajkumar@cravex.com',
  '$2a$10$8K9V/0gQ.3l8w2/7bM.qXe6Qf99wB.U8dC.eR7o4.sJ9f1Q.1a5jG', -- 'password123'
  'Rajkumar',
  'Customer',
  'customer',
  true,
  true
) ON CONFLICT (phone_number) DO NOTHING;

-- Restaurant Owner: Ramesh
INSERT INTO users (id, phone_number, email, password_hash, first_name, last_name, user_type, is_active, is_verified)
VALUES (
  'a1111111-1111-1111-1111-111111111111',
  '+919876543211',
  'ramesh@cravex.com',
  '$2a$10$8K9V/0gQ.3l8w2/7bM.qXe6Qf99wB.U8dC.eR7o4.sJ9f1Q.1a5jG', -- 'password123'
  'Ramesh',
  'Owner',
  'restaurant',
  true,
  true
) ON CONFLICT (phone_number) DO NOTHING;

-- Rider: Suresh
INSERT INTO users (id, phone_number, email, password_hash, first_name, last_name, user_type, is_active, is_verified)
VALUES (
  'b2222222-2222-2222-2222-222222222222',
  '+919876543212',
  'suresh@cravex.com',
  '$2a$10$8K9V/0gQ.3l8w2/7bM.qXe6Qf99wB.U8dC.eR7o4.sJ9f1Q.1a5jG', -- 'password123'
  'Suresh',
  'Rider',
  'rider',
  true,
  true
) ON CONFLICT (phone_number) DO NOTHING;

-- Admin: Anjali
INSERT INTO users (id, phone_number, email, password_hash, first_name, last_name, user_type, is_active, is_verified)
VALUES (
  'c3333333-3333-3333-3333-333333333333',
  '+919876543213',
  'anjali@cravex.com',
  '$2a$10$8K9V/0gQ.3l8w2/7bM.qXe6Qf99wB.U8dC.eR7o4.sJ9f1Q.1a5jG', -- 'password123'
  'Anjali',
  'Admin',
  'admin',
  true,
  true
) ON CONFLICT (phone_number) DO NOTHING;

-- 2. Create User Wallets
INSERT INTO user_wallets (user_id, balance, currency)
VALUES 
('d4444444-4444-4444-4444-444444444444', 5000.00, 'INR'),
('b2222222-2222-2222-2222-222222222222', 0.00, 'INR')
ON CONFLICT DO NOTHING;

-- 3. Create Restaurants
INSERT INTO restaurants (
  id, user_id, name, slug, description, cuisine_types, cover_image_url, 
  address_line1, city, state, postal_code, latitude, longitude, 
  rating, total_reviews, cost_for_two, average_delivery_time, is_pure_veg
)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'a1111111-1111-1111-1111-111111111111',
  'Meghana Foods',
  'meghana-foods',
  'Delicious biryani and spicy Andhra specialties.',
  ARRAY['Biryani', 'Andhra', 'South Indian'],
  'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500',
  'Koramangala 5th Block',
  'Bengaluru',
  'Karnataka',
  '560095',
  12.9352,
  77.6245,
  4.5,
  120,
  400.00,
  25,
  false
) ON CONFLICT (slug) DO NOTHING;

-- Burger King
INSERT INTO restaurants (
  id, user_id, name, slug, description, cuisine_types, cover_image_url, 
  address_line1, city, state, postal_code, latitude, longitude, 
  rating, total_reviews, cost_for_two, average_delivery_time, is_pure_veg
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'a1111111-1111-1111-1111-111111111111',
  'Burger King',
  'burger-king',
  'Juicy burgers, fast food, and signature beverages.',
  ARRAY['Burgers', 'Fast Food', 'Beverages'],
  'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
  'Indiranagar 100ft Road',
  'Bengaluru',
  'Karnataka',
  '560038',
  12.9716,
  77.6412,
  4.2,
  95,
  300.00,
  20,
  false
) ON CONFLICT (slug) DO NOTHING;

-- A2B
INSERT INTO restaurants (
  id, user_id, name, slug, description, cuisine_types, cover_image_url, 
  address_line1, city, state, postal_code, latitude, longitude, 
  rating, total_reviews, cost_for_two, average_delivery_time, is_pure_veg
)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  'a1111111-1111-1111-1111-111111111111',
  'A2B - Adyar Ananda Bhavan',
  'a2b-adyar-ananda-bhavan',
  'Pure vegetarian South Indian delicacies and sweets.',
  ARRAY['South Indian', 'Vegetarian', 'Sweets'],
  'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?w=500',
  'HSR Layout',
  'Bengaluru',
  'Karnataka',
  '560102',
  12.9116,
  77.6388,
  4.4,
  150,
  250.00,
  30,
  true
) ON CONFLICT (slug) DO NOTHING;

-- 4. Create Menu Categories
-- Meghana Foods Categories
INSERT INTO menu_categories (id, restaurant_id, name, display_order)
VALUES 
('11111111-2222-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'Biryanis', 1),
('11111111-2222-1111-1111-222222222222', '11111111-1111-1111-1111-111111111111', 'Starters', 2)
ON CONFLICT DO NOTHING;

-- Burger King Categories
INSERT INTO menu_categories (id, restaurant_id, name, display_order)
VALUES 
('22222222-2222-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', 'Burgers', 1),
('22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Sides', 2)
ON CONFLICT DO NOTHING;

-- A2B Categories
INSERT INTO menu_categories (id, restaurant_id, name, display_order)
VALUES 
('33333333-2222-3333-3333-111111111111', '33333333-3333-3333-3333-333333333333', 'Dosa Specialties', 1),
('33333333-2222-3333-3333-222222222222', '33333333-3333-3333-3333-333333333333', 'Beverages', 2)
ON CONFLICT DO NOTHING;

-- 5. Create Menu Items
-- Meghana Foods items
INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, is_vegetarian, preparation_time, spice_level)
VALUES 
('11111111-3333-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', '11111111-2222-1111-1111-111111111111', 'Meghana Special Chicken Biryani', 'Our signature spicy chicken biryani.', 280.00, false, 20, 'hot'),
('11111111-3333-1111-1111-222222222222', '11111111-1111-1111-1111-111111111111', '11111111-2222-1111-1111-111111111111', 'Paneer Biryani', 'Fragrant rice with soft spiced paneer cubes.', 240.00, true, 15, 'medium'),
('11111111-3333-1111-1111-333333333333', '11111111-1111-1111-1111-111111111111', '11111111-2222-1111-1111-222222222222', 'Andhra Chilli Chicken', 'Super spicy green chilli chicken starter.', 220.00, false, 15, 'extra_hot')
ON CONFLICT DO NOTHING;

-- Burger King items
INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, is_vegetarian, preparation_time, spice_level)
VALUES 
('22222222-3333-2222-2222-111111111111', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-111111111111', 'Veg Whopper', 'Our classic big burger with flame-grilled veg patty.', 179.00, true, 10, 'mild'),
('22222222-3333-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-111111111111', 'Chicken Whopper', 'Our signature big chicken burger.', 199.00, false, 10, 'mild'),
('22222222-3333-2222-2222-333333333333', '22222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'Golden French Fries', 'Crispy salted potato fries.', 89.00, true, 5, 'mild')
ON CONFLICT DO NOTHING;

-- A2B items
INSERT INTO menu_items (id, restaurant_id, category_id, name, description, price, is_vegetarian, preparation_time, spice_level)
VALUES 
('33333333-3333-3333-3333-111111111111', '33333333-3333-3333-3333-333333333333', '33333333-2222-3333-3333-111111111111', 'Masala Dosa', 'Thin crispy crepe filled with spiced potato mash.', 110.00, true, 12, 'mild'),
('33333333-3333-3333-3333-222222222222', '33333333-3333-3333-3333-333333333333', '33333333-2222-3333-3333-111111111111', 'Plain Idli (2 Pcs)', 'Soft steamed rice cakes served with sambar & chutney.', 60.00, true, 8, 'mild'),
('33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333', '33333333-2222-3333-3333-222222222222', 'Filter Coffee', 'Traditional South Indian frothy milk coffee.', 40.00, true, 5, 'mild')
ON CONFLICT DO NOTHING;
