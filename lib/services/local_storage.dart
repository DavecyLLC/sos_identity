import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/id_model.dart';
import '../models/contact_model.dart';
import '../models/user_profile.dart';

class LocalStorage {
  static const String _idsKey = 'safeid_ids';
  static const String _contactsKey = 'safeid_contacts';
  static const String _profileKey = 'safeid_profile';
  static const String _emergencyIdKey = 'safeid_emergency_id';

  static const String _lockEnabledKey = 'safeid_lock_enabled';
  static const String _lastUnlockKey = 'safeid_last_unlock_epoch';
  static const String _termsAcceptedKey = 'safeid_terms_accepted';

  // TEMPORARY (until iOS build is stable): store PIN in SharedPreferences
  static const String _pinCodeKey = 'safeid_pin_code';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  // ---------------- IDs ----------------

  static Future<List<IdModel>> loadIds() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_idsKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => IdModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveIds(List<IdModel> ids) async {
    final prefs = await _prefs();
    final list = ids.map((e) => e.toJson()).toList();
    await prefs.setString(_idsKey, jsonEncode(list));
  }

  // ---------------- Contacts ----------------

  static Future<List<ContactModel>> loadContacts() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_contactsKey);
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => ContactModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveContacts(List<ContactModel> contacts) async {
    final prefs = await _prefs();
    final list = contacts.map((e) => e.toJson()).toList();
    await prefs.setString(_contactsKey, jsonEncode(list));
  }

  // ---------------- Profile ----------------

  static Future<UserProfile?> loadProfile() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return UserProfile.fromJson(Map<String, dynamic>.from(decoded));
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
    final raw = prefs.getString(_emergencyIdKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      return {
        'type': (m['type'] as String?) ?? '',
        'number': (m['number'] as String?) ?? '',
        'country': (m['country'] as String?) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------- Lock + PIN ----------------

  static Future<bool> getLockEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  static Future<String?> getPinCode() async {
    final prefs = await _prefs();
    final pin = prefs.getString(_pinCodeKey);
    if (pin == null || pin.trim().isEmpty) return null;
    return pin;
  }

  static Future<void> setPinCode(String pin) async {
    final prefs = await _prefs();
    await prefs.setString(_pinCodeKey, pin);
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
