import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _reminderDaysKey = 'reminder_days';
  static const _pinEnabledKey = 'pin_enabled';
  static const _pinHashKey = 'pin_hash';
  static const _jwtTokenKey = 'jwt_token';
  static const _userEmailKey = 'user_email';
  static const _cachedDocumentsKey = 'cached_documents_json';
  static const _cachedDocumentPrefix = 'cached_document_';

  Future<int> getReminderDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reminderDaysKey) ?? 7;
  }

  Future<void> setReminderDays(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderDaysKey, value);
  }

  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  Future<String?> getPinHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinHashKey);
  }

  Future<void> setPinHash(String hash) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, hash);
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  // ── JWT / session ────────────────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtTokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtTokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtTokenKey);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  Future<void> clearUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
  }

  Future<void> setCachedDocumentsJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedDocumentsKey, json);
  }

  Future<String?> getCachedDocumentsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedDocumentsKey);
  }

  Future<void> clearCachedDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDocumentsKey);
  }

  Future<void> setCachedDocumentJson(String documentId, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachedDocumentPrefix$documentId', json);
  }

  Future<String?> getCachedDocumentJson(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_cachedDocumentPrefix$documentId');
  }

  Future<void> clearCachedDocumentJson(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachedDocumentPrefix$documentId');
  }

  Future<void> clearOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDocumentsKey);
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_cachedDocumentPrefix))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearAll() async {
    await clearToken();
    await clearUserEmail();
    await clearPin();
    await clearOfflineCache();
  }
}
