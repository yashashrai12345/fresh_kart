class AppConstants {
  // Supabase Configuration (Connected to Fresh Kart Supabase Project)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nzptqpjpafzdhdknzutf.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56cHRxcGpwYWZ6ZGhka256dXRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NDc4NzUsImV4cCI6MjEwNDQyMzg3NX0.xU_GzACu6XremXkGKlEy8-_itkPPz1rcGEfWz4mKqns',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('placeholder');

  // Fallback Store Defaults (mirrors PRD and APMC Mandi operations)
  static const String defaultStoreName = 'FRESH KART';
  static const String defaultTagline = 'APMC-Direct Fresh Produce';
  static const String defaultSubtitle = 'Farm Fresh Vegetables & Fruits at Mandi Rates';
  static const String defaultAddress =
      'APMC Yard Gate #3, Yeshwanthpur, Bengaluru, Karnataka 560022';
  static const String defaultWhatsAppNumber = '918970050327';
  static const double defaultFreeDeliveryThreshold = 250.0;
  static const double defaultDeliveryFee = 30.0;

  // Storage Keys
  static const String keyDeviceId = 'fk_device_id';
  static const String keyCart = 'fk_cart_items';
  static const String keyOrders = 'fk_saved_orders';
  static const String keyWishlist = 'fk_wishlist_items';
  static const String keySavedAddress = 'fk_saved_address';
  static const String keySavedPhone = 'fk_saved_phone';
  static const String keySavedName = 'fk_saved_name';
}
