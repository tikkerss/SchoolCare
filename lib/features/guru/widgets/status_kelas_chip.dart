import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

import '../models/jadwal.dart';

class StatusKelasChip extends StatelessWidget {
  final StatusKelas status;
  const StatusKelasChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final gaya = switch (status) {
      StatusKelas.belumAbsen => GayaChip.putih,
      StatusKelas.berlangsung => GayaChip.pink,
      StatusKelas.digantikan => GayaChip.orange,
      StatusKelas.dibatalkan => GayaChip.putus,
    };
    return StatusPill(label: status.label, gaya: gaya);
  }
}
