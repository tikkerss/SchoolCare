import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../data/rapor_models.dart';
import '../data/rapor_repository.dart';
import '../utils/format_tanggal.dart';
import '../widgets/status_rapor_badge.dart';

class RaporDetailPage extends StatefulWidget {
  const RaporDetailPage({
    super.key,
    required this.repository,
    required this.siswaId,
  });

  final RaporRepository repository;
  final String siswaId;

  @override
  State<RaporDetailPage> createState() => _RaporDetailPageState();
}

class _RaporDetailPageState extends State<RaporDetailPage> {
  RaporDetail? _rapor;
  final Map<String, TextEditingController> _nilaiCtrl = {};
  final _catatanCtrl = TextEditingController();
  bool _loading = true;
  bool _sibuk = false; // simpan / terbit / konfirmasi
  bool _mengunggah = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    for (final c in _nilaiCtrl.values) {
      c.dispose();
    }
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.repository.getRapor(widget.siswaId);
      for (final n in r.nilai) {
        _nilaiCtrl.putIfAbsent(n.mapelId, TextEditingController.new).text =
            n.nilaiAkhir == null ? '' : _format(n.nilaiAkhir!);
      }
      _catatanCtrl.text = r.catatanWali;
      setState(() {
        _rapor = r;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat rapor: $e';
        _loading = false;
      });
    }
  }

  String _format(double n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

  double? _parse(String teks) =>
      double.tryParse(teks.trim().replaceAll(',', '.'));

  bool get _terkunci =>
      _rapor!.status == StatusRapor.terbit ||
      _rapor!.status == StatusRapor.diambil;

  /// Pindahkan isi form ke objek rapor. Mengembalikan pesan error kalau ada.
  String? _sinkronkan() {
    final r = _rapor!;
    for (final n in r.nilai) {
      final teks = _nilaiCtrl[n.mapelId]!.text;
      if (teks.trim().isEmpty) {
        n.nilaiAkhir = null;
        continue;
      }
      final v = _parse(teks);
      if (v == null || v < 0 || v > 100) {
        return 'Nilai ${n.namaMapel} harus angka 0–100.';
      }
      n.nilaiAkhir = v;
    }
    r.catatanWali = _catatanCtrl.text.trim();
    return null;
  }

  void _snack(String teks) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));

  void _isiDariRataRata() {
    setState(() {
      for (final n in _rapor!.nilai) {
        if (n.rataRataGuru != null) {
          _nilaiCtrl[n.mapelId]!.text = _format(
            n.rataRataGuru!.roundToDouble(),
          );
        }
      }
    });
  }

  Future<void> _jalankan(Future<void> Function() aksi, String sukses) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
      if (mounted) _snack(sukses);
    } catch (e) {
      if (mounted) {
        _snack('Gagal: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _simpanDraft() async {
    final err = _sinkronkan();
    if (err != null) {
      _snack(err);
      return;
    }
    await _jalankan(
      () => widget.repository.simpanDraft(_rapor!),
      'Draft rapor disimpan',
    );
    setState(() {}); // perbarui badge status
  }

  Future<void> _pilihDanUnggahPdf() async {
    // file_picker v12+: pickFile() mengembalikan satu file, atau null kalau dibatalkan.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return; // dibatalkan

    setState(() => _mengunggah = true);
    try {
      final bytes = await file.readAsBytes();
      final path = await widget.repository.uploadPdf(
        widget.siswaId,
        file.name,
        bytes,
      );
      if (!mounted) return;
      setState(() => _rapor!.filePdf = path);
      _snack('PDF diunggah. Jangan lupa Simpan Draft.');
    } catch (e) {
      if (mounted) _snack('Gagal mengunggah: $e');
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  Future<bool> _konfirmasi(String judul, String isi, String tombol) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tombol),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _terbitkan() async {
    final err = _sinkronkan();
    if (err != null) {
      _snack(err);
      return;
    }
    if (!_rapor!.lengkap) {
      _snack('Lengkapi semua nilai dan unggah PDF dulu.');
      return;
    }
    final ok = await _konfirmasi(
      'Terbitkan rapor?',
      'Setelah terbit, nilai dan catatan tidak bisa diubah lagi. '
          'Orang tua baru bisa membuka rapor digital setelah pengambilan rapor fisik dikonfirmasi.',
      'Terbitkan',
    );
    if (!ok) return;
    await _jalankan(() async {
      await widget.repository.simpanDraft(_rapor!);
      await widget.repository.terbitkan(widget.siswaId);
      _rapor!.isPublished = true;
    }, 'Rapor diterbitkan');
  }

  Future<void> _konfirmasiAmbil() async {
    final ok = await _konfirmasi(
      'Konfirmasi pengambilan',
      'Pastikan orang tua/wali ${_rapor!.siswa.nama} sudah mengambil rapor fisik. '
          'Setelah ini, rapor digital langsung terbuka di aplikasi orang tua.',
      'Sudah diambil',
    );
    if (!ok) return;
    await _jalankan(() async {
      await widget.repository.konfirmasiPengambilan(widget.siswaId);
      _rapor!.diambilPada = DateTime.now();
    }, 'Pengambilan rapor dikonfirmasi');
  }

  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_rapor?.siswa.nama ?? 'Rapor')),
      body: _buildBody(),
      bottomNavigationBar: _rapor == null ? null : _tombolAksi(),
    );
  }

  Widget _buildBody() {
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

    final r = _rapor!;
    final judul = Theme.of(context).textTheme.titleSmall;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('NIS ${r.siswa.nis} • Semester ${r.semester}'),
            ),
            StatusRaporBadge(r.status),
          ],
        ),
        const SizedBox(height: 12),
        _banner(r),

        // ---------- Nilai ----------
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Nilai Akhir', style: judul)),
            if (!_terkunci)
              TextButton.icon(
                onPressed: _isiDariRataRata,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: const Text('Isi dari rata-rata guru'),
              ),
          ],
        ),
        Card(
          child: Column(children: [for (final n in r.nilai) _barisNilai(n)]),
        ),

        // ---------- Catatan ----------
        const SizedBox(height: 16),
        Text('Catatan Wali Kelas', style: judul),
        const SizedBox(height: 8),
        TextField(
          controller: _catatanCtrl,
          enabled: !_terkunci,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Contoh: Ananda aktif di kelas, tingkatkan ketelitian di Matematika.',
          ),
        ),

        // ---------- PDF ----------
        const SizedBox(height: 16),
        Text('File PDF Rapor', style: judul),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFD64545)),
            title: Text(
              r.filePdf == null ? 'Belum ada file' : r.filePdf!.split('/').last,
            ),
            subtitle: r.filePdf == null
                ? const Text('Wajib diunggah sebelum terbit')
                : null,
            trailing: _terkunci
                ? null
                : _mengunggah
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _pilihDanUnggahPdf,
                    child: Text(r.filePdf == null ? 'Unggah' : 'Ganti'),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _banner(RaporDetail r) {
    final (ikon, teks, warna) = switch (r.status) {
      StatusRapor.belumDisusun || StatusRapor.draft => (
        Icons.edit_note,
        'Lengkapi nilai, catatan, dan PDF, lalu terbitkan.',
        const Color(0xFFE0A100),
      ),
      StatusRapor.terbit => (
        Icons.lock_clock,
        'Rapor sudah terbit. Konfirmasi setelah orang tua mengambil rapor fisik '
            'agar rapor digital terbuka.',
        const Color(0xFF1E6FD9),
      ),
      StatusRapor.diambil => (
        Icons.verified,
        'Rapor fisik diambil ${formatTanggal(r.diambilPada!)}, ${formatJam(r.diambilPada!)}. '
            'Rapor digital sudah terbuka untuk orang tua.',
        const Color(0xFF2E9E5B),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warna.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(ikon, color: warna),
          const SizedBox(width: 12),
          Expanded(child: Text(teks)),
        ],
      ),
    );
  }

  Widget _barisNilai(NilaiMapel n) {
    final v = _parse(_nilaiCtrl[n.mapelId]!.text);
    final predikat = (v != null && v >= 0 && v <= 100) ? predikatDari(v) : '–';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.namaMapel),
                if (n.rataRataGuru != null)
                  Text(
                    'Rata-rata guru: ${n.rataRataGuru!.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _nilaiCtrl[n.mapelId],
              enabled: !_terkunci,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: '0–100',
              ),
              onChanged: (_) => setState(() {}), // perbarui predikat
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              predikat,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _tombolAksi() {
    final status = _rapor!.status;
    if (status == StatusRapor.diambil) return null;

    final loading = const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: status == StatusRapor.terbit
            ? FilledButton.icon(
                onPressed: _sibuk ? null : _konfirmasiAmbil,
                icon: _sibuk ? loading : const Icon(Icons.how_to_reg),
                label: const Text('Konfirmasi Rapor Fisik Diambil'),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sibuk || _mengunggah ? null : _simpanDraft,
                      child: const Text('Simpan Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _sibuk || _mengunggah ? null : _terbitkan,
                      child: _sibuk ? loading : const Text('Terbitkan'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
