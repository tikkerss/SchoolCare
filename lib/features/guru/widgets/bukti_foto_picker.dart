import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/bukti_foto_service.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';
// Koordinat & radius sekolah dipakai bersama dengan laporan Pihak Sekolah, supaya hasilnya sama.
import 'package:schoolcare/features/laporan_sekolah/data/laporan_models.dart'
    show jarakMeter, lokasiSekolah, radiusSekolahMeter;

/// Pratinjau foto bukti + lokasi + waktu, dengan tombol ambil / ambil ulang.
/// Dipakai di alur Hadir dan Tidak Hadir.
class BuktiFotoPicker extends StatefulWidget {
  const BuktiFotoPicker({super.key, required this.bukti, required this.onBerubah});

  final BuktiFoto? bukti;
  final ValueChanged<BuktiFoto> onBerubah;

  @override
  State<BuktiFotoPicker> createState() => _BuktiFotoPickerState();
}

class _BuktiFotoPickerState extends State<BuktiFotoPicker> {
  bool _memuat = false;

  Future<void> _ambil() async {
    setState(() => _memuat = true);
    try {
      widget.onBerubah(await BuktiFotoService.ambil());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bukti = widget.bukti;
    final kecil = Theme.of(context).textTheme.bodySmall;
    final jarak = bukti == null
        ? null
        : jarakMeter(bukti.latitude, bukti.longitude, lokasiSekolah.lat, lokasiSekolah.lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bukti == null)
          Container(
            height: 160,
            decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_outlined, size: 40, color: AppColors.black),
                SizedBox(height: 6),
                Text(
                  'Belum ada foto',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ],
            ),
          ),
        if (bukti != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(bukti.file, height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.pink),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${bukti.latitude.toStringAsFixed(6)}, ${bukti.longitude.toStringAsFixed(6)} '
                  '(±${bukti.akurasiMeter.round()} m)',
                  style: kecil?.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 4),
              Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(bukti.waktu), style: kecil?.copyWith(fontSize: 11)),
            ],
          ),
          if (jarak != null && jarak > radiusSekolahMeter)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(14)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_off_outlined, size: 18, color: AppColors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi di luar area sekolah (± ${(jarak / 1000).toStringAsFixed(1)} km). '
                      'Absensi tetap bisa disimpan, tetapi akan ditandai di laporan sekolah.',
                      style: kecil?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: _memuat
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.photo_camera_outlined),
          label: Text(bukti == null ? 'Ambil Foto Bukti' : 'Ambil Ulang'),
          onPressed: _memuat ? null : _ambil,
        ),
      ],
    );
  }
}
