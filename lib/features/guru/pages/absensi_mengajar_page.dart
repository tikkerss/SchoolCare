import 'package:material_ui/material_ui.dart';
import '../models/jadwal.dart';
import 'absensi_hadir_page.dart';

class AbsensiMengajarPage extends StatelessWidget {
  final Jadwal jadwal;
  const AbsensiMengajarPage({super.key, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Absensi Mengajar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.mapel, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${jadwal.kelas} • ${jadwal.ruang}'),
                    Text('${jadwal.jamMulai} - ${jadwal.jamSelesai}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Apakah Anda hadir mengajar?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Hadir'),
              onPressed: () async {
                final berhasil = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => AbsensiHadirPage(jadwal: jadwal)),
                );
                if (berhasil == true && context.mounted) {
                  Navigator.pop(context, StatusKelas.berlangsung);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Tidak Hadir'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form tidak hadir (segera dibuat)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}