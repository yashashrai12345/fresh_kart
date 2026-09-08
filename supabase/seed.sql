-- Fresh Kart Seed Data
-- APMC Mandi Produce Catalog

-- 1. Insert Initial Store Settings
insert into public.store_settings (
    id, name, tagline, subtitle, address, whatsapp_number,
    operating_hours, free_delivery_threshold, delivery_fee,
    about_text, guarantee_text
) values (
    '00000000-0000-0000-0000-000000000001',
    'FRESH KART',
    'APMC-Direct Fresh Produce',
    'Farm Fresh Vegetables & Fruits at Mandi Wholesale Rates',
    'APMC Yard Gate #3, Yeshwanthpur, Bengaluru, Karnataka 560022',
    '918970050327',
    '{
        "Monday": "6:00 AM - 9:00 PM",
        "Tuesday": "6:00 AM - 9:00 PM",
        "Wednesday": "6:00 AM - 9:00 PM",
        "Thursday": "6:00 AM - 9:00 PM",
        "Friday": "6:00 AM - 9:00 PM",
        "Saturday": "6:00 AM - 10:00 PM",
        "Sunday": "6:00 AM - 10:00 PM"
    }'::jsonb,
    250.00,
    30.00,
    'Fresh Kart sources vegetables and fruits daily at 4:00 AM directly from local APMC mandis and organic farmer clusters. No cold-storage decay, zero middleman markup — only crisp, peak-fresh farm produce delivered to your doorstep within hours of procurement.',
    '100% Crisp & Clean Guarantee: If any item is bruised or unsatisfactory, WhatsApp us within 2 hours of delivery for an instant replacement or full refund without return hassle.'
) on conflict (id) do nothing;

-- 2. Insert Categories
insert into public.categories (id, name, slug, icon, sort_order, is_active) values
    ('cat_veg', 'Fresh Vegetables', 'vegetables', 'carrot', 1, true),
    ('cat_greens', 'Leafy Greens & Herbs', 'leafy-greens', 'sprout', 2, true),
    ('cat_fruits', 'Fresh Fruits', 'fruits', 'apple', 3, true),
    ('cat_combos', 'Value Combo Packs', 'combo-packs', 'shopping-bag', 4, true)
on conflict (id) do update set
    name = excluded.name,
    slug = excluded.slug,
    icon = excluded.icon,
    sort_order = excluded.sort_order;

