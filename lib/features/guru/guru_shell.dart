import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/features/guru/pages/jadwal_page.dart';
import 'package:schoolcare/features/guru/pages/tugas_page.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
