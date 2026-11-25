import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/akademik_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/beranda_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/kehadiran_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';
import 'package:schoolcare/shared/widgets/app_bottom_nav.dart';

/// Kerangka tampilan Orang Tua (route '/ortu'):
/// AppBar berisi nama anak (bisa diganti kalau anak > 1) + navigasi bawah 4 tab.
class OrtuShellPage extends StatefulWidget {
  const OrtuShellPage({super.key});

  @override
  State<OrtuShellPage> createState() => _OrtuShellPageState();
}

class _OrtuShellPageState extends State<OrtuShellPage> {
  final _repo = OrtuRepository();
  List<Anak>? _daftarAnak; // null = sedang dimuat
  Anak? _dipilih;
  bool _gagal = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _muatAnak();
  }

  Future<void> _muatAnak() async {
    try {
      await initializeDateFormatting('id_ID'); // supaya nama hari/bulan berbahasa Indonesia
      final list = await _repo.getAnak();
      if (!mounted) return;
      setState(() {
        _daftarAnak = list;
        _dipilih = list.isEmpty ? null : list.first;
        _gagal = false;
      });
    } catch (e) {
      debugPrint('OrtuShellPage: $e');
      if (mounted) setState(() => _gagal = true);
    }
  }

  void _cobaLagi() {
    setState(() {
      _gagal = false;
      _daftarAnak = null;
    });
    _muatAnak();
  }

  @override
  Widget build(BuildContext context) {
    final anak = _dipilih;

    final Widget status = _gagal
        ? GagalView(pesan: 'Gagal memuat data anak.', onCobaLagi: _cobaLagi)
        : _daftarAnak == null
            ? const MemuatView()
            : const KosongView(
                pesan: 'Akun ini belum terhubung dengan data siswa.\nHubungi pihak sekolah.',
                ikon: Icons.child_care,
              );

    // ValueKey(siswaId): saat anak diganti, tab dibuat ulang & memuat data anak baru.
    final tabs = <Widget>[
      anak == null
          ? status
          : BerandaTab(
              key: ValueKey('beranda-${anak.siswaId}'),
              anak: anak,
              pemilihAnak: _pemilihAnak(anak),
              onLihatKehadiran: () => setState(() => _index = 1),
              onLihatAkademik: () => setState(() => _index = 2),
            ),
      anak == null ? status : KehadiranTab(key: ValueKey('hadir-${anak.siswaId}'), anak: anak),
      anak == null ? status : AkademikTab(key: ValueKey('akademik-${anak.siswaId}'), anak: anak),
      const ProfilPage(showAppBar: false),
    ];

    return Scaffold(
      // Beranda punya judul sendiri ("Hari ini, <anak> di sekolah"), jadi tanpa AppBar.
      appBar: _index == 0 && anak != null
          ? null
          : AppBar(title: anak == null ? const Text('SchoolCare') : _judul(anak)),
      body: SafeArea(bottom: false, child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(ikon: Icons.home_outlined, label: 'Beranda'),
          AppBottomNavItem(ikon: Icons.fact_check_outlined, label: 'Kehadiran'),
          AppBottomNavItem(ikon: Icons.menu_book_outlined, label: 'Akademik'),
          AppBottomNavItem(ikon: Icons.person_outline, label: 'Profil'),
        ],
      ),
    );
  }

  /// Chip kecil "Kelas 7A ▾" di Beranda. Kalau anak lebih dari satu, bisa diketuk untuk ganti anak.
  Widget _pemilihAnak(Anak a) {
    final list = _daftarAnak ?? const <Anak>[];
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          list.length < 2 ? 'Kelas ${a.namaKelas}' : '${a.nama} · ${a.namaKelas}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        if (list.length >= 2) const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.black),
      ]),
    );
    if (list.length < 2) return chip;
    return PopupMenuButton<Anak>(
      tooltip: 'Ganti anak',
      onSelected: (x) => setState(() => _dipilih = x),
      itemBuilder: (_) => [
        for (final x in list) PopupMenuItem(value: x, child: Text('${x.nama} (Kelas ${x.namaKelas})')),
      ],
      child: chip,
    );
  }

  /// Nama + kelas anak. Kalau anak lebih dari satu, bisa diketuk untuk ganti anak.
  Widget _judul(Anak a) {
    final teks = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.nama),
        Text('Kelas ${a.namaKelas}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.white)),
      ],
    );
    final list = _daftarAnak ?? const <Anak>[];
    if (list.length < 2) return teks;
    return PopupMenuButton<Anak>(
      tooltip: 'Ganti anak',
      onSelected: (x) => setState(() => _dipilih = x),
      itemBuilder: (_) => [
        for (final x in list) PopupMenuItem(value: x, child: Text('${x.nama} (Kelas ${x.namaKelas})')),
      ],
      child: Row(mainAxisSize: MainAxisSize.min, children: [teks, const Icon(Icons.arrow_drop_down)]),
    );
  }
}
