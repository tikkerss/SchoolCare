import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/wali_kelas/data/absensi_repository.dart';
import 'package:schoolcare/features/wali_kelas/pages/wali_kelas_home_page.dart';

/// Pintu masuk route '/wali' (dipanggil dari app_router.dart).
/// Isinya menu Wali Kelas buatan FE Wali Kelas.
/// Guru wali kelas membukanya dari tab Profil → "Menu Wali Kelas".
/// TODO(Backend): ganti Dummy*Repository dengan versi Supabase.
/// Id kelas yang diwalikan: context.read<AuthProvider>().kelasWaliId
class WaliHomePage extends StatelessWidget {
  const WaliHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WaliKelasHomePage(repository: DummyAbsensiRepository());
  }
}
