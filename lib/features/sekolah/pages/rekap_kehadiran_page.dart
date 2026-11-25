import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Rekap kehadiran siswa per kelas per bulan (hadir, terlambat, izin, sakit, alpa).
class RekapKehadiranPage extends StatefulWidget {
  const RekapKehadiranPage({super.key});

  @override
  State<RekapKehadiranPage> createState() => _RekapKehadiranPageState();
}

class _RekapKehadiranPageState extends State<RekapKehadiranPage> {
  final _repo = SekolahRepository();
  List<Kelas>? _kelas;
  String? _kelasId;
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  Future<List<RekapSiswa>>? _future;

  @override
  void initState() {
    super.initState();
    _awal();
  }

  Future<void> _awal() async {
    try {
      final ta = await _repo.getTahunAjaranAktif();
      final kelas = await _repo.getKelas(tahunAjaranId: ta?.id);
      if (!mounted) return;
      setState(() {
        _kelas = kelas;
        _kelasId = kelas.isEmpty ? null : kelas.first.id;
        _future = _kelasId == null ? null : _repo.getRekap(kelasId: _kelasId!, bulan: _bulan);
      });
    } catch (e) {
      if (mounted) AdminUi.snack(context, AdminUi.pesanError(e), error: true);
    }
  }

  void _muatUlang() => setState(() => _future = _repo.getRekap(kelasId: _kelasId!, bulan: _bulan));

  void _gantiBulan(int geser) {
    _bulan = DateTime(_bulan.year, _bulan.month + geser);
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final kelas = _kelas;
    final bulanIni = DateTime(DateTime.now().year, DateTime.now().month);

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kehadiran Siswa')),
      body: LembarPutih(child: kelas == null
          ? const LoadingView()
          : kelas.isEmpty
              ? const EmptyState(message: 'Belum ada kelas di tahun ajaran aktif.')
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _kelasId,
                      decoration: const InputDecoration(labelText: 'Kelas'),
                      items: [for (final k in kelas) DropdownMenuItem(value: k.id, child: Text('Kelas ${k.namaKelas}'))],
                      onChanged: (v) {
                        _kelasId = v;
                        _muatUlang();
                      },
                    ),
                  ),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _gantiBulan(-1)),
                    Expanded(child: Text(Fmt.bulan(_bulan), textAlign: TextAlign.center)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _bulan == bulanIni ? null : () => _gantiBulan(1),
                    ),
                  ]),
                  Expanded(
                    child: AsyncView<List<RekapSiswa>>(
                      future: _future!,
                      onRetry: _muatUlang,
                      isEmpty: (d) => d.isEmpty,
                      emptyMessage: 'Belum ada data absensi di bulan ini.',
                      builder: (context, list) => SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowColor: const WidgetStatePropertyAll(AppColors.softPink),
                            columns: const [
                              DataColumn(label: Text('Nama')),
                              DataColumn(label: Text('Hadir'), numeric: true),
                              DataColumn(label: Text('Terlambat'), numeric: true),
                              DataColumn(label: Text('Izin'), numeric: true),
                              DataColumn(label: Text('Sakit'), numeric: true),
                              DataColumn(label: Text('Alpa'), numeric: true),
                            ],
                            rows: [
                              for (final r in list)
                                DataRow(cells: [
                                  DataCell(Text(r.nama)),
                                  DataCell(Text('${r.hadir}')),
                                  DataCell(Text('${r.terlambat}')),
                                  DataCell(Text('${r.izin}')),
                                  DataCell(Text('${r.sakit}')),
                                  DataCell(Text('${r.alpa}',
                                      style: TextStyle(color: r.alpa > 0 ? AppColors.danger : null))),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ])),
    );
  }
}
