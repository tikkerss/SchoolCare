import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/tugas_repository.dart';
import 'package:schoolcare/features/guru/models/tugas.dart';
import 'package:schoolcare/features/guru/pages/tugas_form_page.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Detail tugas + penilaian per siswa (mirip Google Classroom).
/// Nilai 0–100; kosongkan kolom untuk menghapus nilai.
class TugasDetailPage extends StatefulWidget {
  const TugasDetailPage({super.key, required this.tugas});

  final TugasGuru tugas;

  @override
  State<TugasDetailPage> createState() => _TugasDetailPageState();
}

class _TugasDetailPageState extends State<TugasDetailPage> {
  final _repo = TugasRepository();
  late TugasGuru _tugas = widget.tugas;

  List<NilaiSiswa>? _siswa; // null = sedang dimuat
  bool _gagal = false;
  final _kolom = <String, TextEditingController>{};
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _muatNilai();
  }

  @override
  void dispose() {
    for (final c in _kolom.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _muatNilai() async {
    setState(() {
      _siswa = null;
      _gagal = false;
    });
    try {
      final list = await _repo.getNilaiTugas(_tugas);
      if (!mounted) return;
      for (final c in _kolom.values) {
        c.dispose();
      }
      _kolom
        ..clear()
        ..addAll({for (final s in list) s.siswaId: TextEditingController(text: _teks(s.nilai))});
      setState(() => _siswa = list);
    } catch (e) {
      debugPrint('TugasDetailPage: $e');
      if (mounted) setState(() => _gagal = true);
    }
  }

  static String _teks(double? n) => n == null ? '' : (n == n.roundToDouble() ? n.toInt().toString() : n.toString());

  /// null = kolom kosong; NaN = isian tidak valid
  static double? _baca(String teks) {
    final t = teks.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    return (n == null || n < 0 || n > 100) ? double.nan : n;
  }

  int get _jumlahTerisi => _kolom.values.where((c) => c.text.trim().isNotEmpty).length;

  Future<void> _simpanNilai() async {
    final nilaiBaru = <String, double?>{};
    for (final e in _kolom.entries) {
      final n = _baca(e.value.text);
      if (n != null && n.isNaN) {
        final nama = _siswa!.firstWhere((s) => s.siswaId == e.key).nama;
        _pesan('Nilai $nama harus angka 0–100.');
        return;
      }
      nilaiBaru[e.key] = n;
    }

    setState(() => _menyimpan = true);
    try {
      await _repo.simpanNilai(_tugas, _siswa!, nilaiBaru);
      _pesan('Nilai tersimpan.');
      await _muatNilai();
    } catch (e) {
      debugPrint('TugasDetailPage simpanNilai: $e');
      _pesan('Gagal menyimpan nilai.');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Future<void> _ubah() async {
    final tersimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TugasFormPage(tugas: _tugas)),
    );
    if (tersimpan != true) return;
    try {
      final semua = await _repo.getTugasSaya();
      final baru = semua.where((t) => t.id == _tugas.id).firstOrNull;
      if (baru != null && mounted) {
        final kelasBerubah = baru.kelasId != _tugas.kelasId;
        setState(() => _tugas = baru);
        if (kelasBerubah) _muatNilai();
      }
    } catch (e) {
      debugPrint('TugasDetailPage: $e');
    }
  }

  Future<void> _hapus() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${_tugas.judul}" beserta semua nilainya akan dihapus. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await _repo.hapusTugas(_tugas.id);
      if (!mounted) return;
      _pesan('Tugas dihapus.');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('TugasDetailPage hapus: $e');
      _pesan('Gagal menghapus tugas.');
    }
  }

  void _pesan(String teks) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  @override
  Widget build(BuildContext context) {
    final t = _tugas;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(tooltip: 'Ubah tugas', icon: const Icon(Icons.edit_outlined), onPressed: _ubah),
          IconButton(tooltip: 'Hapus tugas', icon: const Icon(Icons.delete_outline), onPressed: _hapus),
        ],
      ),
      bottomNavigationBar: _siswa == null || _siswa!.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _menyimpan ? null : _simpanNilai,
                  child: _menyimpan
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan Nilai'),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.judul, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${t.mapel} • Kelas ${t.namaKelas}'),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.event_outlined, size: 18, color: t.lewat ? AppColors.danger : null),
            const SizedBox(width: 6),
            Text(
              'Deadline ${Fmt.waktu(t.tenggat)}${t.lewat ? ' (sudah lewat)' : ''}',
              style: TextStyle(color: t.lewat ? AppColors.danger : null),
            ),
          ]),
          if (t.deskripsi != null) ...[
            const SizedBox(height: 12),
            Text(t.deskripsi!),
          ],
          SectionHeader(_siswa == null ? 'Penilaian' : 'Penilaian ($_jumlahTerisi/${_siswa!.length} dinilai)'),
          if (_gagal)
            ErrorView(onRetry: _muatNilai)
          else if (_siswa == null)
            const Padding(padding: EdgeInsets.all(32), child: LoadingView())
          else if (_siswa!.isEmpty)
            const EmptyState(message: 'Belum ada siswa di kelas ini.')
          else ...[
            Text(
              'Isi nilai 0–100. Kosongkan kolom untuk menghapus nilai. Nilai langsung terlihat oleh orang tua.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                for (final s in _siswa!) ...[
                  ListTile(
                    title: Text(s.nama),
                    subtitle: Text('NIS ${s.nis}'),
                    trailing: SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _kolom[s.siswaId],
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '–',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  if (s != _siswa!.last) const Divider(height: 1),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
