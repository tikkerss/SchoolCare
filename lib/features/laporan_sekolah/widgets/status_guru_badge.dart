import 'package:material_ui/material_ui.dart';

import '../data/laporan_models.dart';

const _hijau = Color(0xFF2E9E5B);
const _biru = Color(0xFF1E6FD9);
const _merah = Color(0xFFD64545);
const _abu = Color(0xFF8A8A8A);

/// Warna + label gabungan kehadiran guru dan status kelas.
(Color, String) infoStatusGuru(AbsensiGuruItem a) =>
    switch ((a.status, a.statusKelas)) {
      (StatusKehadiranGuru.hadir, _) => (_hijau, 'Hadir'),
      (StatusKehadiranGuru.tidakHadir, StatusKelas.digantikan) => (
        _biru,
        'Digantikan',
      ),
      (StatusKehadiranGuru.tidakHadir, _) => (_merah, 'Dibatalkan'),
      (StatusKehadiranGuru.belumAbsen, _) => (_abu, 'Belum absen'),
    };

class StatusGuruBadge extends StatelessWidget {
  const StatusGuruBadge(this.item, {super.key});

  final AbsensiGuruItem item;

  @override
  Widget build(BuildContext context) {
    final (warna, label) = infoStatusGuru(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warna,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
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
        TextButton(
          onPressed: onTapLabel,
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onBerikutnya,
        ),
      ],
    );
  }
}
