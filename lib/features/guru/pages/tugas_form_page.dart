import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/tugas_repository.dart';
import 'package:schoolcare/features/guru/models/tugas.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Form tambah / ubah tugas. Kembali dengan `true` kalau tersimpan.
class TugasFormPage extends StatefulWidget {
  const TugasFormPage({super.key, this.tugas});

  /// null = tugas baru
  final TugasGuru? tugas;

  @override
  State<TugasFormPage> createState() => _TugasFormPageState();
}

class _TugasFormPageState extends State<TugasFormPage> {
  final _repo = TugasRepository();
  late final _judul = TextEditingController(text: widget.tugas?.judul);
  late final _deskripsi = TextEditingController(text: widget.tugas?.deskripsi);
  late Future<List<KelasMapel>> _pilihan = _muatPilihan();

  late String? _kunci = widget.tugas?.kelasMapel.kunci;
  late DateTime _tenggat = widget.tugas?.tenggat ?? _besokJam20();
  bool _menyimpan = false;

  bool get _ubah => widget.tugas != null;

  static DateTime _besokJam20() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + 1, 20);
  }

  Future<List<KelasMapel>> _muatPilihan() async {
    final list = await _repo.getKelasMapel();
    // saat mengubah, kelas/mapel tugas lama tetap ada di pilihan walau jadwalnya sudah berubah
    final lama = widget.tugas?.kelasMapel;
    if (lama != null && !list.any((k) => k.kunci == lama.kunci)) list.insert(0, lama);
    return list;
  }

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final sekarang = DateTime.now();
    final tgl = await showDatePicker(
      context: context,
      initialDate: _tenggat,
      firstDate: _tenggat.isBefore(sekarang) ? _tenggat : sekarang,
      lastDate: sekarang.add(const Duration(days: 365)),
    );
    if (tgl == null || !mounted) return;
    final jam = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_tenggat));
    setState(() {
      final j = jam ?? TimeOfDay.fromDateTime(_tenggat);
      _tenggat = DateTime(tgl.year, tgl.month, tgl.day, j.hour, j.minute);
    });
  }

  Future<void> _simpan(List<KelasMapel> pilihan) async {
    setState(() => _menyimpan = true);
    try {
      await _repo.simpanTugas(
        id: widget.tugas?.id,
        kelasMapel: pilihan.firstWhere((k) => k.kunci == _kunci),
        judul: _judul.text.trim(),
        deskripsi: _deskripsi.text.trim(),
        tenggat: _tenggat,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ubah ? 'Tugas diperbarui.' : 'Tugas ditambahkan.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('TugasFormPage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan tugas.')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ubah ? 'Ubah Tugas' : 'Tambah Tugas')),
      body: AsyncView<List<KelasMapel>>(
        future: _pilihan,
        onRetry: () => setState(() => _pilihan = _muatPilihan()),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Anda belum punya jadwal mengajar di semester ini, jadi belum bisa membuat tugas.',
        builder: (context, pilihan) {
          final bisaSimpan = _kunci != null && _judul.text.trim().isNotEmpty && !_menyimpan;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: pilihan.any((k) => k.kunci == _kunci) ? _kunci : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kelas & mata pelajaran', border: OutlineInputBorder()),
                items: [
                  for (final k in pilihan)
                    DropdownMenuItem(value: k.kunci, child: Text(k.label, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _kunci = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _judul,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Judul tugas', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deskripsi,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Petunjuk (opsional)',
                  hintText: 'Contoh: kerjakan buku paket hal. 25 no. 1–10',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Deadline'),
                subtitle: Text(Fmt.waktu(_tenggat)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pilihTanggal,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: bisaSimpan ? () => _simpan(pilihan) : null,
                child: _menyimpan
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_ubah ? 'Simpan Perubahan' : 'Tambah Tugas'),
              ),
            ],
          );
        },
      ),
    );
  }
}
