import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase. Pakai HANYA di file folder `data/` (repository).
/// Jangan dipanggil saat DEMO_MODE=true karena Supabase tidak diinisialisasi.
SupabaseClient get supabase => Supabase.instance.client;
