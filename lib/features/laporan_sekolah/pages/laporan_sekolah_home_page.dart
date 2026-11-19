import 'package:material_ui/material_ui.dart';

import '../data/laporan_repository.dart';
import 'laporan_absensi_guru_page.dart';
import 'pantau_rapor_page.dart';
import 'rekap_kehadiran_sekolah_page.dart';

/// Menu laporan untuk Pihak Sekolah. Di repo tim, halaman-halaman ini
/// dipasang ke navigasi Pihak Sekolah yang dibuat FE Fondasi / Backend.
class LaporanSekolahHomePage extends StatelessWidget {
  LaporanSekolahHomePage({super.key, LaporanRepository? repository})
    : repository = repository ?? DummyLaporanRepository();

  final LaporanRepository repository;

  @override
  Widget build(BuildContext context) {
    final menu = <(IconData, String, String, Widget Function())>[
      (
        Icons.badge_outlined,
        'Laporan Absensi Guru',
        'Foto bukti, lokasi, guru pengganti',
        () => LaporanAbsensiGuruPage(repository: repository),
      ),
      (
        Icons.groups_outlined,
        'Rekap Kehadiran Siswa',
        'Per kelas, per bulan',
        () => RekapKehadiranSekolahPage(repository: repository),
      ),
      (
        Icons.fact_check_outlined,
        'Pantau Rapor',
        'Progres rapor tiap kelas',
        () => PantauRaporPage(repository: repository),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Sekolah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (ikon, judul, sub, page) in menu)
            Card(
              child: ListTile(
                leading: Icon(ikon),
                title: Text(judul),
                subtitle: Text(sub),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
