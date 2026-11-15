import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi aplikasi yang dibaca dari file `.env`.
class AppConfig {
  AppConfig._();

  /// `DEMO_MODE=true`  → aplikasi memakai data contoh di `lib/core/demo/demo_data.dart`
  ///                     (tidak butuh Supabase, cocok selama Backend belum siap).
  /// `DEMO_MODE=false` → aplikasi memakai Supabase sungguhan.
  static bool get demo => (dotenv.env['DEMO_MODE'] ?? 'true').trim().toLowerCase() == 'true';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
