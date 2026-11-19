import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/pages/jadwal_detail_page.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

/// Daftar jam pelajaran yang diampu guru hari ini (dari Supabase).
/// Ketuk satu jam pelajaran untuk absensi mengajar, berita acara, dan daftar siswa.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _repo = GuruRepository();
  late Future<List<Jadwal>> _future = _repo.getJadwalHariIni();

  void _muatUlang() => setState(() => _future = _repo.getJadwalHariIni());

  /// Membuka detail jam pelajaran (absensi + daftar siswa). Jadwal dimuat ulang sesudahnya.
  Future<void> _buka(Jadwal j) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => JadwalDetailPage(jadwal: j)),
    );
    if (mounted) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jadwal Mengajar'),
            Text(Fmt.hari(DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _muatUlang();
          await _future;
        },
        child: AsyncView<List<Jadwal>>(
          future: _future,
          onRetry: _muatUlang,
          isEmpty: (list) => list.isEmpty,
          emptyMessage: 'Tidak ada jadwal mengajar hari ini.',
          emptyIcon: Icons.event_available_outlined,
          builder: (context, list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _JadwalCard(jadwal: list[i], onTap: () => _buka(list[i])),
          ),
        ),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  const _JadwalCard({required this.jadwal, required this.onTap});

  final Jadwal jadwal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text(Fmt.jam(jadwal.jamMulai), style: theme.textTheme.titleMedium),
                  Text(Fmt.jam(jadwal.jamSelesai), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.mapel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Kelas ${jadwal.namaKelas} • ${jadwal.ruang ?? '-'}'),
                    if (jadwal.guruPengganti != null)
                      Text('Pengganti: ${jadwal.guruPengganti}', style: theme.textTheme.bodySmall),
                    if (jadwal.pernahDiubah)
                      Text(
                        'Diubah ${Fmt.waktu(jadwal.diubahPada!)}',
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(jadwal.statusKelas),
            ],
          ),
        ),
      ),
    );
  }
}
