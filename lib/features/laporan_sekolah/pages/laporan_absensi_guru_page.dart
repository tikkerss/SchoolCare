import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

import '../../wali_kelas/utils/format_tanggal.dart';
import '../../wali_kelas/widgets/status_badge.dart' show warnaPersen;
import '../data/laporan_models.dart';
import '../data/laporan_repository.dart';
import '../widgets/status_guru_badge.dart';
import 'detail_absensi_guru_page.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

enum _Filter { semua, hadir, digantikan, dibatalkan, belum, luarArea }

class LaporanAbsensiGuruPage extends StatefulWidget {
  const LaporanAbsensiGuruPage({super.key, required this.repository});

  final LaporanRepository repository;

  @override
  State<LaporanAbsensiGuruPage> createState() => _LaporanAbsensiGuruPageState();
}

class _LaporanAbsensiGuruPageState extends State<LaporanAbsensiGuruPage> {
  DateTime _tanggal = _hariIni();
  _Filter _filter = _Filter.semua;
  List<AbsensiGuruItem> _harian = [];
  List<RekapGuru> _rekap = [];
  bool _loading = true;
  String? _error;

  static DateTime _hariIni() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
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
      final hasil = await Future.wait([
        widget.repository.getAbsensiGuruHarian(_tanggal),
        widget.repository.getRekapGuruBulanan(
          DateTime(_tanggal.year, _tanggal.month),
        ),
      ]);
      setState(() {
        _harian = hasil[0] as List<AbsensiGuruItem>;
        _rekap = hasil[1] as List<RekapGuru>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat laporan: $e';
        _loading = false;
      });
    }
  }

  void _gantiTanggal(DateTime t) {
    setState(() => _tanggal = t);
    _muat();
  }

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2025),
      lastDate: _hariIni(),
    );
    if (t != null) _gantiTanggal(t);
  }

  bool _cocok(AbsensiGuruItem a, _Filter f) => switch (f) {
    _Filter.semua => true,
    _Filter.hadir => a.status == StatusKehadiranGuru.hadir,
    _Filter.digantikan => a.statusKelas == StatusKelas.digantikan,
    _Filter.dibatalkan => a.statusKelas == StatusKelas.dibatalkan,
    _Filter.belum => a.status == StatusKehadiranGuru.belumAbsen,
    _Filter.luarArea => a.diLuarArea,
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Absensi Guru'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Per Guru (bulan)'),
            ],
          ),
        ),
        body: LembarPutih(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _muat,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            : TabBarView(children: [_tabHarian(), _tabPerGuru()])),
      ),
    );
  }

  // ---------------- Tab Harian ----------------

  Widget _tabHarian() {
    final hariIni = _tanggal == _hariIni();
    int hitung(_Filter f) => _harian.where((a) => _cocok(a, f)).length;

    final list = _harian.where((a) => _cocok(a, _filter)).toList()
      ..sort((a, b) {
        final c = a.kelas.compareTo(b.kelas);
        return c != 0 ? c : a.jamKe.compareTo(b.jamKe);
      });

    const label = {
      _Filter.semua: 'Semua',
      _Filter.hadir: 'Hadir',
      _Filter.digantikan: 'Digantikan',
      _Filter.dibatalkan: 'Dibatalkan',
      _Filter.belum: 'Belum absen',
      _Filter.luarArea: 'Di luar area',
    };

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        children: [
          PemilihPeriode(
            label: formatTanggal(_tanggal),
            onTapLabel: _pilihTanggal,
            onSebelumnya: () =>
                _gantiTanggal(_tanggal.subtract(const Duration(days: 1))),
            onBerikutnya: hariIni
                ? null
                : () => _gantiTanggal(_tanggal.add(const Duration(days: 1))),
          ),
          if (_harian.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Tidak ada jadwal pelajaran di tanggal ini.'),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in _Filter.values)
                    ChoiceChip(
                      label: Text('${label[f]} (${hitung(f)})'),
                      selected: _filter == f,
                      avatar: f == _Filter.luarArea
                          ? const Icon(
                              Icons.location_off,
                              size: 16,
                              color: AppColors.pink,
                            )
                          : null,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
            ),
            const Divider(),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Tidak ada data untuk filter ini.')),
              ),
            for (final a in list) ...[
              ListTile(
                leading: CircleAvatar(child: Text('${a.jamKe}')),
                title: Text('${a.mapel} • ${a.kelas}'),
                // Badge status ditaruh di bawah teks (bukan trailing) supaya tidak
                // overflow ke kanan di layar sempit / teks diperbesar.
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.guru}'
                      '${a.guruPengganti != null ? ' → ${a.guruPengganti}' : ''}'
                      '  •  ${formatJam(a.jamMulai)}',
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusGuruBadge(a),
                        if (a.diLuarArea)
                          const Tooltip(
                            message: 'Foto diambil di luar area sekolah',
                            child: Icon(
                              Icons.location_off,
                              color: AppColors.pink,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                onTap: a.status == StatusKehadiranGuru.belumAbsen
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailAbsensiGuruPage(item: a),
                        ),
                      ),
              ),
              const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------- Tab Per Guru ----------------

  Widget _tabPerGuru() {
    final list = [..._rekap]
      ..sort((a, b) => a.persenHadir.compareTo(b.persenHadir));
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Rekap ${formatBulan(_tanggal)} (sampai hari ini), kehadiran terendah di atas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final r in list) ...[
          ListTile(
            title: Text(r.guru),
            subtitle: Text(
              '${r.mapel}\nHadir ${r.hadir}  ·  Tidak hadir ${r.tidakHadir}'
              '${r.diLuarArea > 0 ? '  ·  Di luar area ${r.diLuarArea}' : ''}',
            ),
            isThreeLine: true,
            trailing: Text(
              r.total == 0 ? '–' : '${r.persenHadir.toStringAsFixed(0)}%',
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
    );
  }
}
