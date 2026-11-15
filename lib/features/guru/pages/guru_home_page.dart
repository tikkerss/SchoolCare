// lib/features/guru/pages/guru_home_page.dart   ← nanti diisi FE Guru
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';

class GuruHomePage extends StatelessWidget {
  const GuruHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${auth.profile?.namaLengkap ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profil'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('TODO FE Guru: jadwal mengajar, absen, tugas, nilai'),
          const SizedBox(height: 16),
          if (auth.isWaliKelas)
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Menu Wali Kelas'),
                subtitle: const Text('Absensi pagi, rekap, rapor'),
                onTap: () => context.push('/wali'),
              ),
            ),
        ],
      ),
    );
  }
}
