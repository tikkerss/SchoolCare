import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../data/rapor_models.dart';
import '../data/rapor_repository.dart';
import '../widgets/status_rapor_badge.dart';
import 'rapor_detail_page.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

class RaporListPage extends StatefulWidget {
  const RaporListPage({super.key, required this.repository});

  final RaporRepository repository;

  @override
  State<RaporListPage> createState() => _RaporListPageState();
}

class _RaporListPageState extends State<RaporListPage> {
  Kelas? _kelas;
  String _semester = '';
  List<RaporRingkas> _data = [];
  StatusRapor? _filter; // null = semua
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
      final kelas = await widget.repository.getKelasWali();
      if (kelas == null) {
        setState(() {
          _error = 'Akun ini tidak tercatat sebagai wali kelas.';
          _loading = false;
        });
        return;
      }
      final semester = await widget.repository.getSemesterAktif();
      final data = await widget.repository.getDaftarRapor(kelas.id);
      setState(() {
        _kelas = kelas;
        _semester = semester;
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rapor: $e';
        _loading = false;
      });
    }
  }

  Future<void> _buka(RaporRingkas r) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RaporDetailPage(repository: widget.repository, siswaId: r.siswa.id),
      ),
    );
    _muat(); // status bisa berubah setelah kembali dari detail
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapor')),
      body: LembarPutih(child: _buildBody()),
    );
  }

  Widget _buildBody() {
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

    int hitung(StatusRapor s) => _data.where((r) => r.status == s).length;
    final list = _filter == null
        ? _data
        : _data.where((r) => r.status == _filter).toList();

    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelas ${_kelas!.namaKelas}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Semester $_semester',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text('Semua (${_data.length})'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    for (final s in StatusRapor.values)
                      ChoiceChip(
                        label: Text('${s.label} (${hitung(s)})'),
                        selected: _filter == s,
                        side: BorderSide(color: warnaStatusRapor(s)),
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Tidak ada siswa dengan status ini.')),
            ),
          for (final r in list) ...[
            ListTile(
              title: Text(r.siswa.nama),
              subtitle: Text('NIS ${r.siswa.nis}'),
              trailing: StatusRaporBadge(r.status),
              onTap: () => _buka(r),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
