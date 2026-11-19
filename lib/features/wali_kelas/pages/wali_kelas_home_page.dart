import 'package:material_ui/material_ui.dart';

import '../data/absensi_repository.dart';
import '../data/kontak_repository.dart';
import '../data/rapor_repository.dart';
import 'absensi_pagi_page.dart';
import 'kontak_orang_tua_page.dart';
import 'rapor_list_page.dart';
import 'rekap_kehadiran_page.dart';

/// Menu sementara untuk sandbox. Di repo tim, menu ini digantikan
/// navigasi dari FE Fondasi.
class WaliKelasHomePage extends StatelessWidget {
  WaliKelasHomePage({
    super.key,
    required this.repository,
    KontakRepository? kontakRepository,
    RaporRepository? raporRepository,
  }) : kontakRepository = kontakRepository ?? DummyKontakRepository(),
       raporRepository = raporRepository ?? DummyRaporRepository();

  final AbsensiRepository repository;
  final KontakRepository kontakRepository;
  final RaporRepository raporRepository;

  @override
  Widget build(BuildContext context) {
    void buka(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    final menu = <(IconData, String, String, Widget Function())>[
      (
        Icons.how_to_reg,
        'Absensi Pagi',
        'Isi kehadiran siswa hari ini',
        () => AbsensiPagiPage(repository: repository),
      ),
      (
        Icons.bar_chart,
        'Rekap & Riwayat Kehadiran',
        'Per bulan, per siswa',
        () => RekapKehadiranPage(repository: repository),
      ),
      (
        Icons.contact_phone,
        'Kontak Orang Tua',
        'Telepon / WhatsApp',
        () => KontakOrangTuaPage(repository: kontakRepository),
      ),
      (
        Icons.description,
        'Rapor',
        'Susun, terbitkan, konfirmasi pengambilan',
        () => RaporListPage(repository: raporRepository),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Wali Kelas')),
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
                onTap: () => buka(page()),
              ),
            ),
        ],
      ),
    );
  }
}