-- 3. Insert Products
insert into public.products (
    id, category_id, name, description, price, mrp, unit,
    diet_tag, spice_level, photo_url, in_stock, stock_left, rating, review_count, sort_order
) values
    -- Vegetables
    (
        'prod_tomato_hybrid', 'cat_veg', 'Farm Fresh Hybrid Tomatoes',
        'Firm, juicy, ruby-red farm tomatoes ideal for daily curries, gravies, and fresh salads.',
        32.00, 45.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 128, 1
    ),
    (
        'prod_onion_nasik', 'cat_veg', 'Nasik Red Onions',
        'Crisp, pungently flavorful grade-A red onions sourced directly from the Nasik hub.',
        38.00, 52.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 210, 2
    ),
    (
        'prod_potato_hassan', 'cat_veg', 'Hassan Gold Potatoes',
        'Thin-skinned, clean earthen potatoes. Starchy and fluffy when cooked, perfect for roasting & boiling.',
        29.00, 40.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600&auto=format&fit=crop&q=80',
        true, null, 4.7, 185, 3
    ),
    (
        'prod_bhindi_ladyfinger', 'cat_veg', 'Tender Green Bhindi (Okra)',
        'Crisp, snap-tender baby okras picked before sunrise. Non-slimy and cooks evenly.',
        42.00, 60.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1604544203292-0ec5a1b32d56?w=600&auto=format&fit=crop&q=80',
        true, 8, 4.9, 94, 4
    ),
    (
        'prod_cauliflower', 'cat_veg', 'Snow White Cauliflower',
        'Tight, clean white curd with fresh outer green leaves intact preserving moisture.',
        35.00, 50.00, '/pc', 'veg', 0,
        'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=600&auto=format&fit=crop&q=80',
        true, null, 4.6, 76, 5
    ),
    (
        'prod_capsicum_green', 'cat_veg', 'Crisp Green Capsicum (Bell Pepper)',
        'Glossy thick-walled green bell peppers with a fresh sweet crunch.',
        55.00, 75.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 62, 6
    ),
    (
        'prod_carrot_ooty', 'cat_veg', 'Ooty Red Carrots',
        'Sweet, deep-orange farm-washed hill carrots loaded with carotene and natural crunch.',
        48.00, 65.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 89, 7
    ),
    (
        'prod_cucumber_salad', 'cat_veg', 'Crisp Salad Cucumber',
        'Cool, refreshing hydrating field cucumbers with tender seeds and delicate skin.',
        30.00, 42.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=600&auto=format&fit=crop&q=80',
        true, null, 4.7, 53, 8
    ),
    (
        'prod_green_chillies', 'cat_veg', 'Spicy Pungent Green Chillies',
        'Spicy, slender green chillies straight from Kolhapur farms for your tadka.',
        18.00, 25.00, '/pack', 'veg', 3,
        'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?w=600&auto=format&fit=crop&q=80',
        true, 5, 4.8, 41, 9
    ),
    (
        'prod_ginger_fresh', 'cat_veg', 'Old Earth Ginger (Adrak)',
        'Pungent, fiber-rich soil-washed ginger roots with intense aromatic heat.',
        36.00, 50.00, '/pack', 'veg', 2,
        'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 87, 10
    ),

    -- Leafy Greens & Herbs
    (
        'prod_palak_spinach', 'cat_greens', 'Tender Farm Palak (Spinach)',
        'Hydro-cleaned broad dark green spinach bunches rich in iron and dietary fiber.',
        24.00, 35.00, '/bunch', 'veg', 0,
        'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 145, 11
    ),
    (
        'prod_coriander_bunch', 'cat_greens', 'Aromatic Country Coriander (Dhaniya)',
        'Fragrant local desi coriander with fresh roots intact for long lasting aroma.',
        15.00, 22.00, '/bunch', 'veg', 0,
        'https://images.unsplash.com/photo-1589135233689-d56d7870636f?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 230, 12
    ),
    (
        'prod_methi_leaves', 'cat_greens', 'Fresh Desi Methi (Fenugreek)',
        'Small-leafed aromatic fenugreek with authentic bittersweet flavor profile.',
        22.00, 32.00, '/bunch', 'veg', 0,
        'https://images.unsplash.com/photo-1628773822503-930a84d436a5?w=600&auto=format&fit=crop&q=80',
        true, 4, 4.7, 72, 13
    ),
    (
        'prod_pudina_mint', 'cat_greens', 'Cool Country Mint (Pudina)',
        'Crisp, intensely refreshing menthol-rich leaves perfect for chutneys and coolers.',
        16.00, 24.00, '/bunch', 'veg', 0,
        'https://images.unsplash.com/photo-1628556270448-4d4e4148e1b1?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 64, 14
    ),
    (
        'prod_curry_leaves', 'cat_greens', 'Fragrant Curry Leaves (Kadi Patta)',
        'Freshly plucked vibrant green sprigs for that essential South Indian tadka.',
        10.00, 15.00, '/pack', 'veg', 0,
        'https://images.unsplash.com/photo-1615485500704-8e990f9900f7?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 118, 15
    ),

    -- Fruits
    (
        'prod_banana_robusta', 'cat_fruits', 'Robusta Sweet Bananas',
        'Naturally ripened, energizing sweet Cavendish bananas without carbide treatment.',
        46.00, 60.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 178, 16
    ),
    (
        'prod_mango_alphonso', 'cat_fruits', 'Devgad Alphonso Mangoes (GI Tag)',
        'The undisputed king of mangoes. Intensely fragrant, saffron pulp, zero fiber.',
        380.00, 500.00, '/kg', 'limited', 0,
        'https://images.unsplash.com/photo-1553279768-865429fa0078?w=600&auto=format&fit=crop&q=80',
        true, 6, 5.0, 92, 17
    ),
    (
        'prod_apple_shimla', 'cat_fruits', 'Kinnaur Royal Apples',
        'Crisp, sweet-tart Himalayan apples with natural red blush and superior crunch.',
        140.00, 180.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600&auto=format&fit=crop&q=80',
        true, null, 4.7, 134, 18
    ),
    (
        'prod_pomegranate_kabul', 'cat_fruits', 'Ruby Red Pomegranates (Anar)',
        'Plump arils bursting with antioxidant-rich sweet red juice.',
        160.00, 210.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&auto=format&fit=crop&q=80',
        true, null, 4.8, 81, 19
    ),
    (
        'prod_papaya_taiwan', 'cat_fruits', 'Taiwan Red Lady Papaya',
        'Honey-sweet orange flesh with digestive enzymes. Ripened on the tree.',
        45.00, 65.00, '/kg', 'veg', 0,
        'https://images.unsplash.com/photo-1517282009859-f000ec3b26fe?w=600&auto=format&fit=crop&q=80',
        true, 3, 4.6, 57, 20
    ),

    -- Combos
    (
        'prod_combo_kitchen_essentials', 'cat_combos', 'Daily Kitchen Staples Basket',
        'Includes 1kg Onions, 1kg Potatoes, 1kg Hybrid Tomatoes, and 100g Ginger + Chillies. Everything you need for daily cooking.',
        129.00, 175.00, '/pack', 'veg', 0,
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 312, 21
    ),
    (
        'prod_combo_greens_immunity', 'cat_combos', 'Immunity Green Leafy Trio',
        'Fresh combo bundle containing 2 Palak bunches, 1 Methi bunch, and 1 aromatic Mint bunch.',
        65.00, 95.00, '/pack', 'veg', 0,
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&auto=format&fit=crop&q=80',
        true, null, 4.9, 140, 22
    ),
    (
        'prod_combo_fruit_bowl', 'cat_combos', 'Morning Fruit Feast Pack',
        '1kg Robusta Bananas + 1kg Shimla Apples + 1 Papaya (~1kg). High energy breakfast nutrition for the family.',
        220.00, 290.00, '/pack', 'veg', 0,
        'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&auto=format&fit=crop&q=80',
        true, 5, 4.9, 88, 23
    )
on conflict (id) do update set
    name = excluded.name,
    description = excluded.description,
    price = excluded.price,
    mrp = excluded.mrp,
    unit = excluded.unit,
    diet_tag = excluded.diet_tag,
    photo_url = excluded.photo_url,
    stock_left = excluded.stock_left,
    in_stock = excluded.in_stock;
