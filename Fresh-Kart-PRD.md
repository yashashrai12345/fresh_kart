# Product Requirements Document (PRD)
## Fresh Kart — Vegetables & Fruits Delivery Platform

**Version:** 1.0
**Prepared for:** Fresh Kart (single-vendor online grocery / APMC-direct fresh produce delivery)
**Source reference:** `fresh-kart-menu-19.html` (existing static single-file HTML prototype, analyzed and used as the functional baseline)
**Target stack:** Android app in **Flutter**, Admin Panel as a **Website**, backend on **free-tier tools**

---

## 1. Background & Source Analysis

The existing HTML file is a single-page, static "digital menu + WhatsApp checkout" prototype for a fictitious vegetable/fruit delivery brand called **FRESH KART**. Key characteristics found in the file:

- Pure front-end app (HTML/CSS/vanilla JS), **no real backend** — all catalog data (~40+ items across 4 categories) is hardcoded in a JS object (`MENU`), including base64-embedded product photos.
- **Categories found:** Vegetables, Leafy Greens & Herbs, Fruits, Combo Packs.
- Each item has: name, price, MRP (for discount %), weight/unit (`/kg`, `/bunch`, etc.), description, diet tag (`veg` / `egg` / `limited`), spice level, photo, out-of-stock flag, rating, review count, optional `stockLeft` (low-stock indicator).
- **Search bar** filters items live by name/description.
- **Category tabs** with sticky scrollspy navigation.
- **Product detail modal**: photo, delivery-time banner, quantity chips (e.g., 250g/500g/1kg), wishlist heart icon, "Similar Products" rail, trust badges.
- **Cart** stored in-memory during session; a floating cart bar shows item count and total; a bottom sheet shows line items, a **free-delivery progress bar** (free above ₹250, else flat fee), delivery address textarea (with **browser geolocation reverse-lookup**), 10-digit phone field.
- **Checkout = "Order on WhatsApp"** — no payment gateway; it builds an order-summary text message and opens `wa.me/<number>` with the prefilled message. Cash/UPI collected on delivery.
- **Order history & tracking** is persisted via a generic `window.storage` key-value API (get/set/list), not `localStorage`. Tracking is a **cosmetic 4-step timeline** (Placed → Confirmed → Packed → Out for delivery), not connected to any real fulfillment system.
- **Wishlist** persisted the same way.
- Static business info block: name, subtitle, tagline, address, and a 7-day open/close hours table; a WhatsApp "chat with support" link; an "About us / Freshness Guarantee" block.
- No login/auth, no real order management, no admin surface, no payments, no notifications, no delivery-partner flow — this is a **customer-facing brochure + WhatsApp order pad only**.

**Assumption (stated explicitly):** Since the prototype has zero backend and zero admin capability, this PRD treats it as the **v1 functional spec for the customer experience only**, and defines a **new, proper backend + native Android app + web admin panel** around it, per your requirements. I've kept the product catalog, categories, cart/wishlist behavior, free-delivery logic, and WhatsApp-order concept from the HTML, and re-platformed everything else (data persistence, images, order lifecycle, auth, admin control) onto a real, free-tier-friendly stack.

---

## 2. Goals & Objectives

1. Replace the static HTML prototype with a real **Flutter Android app** that reproduces (and improves) the exact shopping experience: browse → search → filter by category → view item → add to cart → checkout.
2. Give the business owner a **web-based Admin Panel** to manage products, categories, prices, stock, orders, and basic store settings — without touching code.
3. Keep **infrastructure cost at $0** using free tiers, since this is a small single-vendor store.
4. Preserve the **WhatsApp-first checkout** model (low friction, no payment gateway needed at launch) while making it possible to add real order management (status updates, admin views orders) instead of just a cosmetic tracker.
5. Ship a maintainable, well-structured codebase suitable for a solo/small-team developer.

