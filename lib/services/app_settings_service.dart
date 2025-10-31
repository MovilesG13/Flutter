import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  AppSettingsService._();
  static final instance = AppSettingsService._();
  
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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
    await _prefs?.setInt('last_transaction_timestamp', timestamp);
  }
  
  Future<int?> getLastTransactionTimestamp() async {
    return _prefs?.getInt('last_transaction_timestamp');
  }
  
  // Format last transaction timestamp to human-readable "X days/hours/minutes ago"
  String getLastTransactionText() {
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
}

