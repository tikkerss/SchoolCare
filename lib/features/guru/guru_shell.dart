import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/features/guru/pages/jadwal_page.dart';
import 'package:schoolcare/features/guru/pages/tugas_page.dart';
import 'package:schoolcare/shared/widgets/app_bottom_nav.dart';

/// Kerangka tampilan Guru (route '/guru'): navigasi bawah 3 tab.
///   Jadwal → absensi mengajar, berita acara, daftar siswa + catatan
///   Tugas  → tambah/ubah/hapus tugas, deadline, penilaian
///   Profil → guru wali kelas membuka "Menu Wali Kelas" dari sini
class GuruShell extends StatefulWidget {
  const GuruShell({super.key});

  @override
  State<GuruShell> createState() => _GuruShellState();
}

class _GuruShellState extends State<GuruShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    JadwalPage(),
    TugasPage(),
    // Profil + tombol Keluar; guru wali kelas juga melihat tombol "Menu Wali Kelas" di sini.
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(ikon: Icons.calendar_today_outlined, label: 'Jadwal'),
          AppBottomNavItem(ikon: Icons.assignment_outlined, label: 'Tugas'),
          AppBottomNavItem(ikon: Icons.person_outline, label: 'Profil'),
        ],
      ),
    );
  }
}
