import 'package:material_ui/material_ui.dart';
import '../models/jadwal.dart';

class StatusKelasChip extends StatelessWidget {
  final StatusKelas status;
  const StatusKelasChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StatusKelas.belumAbsen => Colors.grey,
      StatusKelas.berlangsung => Colors.green,
      StatusKelas.digantikan => Colors.orange,
      StatusKelas.dibatalkan => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}