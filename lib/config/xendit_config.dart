class XenditConfig {
  // 🔑 REPLACE THESE WITH YOUR ACTUAL XENDIT API KEYS
  // Get these from: https://dashboard.xendit.co/settings/developers
  
  // Test/Development Environment
  static const String testSecretKey = 'test';
  static const String testPublicKey = 'test';
  
  // Production Environment (use when going live)
  static const String prodSecretKey = 'xnd_production_YOUR_SECRET_KEY_HERE';
  static const String prodPublicKey = 'xnd_public_production_YOUR_PUBLIC_KEY_HERE';
  
  // Current environment flag
  static const bool isTestMode = true; // Set to false for production
  
  // Get current API keys based on environment
  static String get secretKey => isTestMode ? testSecretKey : prodSecretKey;
  static String get publicKey => isTestMode ? testPublicKey : prodPublicKey;
  
  // Xendit API URLs
  static const String baseUrl = 'https://api.xendit.co';
  static const String invoiceUrl = '$baseUrl/v2/invoices';
  
  // Payment methods available
  static const List<String> paymentMethods = [
    'CREDIT_CARD',
    'BCA',
    'MANDIRI',
    'BNI',
    'BRI',
    'PERMATA',
    'OVO',
    'DANA',
    'LINKAJA',
    'SHOPEEPAY',
  ];
}