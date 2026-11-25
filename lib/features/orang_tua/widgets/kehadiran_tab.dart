import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/pages/form_izin_page.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';
import 'package:schoolcare/shared/widgets/dashed.dart';
import 'package:schoolcare/shared/widgets/emotikon_kehadiran.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Tab Kehadiran: rekap & kalender kehadiran per bulan, ter-update otomatis.
/// Ketuk satu hari untuk melihat riwayat perubahan statusnya.
class KehadiranTab extends StatefulWidget {
  const KehadiranTab({super.key, required this.anak});

  final Anak anak;

  @override
  State<KehadiranTab> createState() => _KehadiranTabState();
}

class _KehadiranTabState extends State<KehadiranTab> {
  static const _urutanStatus = ['hadir', 'terlambat', 'izin', 'sakit', 'alpa'];
  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];

  final _repo = OrtuRepository();
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<AbsensiHarian>> _future = _muat();
  late final VoidCallback _berhentiPantau;

  /// Tanggal yang dipilih di kalender (null = belum memilih).
  DateTime? _terpilih = DateUtils.dateOnly(DateTime.now());

  /// Riwayat status untuk absensi yang dipilih, disimpan per id absensi.
  String? _riwayatId;
  Future<List<RiwayatStatus>>? _riwayat;

  @override
  void initState() {
    super.initState();
    _berhentiPantau = _repo.pantauAbsensi(widget.anak.siswaId, () {
      if (mounted) _muatUlang();
    });
  }

  @override
  void dispose() {
    _berhentiPantau();
    super.dispose();
  }

  Future<List<AbsensiHarian>> _muat() => _repo.getAbsensiBulan(widget.anak.siswaId, _bulan);

  void _muatUlang() => setState(() {
        _future = _muat();
        _riwayatId = null; // riwayat ikut dimuat ulang
      });

  void _gantiBulan(int geser) {
    _bulan = DateTime(_bulan.year, _bulan.month + geser);
    final hariIni = DateUtils.dateOnly(DateTime.now());
    _terpilih = DateUtils.isSameMonth(_bulan, hariIni) ? hariIni : null;
    _muatUlang();
  }

  Future<List<RiwayatStatus>> _riwayatUntuk(AbsensiHarian a) {
    if (_riwayatId != a.id || _riwayat == null) {
      _riwayatId = a.id;
      _riwayat = _repo.getRiwayatStatus(a.id);
    }
    return _riwayat!;
  }

  @override
  Widget build(BuildContext context) {
    final bulanIni = DateTime(DateTime.now().year, DateTime.now().month);

    return Column(children: [
      // ---- pilih bulan
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.white,
            onPressed: () => _gantiBulan(-1),
          ),
          Expanded(
            child: Text(
              OrtuFmt.bulan(_bulan),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.white,
            disabledColor: AppColors.softPink,
            onPressed: _bulan == bulanIni ? null : () => _gantiBulan(1),
          ),
        ]),
      ),

      // ---- rekap + kalender + detail
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            _muatUlang();
            await _future;
          },
          child: TungguData<List<AbsensiHarian>>(
            future: _future,
            onCobaLagi: _muatUlang,
            builder: (context, list) {
              final perTanggal = {for (final a in list) DateUtils.dateOnly(a.tanggal): a};
              final t = _terpilih;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _rekap(list),
                  const SizedBox(height: 14),
                  _kalender(perTanggal),
                  if (t != null) ...[
                    const SizedBox(height: 14),
                    _detail(t, perTanggal[t]),
                  ],
                ],
              );
            },
          ),
        ),
      ),

      // ---- tombol izin
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          // Tombol langsung di atas latar pink: softYellow, teks ink Bold.
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.softYellow, foregroundColor: AppColors.ink),
            icon: const Icon(Icons.edit_note),
            label: const Text('Ajukan izin / sakit'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => FormIzinPage(anak: widget.anak)),
            ),
          ),
        ),
      ),
    ]);
  }

  // ------------------------------------------------------------ rekap bulan
  Widget _rekap(List<AbsensiHarian> list) {
    final hitung = {for (final s in _urutanStatus) s: list.where((a) => a.status == s).length};
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        for (final e in hitung.entries)
          Column(mainAxisSize: MainAxisSize.min, children: [
            EmotikonKehadiran(e.key, size: 36),
            const SizedBox(height: 6),
            Text('${e.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(StatusBadge.labelOf(e.key), style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
          ]),
      ]),
    );
  }

  // ---------------------------------------------------------- kalender Sen–Jum
  Widget _kalender(Map<DateTime, AbsensiHarian> perTanggal) {
    final hariIni = DateUtils.dateOnly(DateTime.now());
    final jumlahHari = DateUtils.getDaysInMonth(_bulan.year, _bulan.month);

    // Susun tanggal hari kerja ke dalam minggu (5 kolom).
    final minggu = <List<DateTime?>>[];
    var baris = List<DateTime?>.filled(5, null);
    for (var d = 1; d <= jumlahHari; d++) {
      final tgl = DateTime(_bulan.year, _bulan.month, d);
      if (tgl.weekday > 5) continue;
      baris[tgl.weekday - 1] = tgl;
      if (tgl.weekday == 5) {
        minggu.add(baris);
        baris = List<DateTime?>.filled(5, null);
      }
    }
    if (baris.any((x) => x != null)) minggu.add(baris);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(children: [
        Row(children: [
          for (final h in _namaHari)
            Expanded(
              child: Text(
                h,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkMuted),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        for (final w in minggu)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              for (final tgl in w)
                Expanded(
                  child: tgl == null
                      ? const SizedBox(height: 54)
                      : _selHari(tgl, perTanggal[tgl], belumLewat: tgl.isAfter(hariIni)),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _selHari(DateTime tgl, AbsensiHarian? a, {required bool belumLewat}) {
    final dipilih = _terpilih != null && DateUtils.isSameDay(_terpilih, tgl);
    const ukuran = 34.0;

    final Widget isi;
    if (a != null) {
      isi = EmotikonKehadiran(a.status, size: ukuran);
    } else {
      final angka = SizedBox(
        width: ukuran,
        height: ukuran,
        child: Center(
          child: Text(
            '${tgl.day}',
            style: TextStyle(fontSize: 12, color: belumLewat ? AppColors.inkMuted : AppColors.ink),
          ),
        ),
      );
      // Hari yang belum lewat: lingkaran transparan bergaris putus-putus pink.
      isi = belumLewat
          ? DashedOutline(color: AppColors.pink, radius: ukuran / 2, child: angka)
          : angka;
    }

    return InkResponse(
      onTap: () => setState(() => _terpilih = tgl),
      radius: 26,
      // Tinggi minimal 54 (bukan tinggi tetap): isi sel = cincin 43 + angka ±11.
      // Tinggi tetap dulu overflow ±1 px (lebih besar lagi kalau teks diperbesar).
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Tanggal terpilih: cincin pink 2.5px.
              border: Border.all(color: dipilih ? AppColors.pink : Colors.transparent, width: 2.5),
            ),
            child: isi,
          ),
          if (a != null)
            Text('${tgl.day}', style: const TextStyle(fontSize: 9, color: AppColors.inkMuted, height: 1.2)),
        ]),
      ),
    );
  }

  // ------------------------------------------------------ detail hari terpilih
  Widget _detail(DateTime tgl, AbsensiHarian? a) {
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(OrtuFmt.hari(tgl), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (a != null) StatusChip(a.status),
        ]),
        if (a == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Belum ada data kehadiran.', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          )
        else ...[
          if (a.keterangan != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(a.keterangan!, style: const TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 12),
          const Text('Riwayat perubahan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          FutureBuilder<List<RiwayatStatus>>(
            future: _riwayatUntuk(a),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(height: 60, child: MemuatView());
              }
              if (snap.hasError) return const SizedBox(height: 100, child: GagalView());
              final list = snap.data!;
              if (list.isEmpty) {
                return const Text('Belum ada riwayat.', style: TextStyle(fontSize: 12, color: AppColors.inkMuted));
              }
              return Column(children: [for (final r in list) _barisRiwayat(r)]);
            },
          ),
        ],
      ]),
    );
  }

  Widget _barisRiwayat(RiwayatStatus r) {
    final ket = [
      if (r.keterangan != null) r.keterangan!,
      if (r.oleh != null) 'oleh ${r.oleh}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 48,
          child: Text(OrtuFmt.jamMenit(r.waktu), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (r.statusLama != null) ...[
                  StatusChip(r.statusLama!),
                  const Icon(Icons.arrow_forward, size: 14, color: AppColors.inkMuted),
                ],
                StatusChip(r.statusBaru),
              ],
            ),
            if (ket.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ket, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
              ),
          ]),
        ),
      ]),
    );
  }
}
