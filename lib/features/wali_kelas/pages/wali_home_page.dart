import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/wali_kelas/data/supabase_wali_kelas_repository.dart';
import 'package:schoolcare/features/wali_kelas/pages/wali_kelas_home_page.dart';

/// Pintu masuk route '/wali' (dipanggil dari app_router.dart).
/// Isinya menu Wali Kelas buatan FE Wali Kelas, dengan data dari Supabase.
/// Guru wali kelas membukanya dari tab Profil → "Menu Wali Kelas".
/// Untuk mencoba tampilan tanpa Supabase, ganti ke Dummy*Repository.
class WaliHomePage extends StatefulWidget {
  const WaliHomePage({super.key});

  @override
  State<WaliHomePage> createState() => _WaliHomePageState();
}

class _WaliHomePageState extends State<WaliHomePage> {
  // dibuat sekali supaya tidak diulang setiap halaman di-rebuild
  final _absensi = SupabaseAbsensiRepository();
  final _kontak = SupabaseKontakRepository();
  final _rapor = SupabaseRaporRepository();

  @override
  Widget build(BuildContext context) {
    return WaliKelasHomePage(
      repository: _absensi,
      kontakRepository: _kontak,
      raporRepository: _rapor,
    );
  }
}
