import 'package:material_ui/material_ui.dart';

import '../data/absensi_repository.dart';
import '../data/models.dart';
import '../utils/format_tanggal.dart';
import '../widgets/status_badge.dart';

class DetailSiswaPage extends StatefulWidget {
  const DetailSiswaPage({
    super.key,
    required this.repository,
    required this.rekap,
    required this.bulan,
  });

  final AbsensiRepository repository;
  final RekapSiswa rekap;
  final DateTime bulan;

  @override
  State<DetailSiswaPage> createState() => _DetailSiswaPageState();
}

class _DetailSiswaPageState extends State<DetailSiswaPage> {
  List<AbsensiHarian> _harian = [];
  List<RiwayatPerubahan> _riwayat = [];
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
      final id = widget.rekap.siswa.id;
      // Dua query jalan bersamaan.
      final hasil = await Future.wait([
        widget.repository.getAbsensiSiswa(id, widget.bulan),
        widget.repository.getRiwayatPerubahan(id, widget.bulan),
      ]);
      setState(() {
        _harian = hasil[0] as List<AbsensiHarian>;
        _riwayat = hasil[1] as List<RiwayatPerubahan>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rekap;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(r.siswa.nama),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Harian'),
              Tab(text: 'Riwayat Perubahan'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NIS ${r.siswa.nis}  •  ${formatBulan(widget.bulan)}  •  '
                    'Hadir ${r.persenHadir.toStringAsFixed(0)}%',
                    style: TextStyle(color: warnaPersen(r.persenHadir)),
                  ),
                  const SizedBox(height: 8),
                  RingkasanStatus(jumlah: r.jumlah),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
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
                  : TabBarView(children: [_tabHarian(), _tabRiwayat()]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabHarian() {
    if (_harian.isEmpty) {
      return const Center(child: Text('Belum ada data absensi.'));
    }
    return ListView.separated(
      itemCount: _harian.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final a = _harian[i];
        return ListTile(
          title: Text(formatTanggal(a.tanggal)),
          subtitle: a.keterangan == null ? null : Text(a.keterangan!),
          trailing: StatusBadge(a.status),
        );
      },
    );
  }

  Widget _tabRiwayat() {
    if (_riwayat.isEmpty) {
      return const Center(
        child: Text('Belum ada perubahan status di bulan ini.'),
      );
    }
    return ListView.separated(
      itemCount: _riwayat.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = _riwayat[i];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Row(
            children: [
              if (p.statusLama != null) ...[
                StatusBadge(p.statusLama!),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
              ],
              StatusBadge(p.statusBaru),
            ],
          ),
          subtitle: Text(
            'Absensi ${formatTanggalPendek(p.tanggal)}\n'
            'oleh ${p.diubahOleh} • ${formatTanggalPendek(p.waktu)}, ${formatJam(p.waktu)}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
