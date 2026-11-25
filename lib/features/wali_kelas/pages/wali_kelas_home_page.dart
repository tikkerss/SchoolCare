import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

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

  static const _warnaIkon = [
    AppColors.pink,
    AppColors.orange,
    AppColors.softPink,
    AppColors.softYellow,
  ];

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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final (i, (ikon, judul, sub, page)) in menu.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                onTap: () => buka(page()),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _warnaIkon[i % _warnaIkon.length],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        ikon,
                        color: AppColors.teksDi(_warnaIkon[i % _warnaIkon.length]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            judul,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            sub,
                            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.ink),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
