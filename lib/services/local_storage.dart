import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact_model.dart';
import '../models/id_model.dart';
import '../models/user_profile.dart';

class LocalStorage {
  // SharedPreferences keys
  static const String _idsKey = 'safeid_ids';
  static const String _contactsKey = 'safeid_contacts';
  static const String _profileKey = 'safeid_profile';
  static const String _emergencyIdKey = 'safeid_emergency_id';
  static const String _lockEnabledKey = 'safeid_lock_enabled';
  static const String _lastUnlockKey = 'safeid_last_unlock_epoch';
  static const String _termsAcceptedKey = 'safeid_terms_accepted';

  // PIN key (temporarily in SharedPreferences due to iOS secure storage crash)
  static const String _pinCodeKey = 'safeid_pin_code';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // ---------------- IDs ----------------

  static Future<List<IdModel>> loadIds() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_idsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => IdModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveIds(List<IdModel> ids) async {
    final prefs = await _prefs();
    final jsonString = jsonEncode(ids.map((id) => id.toJson()).toList());
    await prefs.setString(_idsKey, jsonString);
  }

  // ---------------- Contacts ----------------

  static Future<List<ContactModel>> loadContacts() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => ContactModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveContacts(List<ContactModel> contacts) async {
    final prefs = await _prefs();
    final jsonString = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, jsonString);
  }

  // ---------------- Profile ----------------

  static Future<UserProfile?> loadProfile() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _prefs();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // ---------------- Emergency ID ref ----------------

  static Future<void> setEmergencyId(IdModel id) async {
    final prefs = await _prefs();
    final ref = <String, String>{
      'type': id.type,
      'number': id.number,
      'country': id.country,
    };
    await prefs.setString(_emergencyIdKey, jsonEncode(ref));
  }

  static Future<Map<String, String>?> getEmergencyIdRef() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_emergencyIdKey);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'type': decoded['type'] as String? ?? '',
        'number': decoded['number'] as String? ?? '',
        'country': decoded['country'] as String? ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------- Lock / PIN ----------------

  static Future<bool> getLockEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  static Future<String?> getPinCode() async {
    try {
      final prefs = await _prefs();
      return prefs.getString(_pinCodeKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setPinCode(String pin) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(_pinCodeKey, pin);
    } catch (_) {}
  }

  static Future<void> clearPinCode() async {
    final prefs = await _prefs();
    await prefs.remove(_pinCodeKey);
  }

  static Future<DateTime?> getLastUnlockTime() async {
    final prefs = await _prefs();
    final millis = prefs.getInt(_lastUnlockKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> setLastUnlockTime(DateTime time) async {
    final prefs = await _prefs();
    await prefs.setInt(_lastUnlockKey, time.millisecondsSinceEpoch);
  }

  /// ✅ Secure reset: if PIN is forgotten, allow reset but wipe sensitive data.
  /// This prevents someone from resetting PIN and immediately viewing your IDs/contacts.
  static Future<void> resetPinAndWipeData() async {
    final prefs = await _prefs();

    await prefs.remove(_pinCodeKey);
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.remove(_lastUnlockKey);

    // Wipe sensitive data
    await prefs.remove(_idsKey);
    await prefs.remove(_contactsKey);
    await prefs.remove(_profileKey);
    await prefs.remove(_emergencyIdKey);
  }

  // ---------------- Terms ----------------

  static Future<bool> getTermsAccepted() async {
    final prefs = await _prefs();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  static Future<void> setTermsAccepted(bool accepted) async {
    final prefs = await _prefs();
    await prefs.setBool(_termsAcceptedKey, accepted);
  }
}
