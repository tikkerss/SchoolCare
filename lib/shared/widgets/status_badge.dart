import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Badge berwarna untuk status absensi siswa dan status kelas.
/// Isi dengan nilai mentah dari database, contoh: `StatusBadge('sakit')`.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  static const _map = <String, (String, Color)>{
    // absensi siswa
    'hadir': ('Hadir', AppColors.success),
    'terlambat': ('Terlambat', AppColors.warning),
    'izin': ('Izin', AppColors.info),
    'sakit': ('Sakit', AppColors.purple),
    'alpa': ('Alpa', AppColors.danger),
    // status kelas
    'terjadwal': ('Terjadwal', AppColors.textSecondary),
    'berlangsung': ('Berlangsung', AppColors.success),
    'digantikan': ('Digantikan', AppColors.warning),
    'dibatalkan': ('Dibatalkan', AppColors.danger),
    'dijadwalkan_ulang': ('Dijadwal ulang', AppColors.info),
    'kosong': ('Kosong', AppColors.danger),
    'kegiatan': ('Kegiatan', AppColors.purple),
  };

  static String labelOf(String status) => _map[status]?.$1 ?? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _map[status] ?? (status, AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
