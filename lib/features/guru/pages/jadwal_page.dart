import 'package:material_ui/material_ui.dart';
<<<<<<< HEAD
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/pages/jadwal_detail_page.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
=======
import '../data/guru_repository.dart';
import '../models/jadwal.dart';
import '../widgets/status_kelas_chip.dart';
import 'absensi_mengajar_page.dart';
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b

/// Daftar jam pelajaran yang diampu guru hari ini (dari Supabase).
/// Ketuk satu jam pelajaran untuk absensi mengajar, berita acara, dan daftar siswa.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _repo = GuruRepository();
<<<<<<< HEAD
  late Future<List<Jadwal>> _future = _repo.getJadwalHariIni();
=======
  List<Jadwal> _jadwal = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getJadwalHariIni();
      if (mounted) setState(() => _jadwal = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat jadwal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b

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
<<<<<<< HEAD
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
=======
      appBar: AppBar(title: const Text('Jadwal Mengajar')),
      body: _isi(),
    );
  }

  Widget _isi() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (_jadwal.isEmpty) {
      return const Center(child: Text('Tidak ada jadwal mengajar hari ini.'));
    }
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jadwal.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _JadwalCard(
          jadwal: _jadwal[i],
          onTap: () => _bukaAbsensi(i),
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
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
