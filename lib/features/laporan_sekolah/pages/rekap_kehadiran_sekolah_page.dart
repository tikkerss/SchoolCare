import 'package:material_ui/material_ui.dart';

import '../../wali_kelas/data/models.dart';
import '../../wali_kelas/utils/format_tanggal.dart';
import '../../wali_kelas/widgets/status_badge.dart';
import '../data/laporan_models.dart';
import '../data/laporan_repository.dart';
import '../widgets/status_guru_badge.dart' show PemilihPeriode;

class RekapKehadiranSekolahPage extends StatefulWidget {
  const RekapKehadiranSekolahPage({super.key, required this.repository});

  final LaporanRepository repository;

  @override
  State<RekapKehadiranSekolahPage> createState() =>
      _RekapKehadiranSekolahPageState();
}

class _RekapKehadiranSekolahPageState extends State<RekapKehadiranSekolahPage> {
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  bool _terendahDulu = false;
  List<RekapKelas> _data = [];
  bool _loading = true;
  String? _error;

  bool get _bulanIni {
    final n = DateTime.now();
    return _bulan.year == n.year && _bulan.month == n.month;
  }

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
      final data = await widget.repository.getRekapKehadiranKelas(_bulan);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rekap: $e';
        _loading = false;
      });
    }
  }

  void _gantiBulan(int delta) {
    setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Kehadiran Siswa'),
        actions: [
          IconButton(
            tooltip: _terendahDulu
                ? 'Urut nama kelas'
                : 'Kehadiran terendah dulu',
            icon: Icon(
              _terendahDulu ? Icons.sort_by_alpha : Icons.trending_down,
            ),
            onPressed: () => setState(() => _terendahDulu = !_terendahDulu),
          ),
        ],
      ),
      body: Column(
        children: [
          PemilihPeriode(
            label: formatBulan(_bulan),
            onSebelumnya: () => _gantiBulan(-1),
            onBerikutnya: _bulanIni ? null : () => _gantiBulan(1),
          ),
          const Divider(height: 1),
          Expanded(child: _isi()),
        ],
      ),
    );
  }

  Widget _isi() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_data.isEmpty || _data.first.siswa.first.totalHari == 0) {
      return const Center(child: Text('Belum ada data absensi di bulan ini.'));
    }

    final semuaSiswa = [for (final k in _data) ...k.siswa];
    final rataSekolah =
        semuaSiswa.fold<double>(0, (s, r) => s + r.persenHadir) /
        semuaSiswa.length;
    final totalSekolah = <StatusAbsen, int>{
      for (final s in StatusAbsen.values)
        s: _data.fold(0, (sum, k) => sum + (k.total[s] ?? 0)),
    };
    final perluPerhatian = _data.fold(0, (s, k) => s + k.perluPerhatian);

    final list = [..._data]
      ..sort(
        (a, b) => _terendahDulu
            ? a.rataRata.compareTo(b.rataRata)
            : a.kelas.namaKelas.compareTo(b.kelas.namaKelas),
      );

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seluruh sekolah • ${_data.length} kelas • ${semuaSiswa.length} siswa',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rata-rata kehadiran ${rataSekolah.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: warnaPersen(rataSekolah),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (perluPerhatian > 0)
                      Text(
                        '$perluPerhatian siswa kehadirannya di bawah 80%',
                        style: const TextStyle(color: Color(0xFFD64545)),
                      ),
                    const SizedBox(height: 8),
                    RingkasanStatus(jumlah: totalSekolah),
                  ],
                ),
              ),
            ),
          ),
          for (final k in list)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text('Kelas ${k.kelas.namaKelas}'),
                subtitle: Text(
                  'Wali: ${k.waliKelas} • ${k.siswa.length} siswa'
                  '${k.perluPerhatian > 0 ? '\n${k.perluPerhatian} siswa < 80%' : ''}',
                ),
                isThreeLine: k.perluPerhatian > 0,
                trailing: Text(
                  '${k.rataRata.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: warnaPersen(k.rataRata),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _DetailKelasPage(rekap: k, bulan: _bulan),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailKelasPage extends StatelessWidget {
  const _DetailKelasPage({required this.rekap, required this.bulan});

  final RekapKelas rekap;
  final DateTime bulan;

  @override
  Widget build(BuildContext context) {
    final list = [...rekap.siswa]
      ..sort((a, b) => a.persenHadir.compareTo(b.persenHadir));
    return Scaffold(
      appBar: AppBar(title: Text('Kelas ${rekap.kelas.namaKelas}')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wali kelas: ${rekap.waliKelas} • ${formatBulan(bulan)}'),
                Text(
                  'Rata-rata ${rekap.rataRata.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: warnaPersen(rekap.rataRata),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RingkasanStatus(jumlah: rekap.total),
                const SizedBox(height: 8),
                Text(
                  'Kehadiran terendah di atas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final r in list) ...[
            ListTile(
              title: Text(r.siswa.nama),
              subtitle: Text(
                StatusAbsen.values
                    .map((s) => '${s.kode} ${r.jml(s)}')
                    .join('  ·  '),
              ),
              trailing: Text(
                '${r.persenHadir.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: warnaPersen(r.persenHadir),
                ),
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
