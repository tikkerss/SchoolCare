import 'package:material_ui/material_ui.dart';

import '../../wali_kelas/data/rapor_models.dart';
import '../../wali_kelas/widgets/status_rapor_badge.dart';
import '../data/laporan_models.dart';
import '../data/laporan_repository.dart';

class PantauRaporPage extends StatefulWidget {
  const PantauRaporPage({super.key, required this.repository});

  final LaporanRepository repository;

  @override
  State<PantauRaporPage> createState() => _PantauRaporPageState();
}

class _PantauRaporPageState extends State<PantauRaporPage> {
  List<RaporKelas> _data = [];
  bool _hanyaBelumSelesai = false;
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
      final data = await widget.repository.getStatusRapor();
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat status rapor: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantau Rapor')),
      body: _isi(),
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
    if (_data.isEmpty) {
      return const Center(child: Text('Belum ada data kelas.'));
    }

    final totalSiswa = _data.fold(0, (s, k) => s + k.siswa.length);
    final totalSelesai = _data.fold(0, (s, k) => s + k.selesai);
    int totalStatus(StatusRapor st) => _data.fold(0, (s, k) => s + k.jml(st));

    final list = _hanyaBelumSelesai
        ? _data.where((k) => k.progres < 1).toList()
        : _data;

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
                      'Semester ${_data.first.semester}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text('$totalSelesai dari $totalSiswa rapor sudah terbit'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalSiswa == 0 ? 0 : totalSelesai / totalSiswa,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    _JumlahPerStatus(hitung: totalStatus),
                  ],
                ),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Hanya kelas yang belum selesai'),
            value: _hanyaBelumSelesai,
            onChanged: (v) => setState(() => _hanyaBelumSelesai = v),
          ),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Semua kelas sudah selesai.')),
            ),
          for (final k in list)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _DetailRaporKelasPage(data: k),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kelas ${k.kelas.namaKelas}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${k.selesai}/${k.siswa.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Wali: ${k.waliKelas}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: k.progres,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                        color: k.progres == 1 ? const Color(0xFF2E9E5B) : null,
                      ),
                      const SizedBox(height: 8),
                      _JumlahPerStatus(hitung: k.jml),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JumlahPerStatus extends StatelessWidget {
  const _JumlahPerStatus({required this.hitung});

  final int Function(StatusRapor) hitung;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final s in StatusRapor.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: warnaStatusRapor(s)),
              const SizedBox(width: 4),
              Text(
                '${s.label}: ${hitung(s)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
      ],
    );
  }
}

class _DetailRaporKelasPage extends StatelessWidget {
  const _DetailRaporKelasPage({required this.data});

  final RaporKelas data;

  @override
  Widget build(BuildContext context) {
    // Urutkan: belum disusun dulu (yang perlu ditindaklanjuti), lalu draft, terbit, diambil.
    final list = [...data.siswa]
      ..sort((a, b) => a.status.index.compareTo(b.status.index));
    return Scaffold(
      appBar: AppBar(title: Text('Rapor ${data.kelas.namaKelas}')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Wali kelas: ${data.waliKelas}'),
            subtitle: Text(
              '${data.selesai} dari ${data.siswa.length} rapor sudah terbit',
            ),
          ),
          const Divider(height: 1),
          for (final r in list) ...[
            ListTile(
              title: Text(r.siswa.nama),
              subtitle: Text('NIS ${r.siswa.nis}'),
              trailing: StatusRaporBadge(r.status),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
