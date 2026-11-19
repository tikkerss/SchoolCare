import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/shared/data/info_models.dart';
import 'package:schoolcare/shared/data/info_repository.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Jadwal pelajaran satu kelas, satu tab per hari. Tab hari ini otomatis terbuka.
class JadwalKelasPage extends StatefulWidget {
  const JadwalKelasPage({super.key, required this.kelasId});

  final String kelasId;

  @override
  State<JadwalKelasPage> createState() => _JadwalKelasPageState();
}

class _JadwalKelasPageState extends State<JadwalKelasPage> {
  static const _hari = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];
  final _repo = InfoRepository();
  late Future<List<JadwalItem>> _future = _repo.getJadwalKelas(widget.kelasId);

  void _reload() => setState(() => _future = _repo.getJadwalKelas(widget.kelasId));

  @override
  Widget build(BuildContext context) {
    final indexHariIni = (DateTime.now().weekday - 1).clamp(0, 5);
    return DefaultTabController(
      length: _hari.length,
      initialIndex: indexHariIni,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jadwal Pelajaran'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final h in _hari) Tab(text: h[0].toUpperCase() + h.substring(1))],
          ),
        ),
        body: AsyncView<List<JadwalItem>>(
          future: _future,
          onRetry: _reload,
          builder: (context, list) => TabBarView(children: [
            for (final h in _hari) _listHari(list.where((j) => j.hari == h).toList()),
          ]),
        ),
      ),
    );
  }

  Widget _listHari(List<JadwalItem> items) {
    if (items.isEmpty) return const EmptyState(message: 'Tidak ada pelajaran.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final j = items[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${j.jamKe}')),
            title: Text(j.mapel),
            subtitle: Text([
              '${Fmt.jam(j.jamMulai)}–${Fmt.jam(j.jamSelesai)}',
              j.guru,
              if (j.ruang != null) j.ruang!,
            ].join(' · ')),
          ),
        );
      },
    );
  }
}
