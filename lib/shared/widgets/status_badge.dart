import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/dashed.dart';

/// Gaya chip status (bagian 3 panduan desain).
enum GayaChip {
  pink(AppColors.pink, AppColors.white),
  orange(AppColors.orange, AppColors.white),
  softYellow(AppColors.softYellow, AppColors.black),
  softPink(AppColors.softPink, AppColors.black),
  putih(AppColors.white, AppColors.ink),

  /// Putih + garis putus-putus pink, teks pink (Alpa).
  putus(AppColors.white, AppColors.pink),

  /// softYellow + garis putus-putus pink, teks pink (kelas Dibatalkan).
  putusKuning(AppColors.softYellow, AppColors.pink);

  const GayaChip(this.latar, this.teks);
  final Color latar;
  final Color teks;

  /// Warna tunggal yang mewakili gaya ini (untuk titik/garis tepi).
  Color get aksen => switch (this) {
        GayaChip.putih => AppColors.softPink,
        GayaChip.putus || GayaChip.putusKuning => AppColors.pink,
        _ => latar,
      };
}

/// Chip status dasar: radius 8, teks Bold 11. Dipakai semua badge status.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.gaya});

  final String label;
  final GayaChip gaya;

  @override
  Widget build(BuildContext context) {
    final teks = Text(
      label,
      style: TextStyle(color: gaya.teks, fontWeight: FontWeight.w700, fontSize: 11, height: 1.3),
    );
    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
    if (gaya == GayaChip.putus || gaya == GayaChip.putusKuning) {
      return DecoratedBox(
        decoration: BoxDecoration(color: gaya.latar, borderRadius: BorderRadius.circular(8)),
        child: DashedOutline(
          color: AppColors.pink,
          child: Padding(padding: padding, child: teks),
        ),
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gaya.latar,
        borderRadius: BorderRadius.circular(8),
        border: gaya == GayaChip.putih ? Border.all(color: AppColors.softPink) : null,
      ),
      child: teks,
    );
  }
}

/// Badge berwarna untuk status absensi siswa dan status kelas.
/// Isi dengan nilai mentah dari database, contoh: `StatusBadge('sakit')`.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  static const _map = <String, (String, GayaChip)>{
    // absensi siswa
    'hadir': ('Hadir', GayaChip.pink),
    'terlambat': ('Terlambat', GayaChip.orange),
    'izin': ('Izin', GayaChip.softYellow),
    'sakit': ('Sakit', GayaChip.softPink),
    'alpa': ('Alpa', GayaChip.putus),
    // status kelas
    'terjadwal': ('Terjadwal', GayaChip.softYellow),
    'berlangsung': ('Berlangsung', GayaChip.pink),
    'digantikan': ('Digantikan', GayaChip.orange),
    'dibatalkan': ('Dibatalkan', GayaChip.putusKuning),
    'selesai': ('Selesai', GayaChip.softYellow),
    'dijadwalkan_ulang': ('Dijadwal ulang', GayaChip.orange),
    'kosong': ('Kosong', GayaChip.putus),
    'kegiatan': ('Kegiatan', GayaChip.softYellow),
  };

  static String labelOf(String status) => _map[status]?.$1 ?? status;

  static GayaChip gayaOf(String status) => _map[status]?.$2 ?? GayaChip.putih;

  @override
  Widget build(BuildContext context) => StatusPill(label: labelOf(status), gaya: gayaOf(status));
}
