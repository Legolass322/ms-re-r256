import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/aria_api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({
    required this.apiClient,
    required SharedPreferences preferences,
  }) : _preferences = preferences {
    final storedToken = _preferences.getString(_tokenStorageKey);
    if (storedToken != null && storedToken.isNotEmpty) {
      apiClient.setAuthToken(storedToken);
    }
  }

  final AriaApiClient apiClient;
  final SharedPreferences _preferences;

  static const _tokenStorageKey = 'aria_auth_token';

  Future<UserProfile?> restoreSession() async {
    final existingToken = _preferences.getString(_tokenStorageKey);
    if (existingToken == null || existingToken.isEmpty) {
      return null;
    }

    try {
      apiClient.setAuthToken(existingToken);
      return await apiClient.getCurrentUser();
    } catch (_) {
      await _preferences.remove(_tokenStorageKey);
      apiClient.setAuthToken(null);
      return null;
    }
  }

  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
  }) {
    return apiClient.registerUser(
      email: email,
      username: username,
      password: password,
    );
  }

  Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    try {
      developer.log('DEBUG: Starting login process...', name: 'AuthRepository');
      final token = await apiClient.login(
        username: username,
        password: password,
      );
      developer.log('DEBUG: Login successful, token received', name: 'AuthRepository');
      
      await _preferences.setString(_tokenStorageKey, token.accessToken);
      developer.log('DEBUG: Token saved to preferences', name: 'AuthRepository');
      
      apiClient.setAuthToken(token.accessToken);
      developer.log('DEBUG: Token set in API client', name: 'AuthRepository');
      
      // Get user profile after successful login
      developer.log('DEBUG: Getting user profile after login...', name: 'AuthRepository');
      try {
        final user = await apiClient.getCurrentUser();
        developer.log('DEBUG: User profile received: ${user.username}, isAdmin: ${user.isAdmin}', name: 'AuthRepository');
        return user;
      } catch (getUserError, getUserStack) {
        developer.log('ERROR getting user profile: $getUserError', name: 'AuthRepository', error: getUserError, stackTrace: getUserStack);
        // If getCurrentUser fails, we still have a valid token, so create a minimal user profile
        // This shouldn't happen, but handle gracefully
        rethrow;
      }
    } catch (e, stackTrace) {
      developer.log('ERROR in login: $e', name: 'AuthRepository', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserProfile> refreshCurrentUser() {
    return apiClient.getCurrentUser();
  }

  Future<void> logout() async {
    await _preferences.remove(_tokenStorageKey);
    apiClient.setAuthToken(null);
  }
}

