import 'package:material_ui/material_ui.dart';
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
    Scaffold(body: Center(child: Text('Kelas'))),
    Scaffold(body: Center(child: Text('Akademik'))),
    Scaffold(body: Center(child: Text('Profil'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Kelas'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Akademik'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}