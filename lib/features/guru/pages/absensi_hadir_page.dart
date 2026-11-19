import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../data/bukti_foto_service.dart';
import '../data/guru_repository.dart';
import '../models/bukti_foto.dart';
import '../models/jadwal.dart';

class AbsensiHadirPage extends StatefulWidget {
  final Jadwal jadwal;
  const AbsensiHadirPage({super.key, required this.jadwal});

  @override
  State<AbsensiHadirPage> createState() => _AbsensiHadirPageState();
}

class _AbsensiHadirPageState extends State<AbsensiHadirPage> {
  final _beritaAcara = TextEditingController();
  BuktiFoto? _bukti;
  bool _memuat = false;

  @override
  void dispose() {
    _beritaAcara.dispose();
    super.dispose();
  }

  Future<void> _ambilFoto() async {
    setState(() => _memuat = true);
    try {
      final bukti = await BuktiFotoService.ambil();
      setState(() => _bukti = bukti);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  bool _menyimpan = false;

  /// Upload foto ke Storage + simpan baris absensi_guru.
  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await GuruRepository().simpanHadir(
        jadwalId: widget.jadwal.id,
        bukti: _bukti!,
        beritaAcara: _beritaAcara.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan absensi: $e')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisaSimpan = _bukti != null && _beritaAcara.text.trim().isNotEmpty && !_menyimpan;

    return Scaffold(
      appBar: AppBar(title: Text('Hadir • ${widget.jadwal.kelas}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Foto kegiatan kelas'),
          const SizedBox(height: 8),
          if (_bukti != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_bukti!.file, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text('Lokasi: ${_bukti!.latitude.toStringAsFixed(6)}, '
                '${_bukti!.longitude.toStringAsFixed(6)}'),
            Text('Waktu: ${DateFormat('dd/MM/yyyy HH:mm').format(_bukti!.waktu)}'),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            icon: _memuat
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_camera_outlined),
            label: Text(_bukti == null ? 'Ambil Foto Bukti' : 'Ambil Ulang'),
            onPressed: _memuat ? null : _ambilFoto,
          ),
          const SizedBox(height: 24),
          const Text('2. Berita acara'),
          const SizedBox(height: 8),
          TextField(
            controller: _beritaAcara,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ringkasan materi atau kegiatan pembelajaran',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: bisaSimpan ? _simpan : null,
            child: const Text('Simpan Absensi'),
          ),
        ],
      ),
    );
  }
}