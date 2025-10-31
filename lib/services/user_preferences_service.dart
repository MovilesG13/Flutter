import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPreferencesService {
  UserPreferencesService._();
  static final instance = UserPreferencesService._();
  
  Box? _prefsBox;
  static const String _boxName = 'user_preferences';
  static const String _keyCurrency = 'currency';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLocalDisplayName = 'local_display_name';
  
  Future<void> init() async {
    await Hive.initFlutter();
    _prefsBox = await Hive.openBox(_boxName);
    // Sync display name from Firebase on init if user is logged in
    await syncDisplayNameFromFirebase();
  }
  
  // ========== Currency ==========
  Future<void> setCurrency(String currency) async {
    await _prefsBox?.put(_keyCurrency, currency);
  }
  
  String getCurrency() {
    return _prefsBox?.get(_keyCurrency, defaultValue: 'USD') ?? 'USD';
  }
  
  // ========== Notifications ==========
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefsBox?.put(_keyNotificationsEnabled, enabled);
  }
  
  bool areNotificationsEnabled() {
    return _prefsBox?.get(_keyNotificationsEnabled, defaultValue: true) ?? true;
  }
  
  // ========== Display Name ==========
  // Get local cached name (for offline/quick access)
  String? getLocalDisplayName() {
    return _prefsBox?.get(_keyLocalDisplayName);
  }
  
  // Set local cached name
  Future<void> setLocalDisplayName(String name) async {
    await _prefsBox?.put(_keyLocalDisplayName, name);
  }
  
  // Sync display name from Firebase Auth to Hive (source of truth is Firebase)
  Future<void> syncDisplayNameFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      await setLocalDisplayName(user.displayName!.trim());
    }
  }
  
  // Update display name in both Firebase Auth and Hive
  Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update Firebase Auth (source of truth)
      await user.updateDisplayName(name);
      await user.reload();
      
      // Update local cache
      await setLocalDisplayName(name);
    }
  }
  
  // Get display name with fallback: Firebase > Hive > email username > 'User'
  String getDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    // Try Firebase first
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    // Fallback to Hive cache
    final localName = getLocalDisplayName();
    if (localName != null && localName.isNotEmpty) {
      return localName;
    }
    // Fallback to email username
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'User';
  }
  
  // Future with .then() handler - Set currency with callback
  Future<void> setCurrencyWithCallback(String currency, {Function()? onSuccess}) {
    return Future.value(_prefsBox?.put(_keyCurrency, currency)).then(
      (result) {
        if (onSuccess != null) {
          onSuccess();
        }
      },
    );
  }
  
  void dispose() {
    _prefsBox?.close();
  }
}

