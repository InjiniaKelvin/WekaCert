import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _reminderDaysKey = 'reminder_days';
  static const _pinEnabledKey = 'pin_enabled';
  static const _pinHashKey = 'pin_hash';

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
}
