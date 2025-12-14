import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/id_model.dart';
import '../models/contact_model.dart';
import '../models/user_profile.dart';

/// LocalStorage
///
/// - IDs, contacts, profile, emergency ID, terms flag, lock flag, last unlock
///   are stored in SharedPreferences (stable across Windows, Android, web).
/// - PIN code is stored in FlutterSecureStorage (more secure) where available.
///
/// This keeps the app RELIABLE across restarts while still treating the PIN
/// as more sensitive.
class LocalStorage {
  // Secure storage instance (used only for PIN)
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  // SharedPreferences keys
  static const String _idsKey = 'safeid_ids';
  static const String _contactsKey = 'safeid_contacts';
  static const String _profileKey = 'safeid_profile';
  static const String _emergencyIdKey = 'safeid_emergency_id';

  static const String _lockEnabledKey = 'safeid_lock_enabled';
  static const String _lastUnlockKey = 'safeid_last_unlock_epoch';
  static const String _termsAcceptedKey = 'safeid_terms_accepted';

  // PIN key (secure)
  static const String _pinCodeKey = 'safeid_pin_code';

  /// Helper: get SharedPreferences instance
  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // IDs
  // ---------------------------------------------------------------------------

  static Future<List<IdModel>> loadIds() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_idsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => IdModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveIds(List<IdModel> ids) async {
    final prefs = await _prefs();
    final List<Map<String, dynamic>> jsonList =
        ids.map((id) => id.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_idsKey, jsonString);
  }

  // ---------------------------------------------------------------------------
  // Contacts
  // ---------------------------------------------------------------------------

  static Future<List<ContactModel>> loadContacts() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_contactsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => ContactModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveContacts(List<ContactModel> contacts) async {
    final prefs = await _prefs();
    final List<Map<String, dynamic>> jsonList =
        contacts.map((c) => c.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_contactsKey, jsonString);
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  static Future<UserProfile?> loadProfile() async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _prefs();
    final jsonString = jsonEncode(profile.toJson());
    await prefs.setString(_profileKey, jsonString);
  }

  // ---------------------------------------------------------------------------
  // Emergency ID reference (type + number)
  // ---------------------------------------------------------------------------

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
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return {
        'type': decoded['type'] as String? ?? '',
        'number': decoded['number'] as String? ?? '',
        'country': decoded['country'] as String? ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // App Lock / PIN
  // ---------------------------------------------------------------------------

  /// Lock enabled flag (non-sensitive)
  static Future<bool> getLockEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_lockEnabledKey, enabled);
  }

  /// PIN code (more sensitive) → keep in secure storage where supported.
  static Future<String?> getPinCode() async {
    try {
      final pin = await _secure.read(key: _pinCodeKey);
      return pin;
    } catch (_) {
      // Fallback: no PIN if secure storage fails
      return null;
    }
  }

  static Future<void> setPinCode(String pin) async {
    try {
      await _secure.write(key: _pinCodeKey, value: pin);
    } catch (_) {
      // If secure storage fails, we deliberately DO NOT store PIN elsewhere.
    }
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

  // ---------------------------------------------------------------------------
  // Terms & Conditions Acceptance
  // ---------------------------------------------------------------------------

  static Future<bool> getTermsAccepted() async {
    final prefs = await _prefs();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  static Future<void> setTermsAccepted(bool accepted) async {
    final prefs = await _prefs();
    await prefs.setBool(_termsAcceptedKey, accepted);
  }
}
