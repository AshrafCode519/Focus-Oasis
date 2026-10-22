import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  static const String _keyCustomUrl = 'oasis_custom_supabase_url';
  static const String _keyCustomKey = 'oasis_custom_supabase_key';

  // Real Supabase credentials for pomodoro-timer project
  static const String defaultUrl = 'https://ooicqwlfelpyrrclgebq.supabase.co';
  static const String defaultAnonKey = 'sb_publishable_d677NrYQpmmIkXp7zXQBng_pdWD-zh4';

  static String getUrl(SharedPreferences prefs) {
    return prefs.getString(_keyCustomUrl) ?? defaultUrl;
  }

  static String getAnonKey(SharedPreferences prefs) {
    return prefs.getString(_keyCustomKey) ?? defaultAnonKey;
  }

  static Future<void> saveCredentials({
    required SharedPreferences prefs,
    required String url,
    required String anonKey,
  }) async {
    final cleanUrl = url.trim();
    final cleanKey = anonKey.trim();

    if (cleanUrl.isNotEmpty) {
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null || !uri.hasScheme || (!uri.isScheme('https') && uri.host != 'localhost' && uri.host != '127.0.0.1')) {
        throw const FormatException('يجب أن يبدأ رابط Supabase بـ https:// لضمان تشفير وأمان البيانات');
      }
    }

    await prefs.setString(_keyCustomUrl, cleanUrl);
    await prefs.setString(_keyCustomKey, cleanKey);
  }

  static bool isConfigured(SharedPreferences prefs) {
    final url = getUrl(prefs);
    final key = getAnonKey(prefs);
    return url.isNotEmpty &&
        key.isNotEmpty &&
        !url.contains('xyzcompany') &&
        !key.contains('placeholder');
  }
}
