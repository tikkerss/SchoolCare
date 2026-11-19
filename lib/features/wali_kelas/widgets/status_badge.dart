import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import 'status_selector.dart';

/// Label status kecil berwarna, misal [Sakit].
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final StatusAbsen status;

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: warna,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
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
        return Chip(
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: warnaStatus(s)),
          label: Text('${s.label}: ${jumlah[s] ?? 0}'),
        );
      }).toList(),
    );
  }
}

Color warnaPersen(double p) {
  if (p >= 90) return const Color(0xFF2E9E5B);
  if (p >= 80) return const Color(0xFFE0A100);
  return const Color(0xFFD64545);
}
