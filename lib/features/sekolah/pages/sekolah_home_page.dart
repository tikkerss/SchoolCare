import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:schoolcare/features/laporan_sekolah/data/laporan_repository.dart';
import 'package:schoolcare/features/laporan_sekolah/data/supabase_laporan_repository.dart';
import 'package:schoolcare/features/laporan_sekolah/pages/laporan_absensi_guru_page.dart';
import 'package:schoolcare/features/laporan_sekolah/pages/pantau_rapor_page.dart';
import 'package:schoolcare/features/laporan_sekolah/pages/rekap_kehadiran_sekolah_page.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/pages/agenda_admin_page.dart';
import 'package:schoolcare/features/sekolah/pages/akun_page.dart';
import 'package:schoolcare/features/sekolah/pages/jadwal_admin_page.dart';
import 'package:schoolcare/features/sekolah/pages/kelas_page.dart';
import 'package:schoolcare/features/sekolah/pages/mapel_page.dart';
import 'package:schoolcare/features/sekolah/pages/pengumuman_admin_page.dart';
import 'package:schoolcare/features/sekolah/pages/siswa_page.dart';
import 'package:schoolcare/features/sekolah/pages/tahun_ajaran_page.dart';
import 'package:schoolcare/shared/widgets/menu_tile.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';

/// Beranda Pihak Sekolah (admin): ringkasan tahun ajaran aktif + menu semua fitur pengelolaan.
class SekolahHomePage extends StatefulWidget {
  const SekolahHomePage({super.key});

  @override
  State<SekolahHomePage> createState() => _SekolahHomePageState();
}

class _SekolahHomePageState extends State<SekolahHomePage> {
  final _repo = SekolahRepository();
  // Untuk mencoba tampilan tanpa Supabase, ganti ke DummyLaporanRepository().
  final LaporanRepository _laporan = SupabaseLaporanRepository();
  late Future<TahunAjaran?> _ta = _repo.getTahunAjaranAktif();

  void _muatUlang() => setState(() => _ta = _repo.getTahunAjaranAktif());

  Future<void> _buka(Widget halaman) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => halaman));
    _muatUlang(); // misalnya tahun ajaran aktif baru saja diganti
  }

  @override
  Widget build(BuildContext context) {
    final nama = context.watch<AuthProvider>().profile?.namaLengkap ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pihak Sekolah'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), tooltip: 'Profil', onPressed: () => context.push('/profil')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _muatUlang(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Halo, '),
              TextSpan(text: nama, style: const TextStyle(color: AppColors.softYellow)),
            ]),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white, height: 1.25),
          ),
          const SizedBox(height: 12),

          // ---- Tahun ajaran aktif
          FutureBuilder<TahunAjaran?>(
            future: _ta,
            builder: (context, snap) {
              final ta = snap.data;
              final belum = snap.connectionState == ConnectionState.done && ta == null;
              return Card(
                color: belum ? AppColors.softYellow : null,
                child: ListTile(
                  // softYellow → teks hitam bold.
                  textColor: belum ? AppColors.black : null,
                  titleTextStyle: belum
                      ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)
                      : null,
                  subtitleTextStyle: belum
                      ? const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black)
                      : null,
                  iconColor: belum ? AppColors.black : null,
                  leading: Icon(belum ? Icons.warning_amber : Icons.event_note,
                      color: belum ? AppColors.black : AppColors.primary),
                  title: Text(snap.connectionState != ConnectionState.done
                      ? 'Memuat tahun ajaran…'
                      : belum
                          ? 'Belum ada tahun ajaran aktif'
                          : 'Tahun ajaran ${ta!.nama}'),
                  subtitle: Text(belum
                      ? 'Buat dan aktifkan tahun ajaran dulu sebelum mengisi kelas & jadwal.'
                      : ta == null
                          ? ''
                          : 'Semester ${hurufBesarAwal(ta.semesterAktif)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _buka(const TahunAjaranPage()),
                ),
              );
            },
          ),

          const SectionHeader('Data master'),
          _grid([
            MenuTile(icon: Icons.manage_accounts_outlined, label: 'Akun', onTap: () => _buka(const AkunPage())),
            MenuTile(icon: Icons.event_note, label: 'Tahun Ajaran', onTap: () => _buka(const TahunAjaranPage())),
            MenuTile(icon: Icons.meeting_room_outlined, label: 'Kelas & Wali', onTap: () => _buka(const KelasPage())),
            MenuTile(icon: Icons.groups_outlined, label: 'Siswa & Orang Tua', onTap: () => _buka(const SiswaPage())),
            MenuTile(icon: Icons.menu_book_outlined, label: 'Mata Pelajaran', onTap: () => _buka(const MapelPage())),
            MenuTile(icon: Icons.schedule, label: 'Jadwal Pelajaran', onTap: () => _buka(const JadwalAdminPage())),
          ]),

          const SectionHeader('Informasi sekolah'),
          _grid([
            MenuTile(icon: Icons.campaign_outlined, label: 'Pengumuman', onTap: () => _buka(const PengumumanAdminPage())),
            MenuTile(icon: Icons.calendar_month, label: 'Agenda / Kalender', onTap: () => _buka(const AgendaAdminPage())),
          ]),

          const SectionHeader('Laporan'),
          _grid([
            // Halaman laporan buatan FE Wali Kelas (lib/features/laporan_sekolah)
            MenuTile(
              icon: Icons.badge_outlined,
              label: 'Absensi Guru',
              onTap: () => _buka(LaporanAbsensiGuruPage(repository: _laporan)),
            ),
            MenuTile(
              icon: Icons.bar_chart,
              label: 'Rekap Kehadiran Siswa',
              onTap: () => _buka(RekapKehadiranSekolahPage(repository: _laporan)),
            ),
            MenuTile(
              icon: Icons.fact_check_outlined,
              label: 'Pantau Rapor',
              onTap: () => _buka(PantauRaporPage(repository: _laporan)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _grid(List<Widget> items) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: items,
      );
}
