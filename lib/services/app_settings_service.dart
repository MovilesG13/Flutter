import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();
  static final instance = AppSettingsService._();
  
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Future with .then() handler - Example implementation
  Future<void> initializeWithCallback({Function(SharedPreferences)? onSuccess, Function()? onError}) {
    return SharedPreferences.getInstance().then(
      (prefs) {
        _prefs = prefs;
        if (onSuccess != null) {
          onSuccess(prefs);
        }
      },
      onError: (error) {
        if (onError != null) {
          onError();
        }
      },
    );
  }
  
  // ========== Dark Mode (SharedPreferences) ==========
  Future<void> setThemeMode(String mode) async {
    // mode: 'light', 'dark', or 'system'
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setString('theme_mode', mode);
  }
  
  Future<String> getThemeMode() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs?.getString('theme_mode') ?? 'system';
  }
  
  // Synchronous getter for theme mode
  String getThemeModeSync() {
    return _prefs?.getString('theme_mode') ?? 'system';
  }
  
  bool isDarkMode() {
    final mode = getThemeModeSync();
    return mode == 'dark';
  }
  
  // Future with .then() handler - Set theme mode with callback
  Future<void> setThemeModeWithCallback(String mode, {Function()? onSuccess}) {
    if (_prefs == null) {
      return init().then((_) => _setThemeModeSync(mode, onSuccess));
    }
    return Future.value(_setThemeModeSync(mode, onSuccess));
  }
  
  Future<void> _setThemeModeSync(String mode, Function()? onSuccess) {
    return Future.value(_prefs?.setString('theme_mode', mode)).then(
      (result) {
        if (onSuccess != null) {
          onSuccess();
        }
      },
    );
  }
  
  // Future with .then() handler + async/await combined
  // Initialize and then perform async operations
  Future<void> initializeWithCombinedAsync({Function(SharedPreferences)? onComplete}) async {
    // Start with async/await
    await Future.delayed(Duration(milliseconds: 50));
    
    // Use .then() to chain the SharedPreferences initialization
    return SharedPreferences.getInstance().then((prefs) async {
      // Inside .then() callback, use async/await
      _prefs = prefs;
      
      // Perform additional async operations
      await Future.delayed(Duration(milliseconds: 25));
      
      // Call completion callback if provided
      if (onComplete != null) {
        onComplete(prefs);
      }
    }).then((_) async {
      // Chain another .then() with async work
      await Future.delayed(Duration(milliseconds: 10));
    });
  }
  
  // Future with .then() handler + async/await combined
  // Set theme mode with combined async patterns
  Future<void> setThemeModeWithCombinedAsync(String mode) async {
    // Start with async/await
    if (_prefs == null) {
      await init();
    }
    
    // Use .then() to chain the set operation
    return Future.value(null).then((_) async {
      await _prefs?.setString('theme_mode', mode);
    }).then((_) async {
      // Additional async operations after setting theme
      await Future.delayed(Duration(milliseconds: 50));
    });
  }
}

