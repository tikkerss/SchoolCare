import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/pages/absensi_hadir_page.dart';
import 'package:schoolcare/features/guru/pages/absensi_tidak_hadir_page.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

/// Langkah pertama absensi mengajar: guru memilih Hadir atau Tidak Hadir.
/// Kembali ke halaman sebelumnya dengan `true` kalau absensi tersimpan.
class AbsensiMengajarPage extends StatelessWidget {
  const AbsensiMengajarPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  Future<void> _lanjut(BuildContext context, Widget halaman) async {
    final selesai = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => halaman));
    if (selesai == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(jadwal.sudahDiabsen ? 'Ubah Absensi' : 'Absensi Mengajar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jadwal.mapel, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Kelas ${jadwal.namaKelas} • ${jadwal.ruang ?? '-'}'),
                  Text('Jam ke-${jadwal.jamKe} • ${jadwal.rentangJam}'),
                  if (jadwal.sudahDiabsen) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Text('Status sekarang: '),
                      StatusBadge(jadwal.statusKelas),
                    ]),
                    if (jadwal.infoWaktu.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(jadwal.infoWaktu, style: theme.textTheme.bodySmall),
                      ),
                  ],
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
            onPressed: () => _lanjut(context, AbsensiHadirPage(jadwal: jadwal)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Tidak Hadir'),
            onPressed: () => _lanjut(context, AbsensiTidakHadirPage(jadwal: jadwal)),
          ),
        ],
      ),
    );
  }
}
