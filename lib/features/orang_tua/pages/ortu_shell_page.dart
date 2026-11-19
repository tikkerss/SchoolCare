import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/akademik_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/beranda_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/kehadiran_tab.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

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
              onLihatKehadiran: () => setState(() => _index = 1),
            ),
      anak == null ? status : KehadiranTab(key: ValueKey('hadir-${anak.siswaId}'), anak: anak),
      anak == null ? status : AkademikTab(key: ValueKey('akademik-${anak.siswaId}'), anak: anak),
      const ProfilPage(showAppBar: false),
    ];

    return Scaffold(
      appBar: AppBar(title: anak == null ? const Text('SchoolCare') : _judul(anak)),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Kehadiran',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Akademik',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  /// Nama + kelas anak. Kalau anak lebih dari satu, bisa diketuk untuk ganti anak.
  Widget _judul(Anak a) {
    final teks = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.nama),
        Text('Kelas ${a.namaKelas}', style: Theme.of(context).textTheme.bodySmall),
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
