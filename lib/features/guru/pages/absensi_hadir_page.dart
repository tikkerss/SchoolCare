import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import '../data/bukti_foto_service.dart';
import '../models/bukti_foto.dart';
import '../models/jadwal.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

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

  void _simpan() {
    // Nanti: upload foto ke Supabase Storage + simpan data absensi.
    Navigator.pop(context, true);
  }

  static const _label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final bisaSimpan = _bukti != null && _beritaAcara.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Hadir • ${widget.jadwal.kelas}')),
      body: LembarPutih(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text('1. Foto bukti kegiatan kelas', style: _label),
          const SizedBox(height: 8),
          if (_bukti != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_bukti!.file, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _Geotag(
                ikon: Icons.location_on_outlined,
                teks: '${_bukti!.latitude.toStringAsFixed(6)}, ${_bukti!.longitude.toStringAsFixed(6)}',
              ),
              _Geotag(ikon: Icons.schedule, teks: DateFormat('dd/MM/yyyy HH:mm').format(_bukti!.waktu)),
            ]),
            const SizedBox(height: 10),
          ] else ...[
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.softPink, width: 1.5),
              ),
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.photo_camera_outlined, size: 40, color: AppColors.pink),
                  SizedBox(height: 6),
                  Text('Belum ada foto', style: TextStyle(fontSize: 12, color: AppColors.inkFaint)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton.icon(
            icon: _memuat
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_camera_outlined),
            label: Text(_bukti == null ? 'Ambil Foto Bukti' : 'Ambil Ulang'),
            onPressed: _memuat ? null : _ambilFoto,
          ),
          const SizedBox(height: 24),
          const Text('2. Berita acara', style: _label),
          const SizedBox(height: 8),
          TextField(
            controller: _beritaAcara,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Ringkasan materi atau kegiatan pembelajaran'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: bisaSimpan ? _simpan : null,
            child: const Text('Kirim Absensi'),
          ),
        ],
      )),
    );
  }
}

/// Label geotag kecil di bawah foto bukti.
class _Geotag extends StatelessWidget {
  const _Geotag({required this.ikon, required this.teks});
  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 14, color: AppColors.ink),
          const SizedBox(width: 4),
          Text(teks, style: const TextStyle(fontSize: 11)),
        ]),
      );
}
