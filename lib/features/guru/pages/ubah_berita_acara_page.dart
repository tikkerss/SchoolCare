import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Mengubah berita acara saja, mis. dilengkapi di akhir pelajaran.
/// Foto, status, dan data lain tidak berubah. Kembali dengan `true` kalau tersimpan.
class UbahBeritaAcaraPage extends StatefulWidget {
  const UbahBeritaAcaraPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  @override
  State<UbahBeritaAcaraPage> createState() => _UbahBeritaAcaraPageState();
}

class _UbahBeritaAcaraPageState extends State<UbahBeritaAcaraPage> {
  final _repo = GuruRepository();
  late final _isi = TextEditingController(text: widget.jadwal.beritaAcara);
  bool _menyimpan = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await _repo.ubahBeritaAcara(widget.jadwal, _isi.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berita acara tersimpan.')));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('UbahBeritaAcaraPage: $e');
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
    final j = widget.jadwal;
    final berubah = _isi.text.trim() != (j.beritaAcara ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Berita Acara')),
      body: LembarPutih(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
          _Langkah('${j.mapel} • Kelas ${j.namaKelas}'),
          Text('Jam ke-${j.jamKe} • ${j.rentangJam}', style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _isi,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ringkasan materi, kegiatan pembelajaran, dan catatan kelas hari ini',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: berubah && !_menyimpan ? _simpan : null,
            child: _menyimpan
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan Berita Acara'),
          ),
          ],
        ),
      ),
    );
  }
}

/// Judul bagian (Bold 15), sama seperti di halaman absensi.
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
