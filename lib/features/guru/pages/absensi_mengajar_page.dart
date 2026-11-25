import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/pages/absensi_hadir_page.dart';
import 'package:schoolcare/features/guru/pages/absensi_tidak_hadir_page.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.mapel,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelas ${jadwal.namaKelas} • ${jadwal.ruang ?? '-'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                Text(
                  'Jam ke-${jadwal.jamKe} • ${jadwal.rentangJam}',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                if (jadwal.sudahDiabsen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Status sekarang: ', style: TextStyle(fontSize: 13)),
                      StatusBadge(jadwal.statusKelas),
                    ],
                  ),
                  if (jadwal.infoWaktu.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(jadwal.infoWaktu, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Apakah Anda hadir mengajar?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Hadir'),
                  onPressed: () => _lanjut(context, AbsensiHadirPage(jadwal: jadwal)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Tidak Hadir'),
                  onPressed: () => _lanjut(context, AbsensiTidakHadirPage(jadwal: jadwal)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
