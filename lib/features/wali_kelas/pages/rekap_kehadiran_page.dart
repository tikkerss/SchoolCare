import 'package:material_ui/material_ui.dart';

import '../data/absensi_repository.dart';
import '../data/models.dart';
import '../utils/format_tanggal.dart';
import '../widgets/status_badge.dart';
import 'detail_siswa_page.dart';

enum _Urutan { nama, kehadiranTerendah }

class RekapKehadiranPage extends StatefulWidget {
  const RekapKehadiranPage({super.key, required this.repository});

  final AbsensiRepository repository;

  @override
  State<RekapKehadiranPage> createState() => _RekapKehadiranPageState();
}

class _RekapKehadiranPageState extends State<RekapKehadiranPage> {
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  _Urutan _urutan = _Urutan.nama;
  Kelas? _kelas;
  List<RekapSiswa> _rekap = [];
  bool _loading = true;
  String? _error;

  bool get _bulanIni {
    final now = DateTime.now();
    return _bulan.year == now.year && _bulan.month == now.month;
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
      final kelas = _kelas ?? await widget.repository.getKelasWali();
      if (kelas == null) {
        setState(() {
          _error = 'Akun ini tidak tercatat sebagai wali kelas.';
          _loading = false;
        });
        return;
      }
      final rekap = await widget.repository.getRekapBulanan(kelas.id, _bulan);
      setState(() {
        _kelas = kelas;
        _rekap = rekap;
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

  List<RekapSiswa> get _rekapUrut {
    final list = [..._rekap];
    if (_urutan == _Urutan.nama) {
      list.sort((a, b) => a.siswa.nama.compareTo(b.siswa.nama));
    } else {
      list.sort((a, b) => a.persenHadir.compareTo(b.persenHadir));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Kehadiran'),
        actions: [
          PopupMenuButton<_Urutan>(
            tooltip: 'Urutkan',
            icon: const Icon(Icons.sort),
            initialValue: _urutan,
            onSelected: (u) => setState(() => _urutan = u),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Urutan.nama, child: Text('Urut nama')),
              PopupMenuItem(
                value: _Urutan.kehadiranTerendah,
                child: Text('Kehadiran terendah dulu'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _PemilihBulan(
            bulan: _bulan,
            onSebelumnya: () => _gantiBulan(-1),
            onBerikutnya: _bulanIni ? null : () => _gantiBulan(1),
          ),
          const Divider(height: 1),
          Expanded(child: _buildIsi()),
        ],
      ),
    );
  }

  Widget _buildIsi() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_rekap.isEmpty || _rekap.first.totalHari == 0) {
      return const Center(child: Text('Belum ada data absensi di bulan ini.'));
    }

    // Total satu kelas
    final totalKelas = <StatusAbsen, int>{
      for (final s in StatusAbsen.values)
        s: _rekap.fold(0, (sum, r) => sum + r.jml(s)),
    };
    final rataRata =
        _rekap.fold<double>(0, (sum, r) => sum + r.persenHadir) / _rekap.length;

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
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
                      'Kelas ${_kelas!.namaKelas}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rata-rata kehadiran ${rataRata.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: warnaPersen(rataRata),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RingkasanStatus(jumlah: totalKelas),
                  ],
                ),
              ),
            ),
          ),
          for (final r in _rekapUrut) ...[
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailSiswaPage(
                    repository: widget.repository,
                    rekap: r,
                    bulan: _bulan,
                  ),
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

class _PemilihBulan extends StatelessWidget {
  const _PemilihBulan({
    required this.bulan,
    required this.onSebelumnya,
    required this.onBerikutnya,
  });

  final DateTime bulan;
  final VoidCallback onSebelumnya;
  final VoidCallback? onBerikutnya; // null = tombol nonaktif

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onSebelumnya,
        ),
        Text(
          formatBulan(bulan),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onBerikutnya,
        ),
      ],
    );
  }
}
