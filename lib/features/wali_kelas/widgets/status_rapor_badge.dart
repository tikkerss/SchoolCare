import 'package:material_ui/material_ui.dart';

import '../data/rapor_models.dart';

Color warnaStatusRapor(StatusRapor s) => switch (s) {
  StatusRapor.belumDisusun => const Color(0xFF8A8A8A),
  StatusRapor.draft => const Color(0xFFE0A100),
  StatusRapor.terbit => const Color(0xFF1E6FD9),
  StatusRapor.diambil => const Color(0xFF2E9E5B),
};

class StatusRaporBadge extends StatelessWidget {
  const StatusRaporBadge(this.status, {super.key});

  final StatusRapor status;

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatusRapor(status);
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
