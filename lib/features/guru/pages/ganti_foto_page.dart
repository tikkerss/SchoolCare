import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';
import 'package:schoolcare/features/guru/widgets/bukti_foto_picker.dart';

/// Mengganti foto bukti saja (beserta lokasi & waktunya).
/// Berita acara, status, dan data lain tidak berubah. Kembali dengan `true` kalau tersimpan.
class GantiFotoPage extends StatefulWidget {
  const GantiFotoPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  @override
  State<GantiFotoPage> createState() => _GantiFotoPageState();
}

class _GantiFotoPageState extends State<GantiFotoPage> {
  final _repo = GuruRepository();
  late final Future<String>? _fotoLama =
      widget.jadwal.fotoPath == null ? null : _repo.urlFoto(widget.jadwal.fotoPath!);
  BuktiFoto? _bukti;
  bool _menyimpan = false;

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await _repo.gantiFoto(widget.jadwal, _bukti!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto bukti diganti.')));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('GantiFotoPage: $e');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Foto Bukti')),
      body: LembarPutih(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
          _Langkah('${j.mapel} • Kelas ${j.namaKelas}'),
          Text('Jam ke-${j.jamKe} • ${j.rentangJam}', style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          if (_fotoLama != null && _bukti == null) ...[
            const SizedBox(height: 16),
            const _Langkah('Foto saat ini'),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<String>(
                future: _fotoLama,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const SizedBox(height: 80, child: Center(child: Text('Foto lama tidak bisa dimuat.')));
                  }
                  if (!snap.hasData) {
                    return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
                  }
                  return Image.network(
                    snap.data!,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const SizedBox(height: 80, child: Center(child: Text('Foto lama tidak bisa dimuat.'))),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          _Langkah(_bukti == null ? 'Foto baru' : 'Foto baru (akan menggantikan foto lama)'),
          BuktiFotoPicker(bukti: _bukti, onBerubah: (b) => setState(() => _bukti = b)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _bukti != null && !_menyimpan ? _simpan : null,
            child: _menyimpan
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Simpan Foto Baru'),
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
