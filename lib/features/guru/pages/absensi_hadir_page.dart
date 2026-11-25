import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/widgets/bukti_foto_picker.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Alur Hadir: foto bukti (kamera + GPS + waktu) → berita acara → status kelas berlangsung.
class AbsensiHadirPage extends StatefulWidget {
  const AbsensiHadirPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  @override
  State<AbsensiHadirPage> createState() => _AbsensiHadirPageState();
}

class _AbsensiHadirPageState extends State<AbsensiHadirPage> {
  final _repo = GuruRepository();
  // Kalau sedang mengubah absensi Hadir, isi berita acara lama.
  late final _beritaAcara = TextEditingController(text: widget.jadwal.hadir ? widget.jadwal.beritaAcara : null);
  BuktiFoto? _bukti;
  bool _menyimpan = false;

  bool get _ubah => widget.jadwal.sudahDiabsen;

  @override
  void dispose() {
    _beritaAcara.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await _repo.absenHadir(jadwal: widget.jadwal, bukti: _bukti, beritaAcara: _beritaAcara.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ubah ? 'Perubahan absensi tersimpan.' : 'Absensi tersimpan. Status kelas: Berlangsung.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('AbsensiHadirPage: $e');
      if (mounted) {
        final pesan = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $pesan')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Saat mengubah, foto lama tetap dipakai kalau tidak diambil ulang.
    final bisaSimpan = (_bukti != null || _ubah) && _beritaAcara.text.trim().isNotEmpty && !_menyimpan;

    return Scaffold(
      appBar: AppBar(title: Text('${_ubah ? 'Ubah: ' : ''}Hadir • Kelas ${widget.jadwal.namaKelas}')),
      body: LembarPutih(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _Langkah(_ubah ? '1. Foto kegiatan kelas (ambil ulang bila perlu)' : '1. Foto kegiatan kelas (wajib)'),
            BuktiFotoPicker(bukti: _bukti, onBerubah: (b) => setState(() => _bukti = b)),
            const SizedBox(height: 24),
            const _Langkah('2. Berita acara'),
            TextField(
              controller: _beritaAcara,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Ringkasan materi atau kegiatan pembelajaran'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: bisaSimpan ? _simpan : null,
              child: _menyimpan
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_ubah ? 'Simpan Perubahan' : 'Simpan Absensi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Judul langkah form (Bold 15).
class _Langkah extends StatelessWidget {
  const _Langkah(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      teks,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}
