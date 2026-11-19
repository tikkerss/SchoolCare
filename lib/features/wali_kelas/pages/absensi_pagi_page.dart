import 'package:material_ui/material_ui.dart';

import '../data/absensi_repository.dart';
import '../data/models.dart';
import '../utils/format_tanggal.dart';
import '../widgets/status_selector.dart';

class AbsensiPagiPage extends StatefulWidget {
  const AbsensiPagiPage({super.key, required this.repository});

  final AbsensiRepository repository;

  @override
  State<AbsensiPagiPage> createState() => _AbsensiPagiPageState();
}

class _AbsensiPagiPageState extends State<AbsensiPagiPage> {
  final DateTime _tanggal = DateTime.now();
  Kelas? _kelas;
  List<BarisAbsensi> _baris = [];
  bool _loading = true;
  bool _menyimpan = false;
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
      final kelas = await widget.repository.getKelasWali();
      if (kelas == null) {
        setState(() {
          _error = 'Akun ini tidak tercatat sebagai wali kelas.';
          _loading = false;
        });
        return;
      }
      final baris = await widget.repository.getAbsensiHarian(
        kelas.id,
        _tanggal,
      );
      setState(() {
        _kelas = kelas;
        _baris = baris;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data: $e';
        _loading = false;
      });
    }
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await widget.repository.simpanAbsensi(_tanggal, _baris);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi pagi berhasil disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  void _tandaiSemuaHadir() {
    setState(() {
      for (final b in _baris) {
        if (!b.dariPengajuanIzin) b.status = StatusAbsen.hadir;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hariMinggu = _tanggal.weekday == DateTime.sunday;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Pagi'),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              tooltip: 'Tandai semua hadir',
              icon: const Icon(Icons.done_all),
              onPressed: _tandaiSemuaHadir,
            ),
        ],
      ),
      body: _buildBody(hariMinggu),
      bottomNavigationBar: _loading || _error != null || hariMinggu
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _menyimpan ? null : _simpan,
                  icon: _menyimpan
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Absensi'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(bool hariMinggu) {
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

    if (hariMinggu) {
      return const Center(child: Text('Hari Minggu, tidak ada absensi.'));
    }

    return Column(
      children: [
        _Ringkasan(kelas: _kelas!, tanggal: _tanggal, baris: _baris),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: _baris.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = _baris[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(b.siswa.nama),
                subtitle: Text(
                  b.dariPengajuanIzin
                      ? 'Izin dari orang tua • ${b.keterangan ?? ''}'
                      : 'NIS ${b.siswa.nis}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: StatusSelector(
                  value: b.status,
                  enabled: !b.dariPengajuanIzin,
                  onChanged: (s) => setState(() => b.status = s),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({
    required this.kelas,
    required this.tanggal,
    required this.baris,
  });

  final Kelas kelas;
  final DateTime tanggal;
  final List<BarisAbsensi> baris;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kelas ${kelas.namaKelas}', style: theme.textTheme.titleMedium),
          Text(formatTanggal(tanggal), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: StatusAbsen.values.map((s) {
              final jumlah = baris.where((b) => b.status == s).length;
              return Chip(
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: warnaStatus(s)),
                label: Text('${s.label}: $jumlah'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
