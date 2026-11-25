import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart' show StatusPill;

import '../data/models.dart';
import 'status_selector.dart';

/// Label status kecil berwarna, misal [Sakit].
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final StatusAbsen status;

  @override
  Widget build(BuildContext context) => StatusPill(label: status.label, gaya: gayaStatus(status));
}

/// Deretan angka H / T / I / S / A, dipakai di rekap.
class RingkasanStatus extends StatelessWidget {
  const RingkasanStatus({super.key, required this.jumlah});

  final Map<StatusAbsen, int> jumlah;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: StatusAbsen.values.map((s) {
        return StatusPill(label: '${s.label}: ${jumlah[s] ?? 0}', gaya: gayaStatus(s));
      }).toList(),
    );
  }
}

/// Warna persentase kehadiran: >= 90 pink, >= 80 orange, di bawahnya ink.
/// (softYellow/softPink terlalu pucat untuk teks di atas putih.)
Color warnaPersen(double p) {
  if (p >= 90) return AppColors.pink;
  if (p >= 80) return AppColors.orange;
  return AppColors.ink;
}