### Non-Goals (v1)
- Online payment gateway integration (Razorpay/UPI-intent, etc.) — Cash/UPI-on-delivery only, same as prototype.
- Multi-vendor / multi-store support.
- Delivery-partner (rider) mobile app.
- iOS app (Flutter codebase will support it later with near-zero extra work, but it's out of scope now).

---

## 3. Users & Roles

| Role | Platform | Description |
|---|---|---|
| **Customer** | Android app (Flutter) | Browses catalog, searches, adds to cart, places order (WhatsApp handoff), views order history/status, manages wishlist & address. |
| **Admin / Store Owner** | Web Admin Panel | Manages categories & products (CRUD, stock, price, photos), views & updates order status, edits store settings (hours, delivery fee/threshold, WhatsApp number, banners), views basic analytics. |
| **(Future) Delivery Staff** | Not in v1 | Out of scope; admin manually updates order status for now. |

---

## 4. Feature Requirements

### 4.1 Customer App (Flutter — Android)

#### A. Catalog & Browsing
- Home screen: hero header (store name, tagline, logo), trust banner, search bar, category tabs (sticky), product grid (2 columns, matching the HTML card layout: photo, veg/non-veg-style diet dot, discount badge, name, rating pill, price + strikethrough MRP, weight/unit).
- Out-of-stock items shown greyed-out with an "Unavailable" ribbon (as in the HTML `oos-ribbon`).
- Low-stock badge when `stockLeft` is set (e.g., "Only 4 left").
- Live search-as-you-type across name + description.
- Category scrollspy (auto-highlight active tab while scrolling).

#### B. Product Detail
- Bottom-sheet/full-screen detail view: large photo, name, diet tag, rating & review count, delivery-window banner ("Fresh delivery — Tomorrow, 6–9 AM" style, sourced from store settings), description, quantity selector chips (derived from weight/unit config, e.g. 250g/500g/1kg for `/kg` items), wishlist toggle, "Similar Products" horizontal rail (same category, excluding current item), sticky bottom price + Add-to-cart/quantity-stepper bar.

#### C. Cart & Checkout
- Persistent cart (survives app restarts) with quantity steppers.
- Free-delivery progress indicator (threshold configurable from Admin, default ₹250, same as prototype).
- Delivery address field with **device GPS + reverse-geocoding** (free provider — see §6) to auto-fill locality/city; manual entry always allowed.
- 10-digit phone number field with validation.
- **Checkout via WhatsApp**: builds the same style of itemized order-summary message and deep-links to WhatsApp (`https://wa.me/<storeNumber>?text=...`) — reproduces the exact behavior from the HTML, using the store's configured WhatsApp number (editable from Admin, not hardcoded).
- On successful WhatsApp handoff, the order is also saved to the **backend** (not just local storage) as a real order record with status `PLACED`.

#### D. Orders & Tracking
- "My Orders" screen listing past orders (fetched from backend, replacing the old `window.storage` history) with order ID, items, total.
- Order detail shows a status timeline: **Placed → Confirmed → Packed → Out for Delivery → Delivered**, driven by the **real status the Admin sets** (upgrade over the prototype's fake timer-based tracker).

#### E. Wishlist
- Heart-toggle on product cards/detail; wishlist screen; persisted to backend per device/user so it survives reinstalls once basic auth exists (see §4.3).

#### F. Store Info
- About/Why-Fresh-Kart block, freshness guarantee text, opening hours, address, and "Chat with us on WhatsApp" support link — all editable from Admin instead of hardcoded.

#### G. Non-functional
- Offline-friendly catalog caching (so the app still shows the last-loaded catalog with no network).
- Image loading with placeholders (category-based icon fallback, same idea as the HTML's SVG icon fallback when no photo is set).

### 4.2 Admin Panel (Website)

- **Login** (email/password) for the store owner — single admin account is enough for v1, but built to support multiple staff accounts later.
- **Dashboard**: today's orders count, pending orders, low-stock items at a glance.
- **Category management**: create/edit/reorder/delete categories (Vegetables, Leafy Greens & Herbs, Fruits, Combo Packs, + custom).
- **Product management**: CRUD for products — name, description, price, MRP, weight/unit, category, diet tag, spice level, stock status (in-stock / out-of-stock / limited + stock count), photo upload (see §6 for free image hosting), rating/review seed values.
- **Order management**: list of orders with customer name/phone/address, items, totals, and a **status dropdown** (Placed/Confirmed/Packed/Out for Delivery/Delivered/Cancelled) — this status is what drives the customer app's tracking screen.
- **Store settings**: business name, tagline, subtitle, address, WhatsApp support/order number, weekly open/close hours, free-delivery threshold, flat delivery fee, about-us text, freshness-guarantee text.
- **Basic search/filter** on products and orders.
- Responsive layout (usable on a laptop primarily; mobile-friendly is a bonus, not a hard requirement for v1).

### 4.3 Auth (minimal, for v1)
- Customer app: **anonymous/device-based identity** at launch (no forced signup, matching the prototype's frictionless feel) using a generated device/installation ID, upgradeable later to phone-OTP login if needed.
- Admin panel: standard email/password auth.

---

## 5. Information Architecture / Data Model (high level)

- **Store** (singleton settings doc): name, tagline, subtitle, address, whatsappNumber, hours[7], freeDeliveryThreshold, deliveryFee, aboutText, guaranteeText.
- **Category**: id, name, sortOrder.
- **Product**: id, categoryId, name, description, price, mrp, unit/weight, dietTag, spiceLevel, photoUrl, inStock (bool), stockLeft (nullable), rating, reviewCount, sortOrder.
- **Order**: id, deviceId/customerId, items[{productId, name, qty, unitPrice}], subtotal, deliveryFee, total, address, phone, status, createdAt, statusUpdatedAt.
- **WishlistItem**: deviceId/customerId, productId.
- **AdminUser**: id, email, passwordHash, role.

---

## 6. Recommended Free/Open-Source Tech Stack

Chosen for **zero cost at small scale**, minimal ops overhead, and good Flutter/web support.

| Layer | Recommendation | Why (free-tier notes) |
|---|---|---|
| Mobile app | **Flutter** (Dart) | As requested; single codebase, easy Android build, free/open-source. |
| Admin panel frontend | **React** (or Flutter Web reusing some models) + **Vite**, hosted on **Vercel/Netlify free tier** | Free hosting, generous limits for a low-traffic single-store admin panel. |
| Backend/API + Database + Auth | **Supabase** (free tier: Postgres DB, Auth, Storage, Realtime, auto-generated REST/GraphQL) | Free tier covers a small store's traffic comfortably; Postgres is relational and easy to model orders/products; built-in Auth for Admin login; built-in Storage for product photos (replacing base64-in-code from the prototype). *(Firebase Spark plan is a solid free alternative if you prefer Google's ecosystem — Firestore + Auth + Storage + free Android push via FCM.)* |
| Image hosting | **Supabase Storage** free tier (or Firebase Storage) | Replaces the huge inline base64 images in the HTML — real URLs, faster loads, easy to update from Admin. |
| Push notifications (order status updates) | **Firebase Cloud Messaging (FCM)** — free, unlimited | Works fine even if the rest of the backend is Supabase; Flutter has first-class FCM support. |
| Checkout handoff | **WhatsApp deep link** (`wa.me`) — free, no API cost | Exactly like the prototype; no WhatsApp Business API subscription needed for v1. |
| Reverse geocoding for "use current location" | **OpenStreetMap Nominatim** (free, rate-limited, no key) or **BigDataCloud free reverse-geocode API** (used in the original HTML) | Keeps the same free, no-signup approach as the prototype. |
| State management (Flutter) | **Riverpod** or **Provider** (free/open-source) | Standard, well-documented choices. |
| CI/simple hosting for admin | **GitHub + Vercel free tier** | Auto-deploy on push, zero cost. |

> Everything above has a genuinely usable free tier for a small single-store business (dozens–low hundreds of orders/day). If/when the store scales significantly, these are also the natural upgrade paths to paid tiers without a rewrite.

---

## 7. Success Metrics (v1)

- Admin can add/edit/remove a product and see it reflected in the Android app within a normal refresh/cache cycle.
- A customer can go from opening the app to a filled-out WhatsApp order message in under 5 taps for a repeat item.
- Admin can update an order's status and the customer sees the updated tracking timeline in-app.
- Zero recurring infra cost at launch traffic levels.

---

## 8. Open Questions (for you to confirm before dev starts)

1. Should customer accounts eventually support phone-OTP login (for cross-device order history), or is device-based identity acceptable long-term?
2. Should the Admin Panel support multiple staff logins/roles from day one, or is single-owner login fine for v1?
3. Any plan to add real payments (UPI intent / Razorpay) later, or is Cash/UPI-on-delivery the permanent model?
4. Should push notifications be included in v1, or added after the first release?

---

## 9. Suggested Phased Roadmap

1. **Phase 1** — Backend schema (Supabase) + Admin Panel (auth, category/product CRUD, store settings).
2. **Phase 2** — Flutter app: catalog browsing, search, product detail, cart (matching HTML UX 1:1).
3. **Phase 3** — WhatsApp checkout + order persistence to backend + Admin order list/status update.
4. **Phase 4** — Order tracking screen in-app tied to real status; wishlist; polish, offline caching, push notifications.
