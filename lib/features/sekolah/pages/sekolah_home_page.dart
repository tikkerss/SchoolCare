import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// SEMENTARA – nanti diisi Backend. Jangan ganti nama file/class.
class SekolahHomePage extends StatelessWidget {
  const SekolahHomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pihak Sekolah'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => context.push('/profil'),
        ),
      ],
    ),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('TODO: kelola akun, siswa, kelas, jadwal, agenda, pengumuman, laporan.'),
    ),
  );
}
