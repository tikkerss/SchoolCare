import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/shared/widgets/app_bottom_nav.dart';
import 'pages/jadwal_page.dart';

class GuruShell extends StatefulWidget {
  const GuruShell({super.key});

  @override
  State<GuruShell> createState() => _GuruShellState();
}

class _GuruShellState extends State<GuruShell> {
  int _index = 0;

  final _pages = const [
    JadwalPage(),
    Scaffold(body: Center(child: Text('Kelas', style: TextStyle(color: AppColors.white)))),
    Scaffold(body: Center(child: Text('Absen', style: TextStyle(color: AppColors.white)))),
    // Profil + tombol Keluar; guru wali kelas juga melihat tombol "Menu Wali Kelas" di sini.
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(ikon: Icons.calendar_today_outlined, label: 'Jadwal'),
          AppBottomNavItem(ikon: Icons.groups_outlined, label: 'Kelas'),
          AppBottomNavItem(ikon: Icons.how_to_reg_outlined, label: 'Absen'),
          AppBottomNavItem(ikon: Icons.person_outline, label: 'Profil'),
        ],
      ),
    );
  }
}
