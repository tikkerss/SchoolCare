const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Senin, 13 November 2026
String formatTanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// Sen, 13 Nov
String formatTanggalPendek(DateTime d) =>
    '${_hari[d.weekday - 1].substring(0, 3)}, ${d.day} ${_bulan[d.month - 1].substring(0, 3)}';

/// November 2026
String formatBulan(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';

/// 07:15
String formatJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
