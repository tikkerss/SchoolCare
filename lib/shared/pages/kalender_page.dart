import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/shared/data/info_models.dart';
import 'package:schoolcare/shared/data/info_repository.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Kalender sekolah (semua peran). Tanggal yang punya agenda diberi titik penanda.
class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key, this.kelasId});

  /// Diisi dari halaman orang tua / wali supaya agenda khusus kelas ikut tampil.
  final String? kelasId;

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  final _repo = InfoRepository();
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  List<Agenda> _agenda = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _ambil(); // jangan panggil setState di initState
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    await _ambil();
  }

  Future<void> _ambil() async {
    try {
      final awal = DateTime(_focused.year, _focused.month, 1);
      final akhir = DateTime(_focused.year, _focused.month + 1, 0);
      _agenda = await _repo.getAgenda(awal, akhir, kelasId: widget.kelasId);
    } catch (e) {
      debugPrint('KalenderPage: $e');
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Agenda> _padaHari(DateTime d) => _agenda.where((a) => a.berlangsungPada(d)).toList();

  @override
  Widget build(BuildContext context) {
    final hariIni = _padaHari(_selected);
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Sekolah')),
      body: LembarPutih(child: Column(children: [
        TableCalendar<Agenda>(
          locale: 'id_ID',
          firstDay: DateTime(2025),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: _focused,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          selectedDayPredicate: (d) => isSameDay(d, _selected),
          eventLoader: _padaHari,
          onDaySelected: (s, f) => setState(() {
            _selected = s;
            _focused = f;
          }),
          onPageChanged: (f) {
            _focused = f;
            _load();
          },
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _error
              ? ErrorView(onRetry: _load)
              : hariIni.isEmpty
                  ? const EmptyState(
                      message: 'Tidak ada agenda di tanggal ini.',
                      icon: Icons.event_available,
                    )
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      for (final a in hariIni)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              leading: Icon(_ikon(a.kategori)),
                              title: Text(a.judul),
                              subtitle: Text([
                                Fmt.tanggal(a.mulai),
                                if (a.jamMulai != null) Fmt.jam(a.jamMulai!),
                                if (a.lokasi != null) a.lokasi!,
                              ].join(' · ')),
                              onTap: () => _detail(a),
                            ),
                          ),
                        ),
                    ]),
        ),
      ])),
    );
  }

  IconData _ikon(String kategori) => switch (kategori) {
        'ujian' => Icons.edit_document,
        'libur' => Icons.beach_access_outlined,
        'pembagian_rapor' => Icons.description_outlined,
        _ => Icons.event,
      };

  void _detail(Agenda a) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(a.judul, style: Theme.of(context).textTheme.titleLarge),
            if (a.deskripsi != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(a.deskripsi!)),
            const Divider(height: 24),
            _baris(
              Icons.calendar_today,
              'Tanggal',
              a.mulai == a.selesai
                  ? Fmt.hari(a.mulai)
                  : '${Fmt.tanggal(a.mulai)} – ${Fmt.tanggal(a.selesai)}',
            ),
            if (a.jamMulai != null) _baris(Icons.schedule, 'Jam', Fmt.jam(a.jamMulai!)),
            if (a.lokasi != null) _baris(Icons.place_outlined, 'Lokasi', a.lokasi!),
            if (a.pakaian != null) _baris(Icons.checkroom, 'Pakaian', a.pakaian!),
            if (a.perlengkapan != null) _baris(Icons.backpack_outlined, 'Perlengkapan', a.perlengkapan!),
            if (a.ketentuanLain != null) _baris(Icons.info_outline, 'Ketentuan lain', a.ketentuanLain!),
          ],
        ),
      );

  Widget _baris(IconData i, String label, String isi) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(i),
        title: Text(label),
        subtitle: Text(isi),
      );
}
