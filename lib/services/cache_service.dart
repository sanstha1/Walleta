// cache_service.dart
abstract class LocalCacheService {
  Future<void> initialize();
  Future<bool> getTrialStarted();
  Future<bool> getOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
  Future<void> setTrialStarted(bool started);
  Future<String?> getCachedAuthToken();
  Future<void> clearAllCache();
}

// user_data_service.dart
abstract class UserDataService {
  bool get isLoggedIn;
  Future<void> loadUserData();
  Future<void> clearUserData();
  String? get userId;
  String? get userName;
  String? get userEmail;
}

// database_service.dart
abstract class DatabaseService {
  Future<void> initialize();
  Future<void> close();
  Future<void> clearDatabase();
}

// auth_service.dart
abstract class AuthService {
  bool get isAuthenticated;
  Future<void> checkAuthStatus();
  Future<bool> validateToken();
  Future<void> logout();
}