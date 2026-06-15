class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000';

  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/signup';
  static String get googleAuth => '$baseUrl/api/auth/google';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get profile => '$baseUrl/api/auth/profile';
  static String get updateProfile => '$baseUrl/api/auth/update-profile';
  static String get updateFcmToken => '$baseUrl/api/auth/fcm-token';
  static String get uploadProfilePicture =>
      '$baseUrl/api/auth/upload-profile-picture';
  static String get forgotPassword => '$baseUrl/api/auth/forgot-password';
  static String get resetPassword => '$baseUrl/api/auth/reset-password';

  static String get transactions => '$baseUrl/api/transactions';
}
