import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';

class OrtuShellPage extends StatefulWidget {
  const OrtuShellPage({super.key});

  @override
  State<OrtuShellPage> createState() => _OrtuShellPageState();
}

class _OrtuShellPageState extends State<OrtuShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const Center(child: Text('Beranda')), // Fase 4 → BerandaTab
      const Center(child: Text('Kehadiran')), // Fase 4 → KehadiranTab
      const Center(child: Text('Akademik')), // Fase 4 → AkademikTab
      const ProfilPage(showAppBar: false),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Kehadiran'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Akademik'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
