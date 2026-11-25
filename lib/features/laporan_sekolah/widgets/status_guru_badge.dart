import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

import '../data/laporan_models.dart';

/// Gaya + label gabungan kehadiran guru dan status kelas.
(GayaChip, String) gayaStatusGuru(AbsensiGuruItem a) =>
    switch ((a.status, a.statusKelas)) {
      (StatusKehadiranGuru.hadir, _) => (GayaChip.pink, 'Hadir'),
      (StatusKehadiranGuru.tidakHadir, StatusKelas.digantikan) => (
        GayaChip.orange,
        'Digantikan',
      ),
      (StatusKehadiranGuru.tidakHadir, _) => (GayaChip.putusKuning, 'Dibatalkan'),
      (StatusKehadiranGuru.belumAbsen, _) => (GayaChip.putih, 'Belum absen'),
    };

/// Warna + label gabungan kehadiran guru dan status kelas.
(Color, String) infoStatusGuru(AbsensiGuruItem a) {
  final (gaya, label) = gayaStatusGuru(a);
  return (gaya.aksen, label);
}

class StatusGuruBadge extends StatelessWidget {
  const StatusGuruBadge(this.item, {super.key});

  final AbsensiGuruItem item;

  @override
  Widget build(BuildContext context) {
    final (gaya, label) = gayaStatusGuru(item);
    return StatusPill(label: label, gaya: gaya);
  }
}

/// Pemilih bulan ◀ November 2026 ▶ yang dipakai beberapa laporan.
class PemilihPeriode extends StatelessWidget {
  const PemilihPeriode({
    super.key,
    required this.label,
    required this.onSebelumnya,
    required this.onBerikutnya,
    this.onTapLabel,
  });

  final String label;
  final VoidCallback onSebelumnya;
  final VoidCallback? onBerikutnya; // null = nonaktif
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onSebelumnya,
        ),
        // Flexible + FittedBox: label tanggal panjang mengecil, tidak overflow.
        Flexible(
          child: TextButton(
            onPressed: onTapLabel,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onBerikutnya,
        ),
      ],
    );
  }
}
