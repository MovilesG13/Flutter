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
  
  // Track last login timestamp (for showing last connection)
  Future<void> setLastLoginTimestamp(int timestamp) async {
    await _prefs?.setInt('last_login_timestamp', timestamp);
  }
  
  Future<int?> getLastLoginTimestamp() async {
    return _prefs?.getInt('last_login_timestamp');
  }
  
  // Track last transaction timestamp (for showing last income/expense)
  Future<void> setLastTransactionTimestamp(int timestamp) async {
    // Ensure SharedPreferences is initialized
    if (_prefs == null) {
      await init();
    }
    await _prefs?.setInt('last_transaction_timestamp', timestamp);
  }
  
  // Future with .then() handler - Save transaction timestamp with callback
  Future<void> setLastTransactionTimestampWithCallback(int timestamp, {Function()? onSuccess}) {
    return Future.value(_prefs?.setInt('last_transaction_timestamp', timestamp)).then(
      (result) {
        if (onSuccess != null) {
          onSuccess();
        }
      },
    );
  }
  
  Future<int?> getLastTransactionTimestamp() async {
    return _prefs?.getInt('last_transaction_timestamp');
  }
  
  // Format last transaction timestamp to human-readable "X days/hours/minutes ago"
  String getLastTransactionText() {
    // Ensure _prefs is initialized
    if (_prefs == null) {
      // Try to get synchronously (may return null if not initialized)
      return 'No transactions yet';
    }
    
    final timestamp = _prefs?.getInt('last_transaction_timestamp');
    if (timestamp == null) {
      return 'No transactions yet';
    }
    
    final lastTransaction = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastTransaction);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Async version that ensures SharedPreferences is initialized
  Future<String> getLastTransactionTextAsync() async {
    if (_prefs == null) {
      await init();
    }
    
    final timestamp = _prefs?.getInt('last_transaction_timestamp');
    if (timestamp == null) {
      return 'No transactions yet';
    }
    
    final lastTransaction = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastTransaction);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Format timestamp to human-readable "X days/hours/minutes ago" (for login)
  String getLastConnectionText() {
    final timestamp = _prefs?.getInt('last_login_timestamp');
    if (timestamp == null) {
      return 'First connection';
    }
    
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
  // Set multiple settings with combined async patterns
  Future<void> setMultipleSettingsWithCombinedAsync({
    int? loginTimestamp,
    int? transactionTimestamp,
  }) async {
    // Start with async/await
    if (_prefs == null) {
      await init();
    }
    
    // Use .then() to chain multiple set operations
    return Future.value(null).then((_) async {
      if (loginTimestamp != null) {
        await _prefs?.setInt('last_login_timestamp', loginTimestamp);
      }
    }).then((_) async {
      if (transactionTimestamp != null) {
        await _prefs?.setInt('last_transaction_timestamp', transactionTimestamp);
      }
    });
  }
}

