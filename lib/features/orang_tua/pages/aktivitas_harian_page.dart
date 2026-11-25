import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Aktivitas kelas anak per jam pelajaran: status kelas, guru yang mengajar,
/// berita acara, dan foto bukti dari guru. Diperbarui otomatis tiap 60 detik.
class AktivitasHarianPage extends StatefulWidget {
  const AktivitasHarianPage({super.key, required this.anak});

  final Anak anak;

  @override
  State<AktivitasHarianPage> createState() => _AktivitasHarianPageState();
}

class _AktivitasHarianPageState extends State<AktivitasHarianPage> {
  final _repo = OrtuRepository();
  DateTime _tanggal = DateTime.now();
  List<AktivitasKelas>? _data; // null = sedang dimuat
  bool _gagal = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ambil(); // jangan memanggil setState langsung di initState
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (DateUtils.isSameDay(_tanggal, DateTime.now())) _ambil(diam: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Muat ulang dengan menampilkan loading (ganti tanggal / tombol coba lagi).
  Future<void> _muatUlang() async {
    setState(() {
      _data = null;
      _gagal = false;
    });
    await _ambil();
  }

  /// [diam] = true → kalau gagal, tampilan lama dibiarkan (pembaruan berkala).
  Future<void> _ambil({bool diam = false}) async {
    final kelasId = widget.anak.kelasId;
    try {
      final d = kelasId == null ? <AktivitasKelas>[] : await _repo.getAktivitasHarian(kelasId, _tanggal);
      if (mounted) {
        setState(() {
          _data = d;
          _gagal = false;
        });
      }
    } catch (e) {
      debugPrint('AktivitasHarianPage: $e');
      if (mounted && !diam) setState(() => _gagal = true);
    }
  }

  Future<void> _pilihTanggal() async {
    final n = DateTime.now();
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: n.subtract(const Duration(days: 60)),
      lastDate: n.add(const Duration(days: 14)),
    );
    if (t == null) return;
    _tanggal = t;
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final hariIni = DateUtils.isSameDay(_tanggal, DateTime.now());
    final data = _data;

    final Widget body;
    if (_gagal) {
      body = GagalView(onCobaLagi: _muatUlang);
    } else if (data == null) {
      body = const MemuatView();
    } else if (data.isEmpty) {
      body = const KosongView(pesan: 'Tidak ada jadwal pelajaran di hari ini.', ikon: Icons.weekend_outlined);
    } else {
      body = RefreshIndicator(
        onRefresh: () => _ambil(diam: true),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _KartuAktivitas(
            key: ValueKey('${data[i].jamKe}-${data[i].jamMulai}'),
            a: data[i],
            sorot: hariIni && data[i].sedangBerlangsung,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aktivitas Harian'),
            Text(
              '${widget.anak.nama} · ${OrtuFmt.hari(_tanggal)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.white),
            ),
          ],
        ),
        actions: [
          if (!hariIni)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
              onPressed: () {
                _tanggal = DateTime.now();
                _muatUlang();
              },
              child: const Text('Hari ini'),
            ),
          IconButton(icon: const Icon(Icons.calendar_today), tooltip: 'Pilih tanggal', onPressed: _pilihTanggal),
        ],
      ),
      body: Column(children: [
        _StripHari(
          terpilih: _tanggal,
          onPilih: (t) {
            if (DateUtils.isSameDay(t, _tanggal)) return;
            _tanggal = t;
            _muatUlang();
          },
        ),
        Expanded(child: body),
      ]),
    );
  }
}

/// Strip 5 hari kerja (Sen–Jum) di minggu tanggal terpilih. Hari aktif = pink.
class _StripHari extends StatelessWidget {
  const _StripHari({required this.terpilih, required this.onPilih});

  final DateTime terpilih;
  final ValueChanged<DateTime> onPilih;

  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];

  @override
  Widget build(BuildContext context) {
    final t = DateUtils.dateOnly(terpilih);
    // Sabtu/Minggu → tampilkan minggu itu juga (Senin sebelumnya).
    final senin = t.subtract(Duration(days: t.weekday - 1));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      // Di dalam kartu putih supaya hari aktif (pink) tetap terlihat di atas latar pink.
      child: SoftCard(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          for (var i = 0; i < 5; i++) Expanded(child: _sel(senin.add(Duration(days: i)), i)),
        ]),
      ),
    );
  }

  Widget _sel(DateTime d, int i) {
    final aktif = DateUtils.isSameDay(d, terpilih);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: aktif ? AppColors.pink : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onPilih(d),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: aktif ? null : Border.all(color: AppColors.softPink, width: 1.5),
            ),
            child: Column(children: [
              Text(
                _hari[i],
                style: TextStyle(fontSize: 11, color: aktif ? AppColors.white : AppColors.inkMuted),
              ),
              Text(
                '${d.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: aktif ? AppColors.white : AppColors.ink,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Kartu tiket satu jam pelajaran. Ketuk untuk membuka foto bukti + berita acara.
class _KartuAktivitas extends StatefulWidget {
  const _KartuAktivitas({super.key, required this.a, required this.sorot});

  final AktivitasKelas a;
  final bool sorot; // pelajaran yang sedang berlangsung

  @override
  State<_KartuAktivitas> createState() => _KartuAktivitasState();
}

class _KartuAktivitasState extends State<_KartuAktivitas> {
  late bool _terbuka = widget.sorot;

  @override
  Widget build(BuildContext context) {
    final a = widget.a;
    final adaDetail = a.beritaAcara != null || a.fotoUrl != null;
    return TicketCard(
      jamMulai: OrtuFmt.jam(a.jamMulai),
      jamSelesai: OrtuFmt.jam(a.jamSelesai),
      labelAtas: 'Jam ${a.jamKe}',
      sorot: widget.sorot,
      onTap: adaDetail ? () => setState(() => _terbuka = !_terbuka) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.mapel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                [
                  a.digantikan ? 'Digantikan ${a.guruMengajar} (seharusnya ${a.guruTerjadwal})' : a.guruTerjadwal,
                  if (a.ruang != null) a.ruang!,
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          StatusChip(a.statusKelas),
        ]),
        if (a.infoKegiatan != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(8)),
            child: Text(a.infoKegiatan!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
        if (adaDetail) ...[
          const SizedBox(height: 6),
          Row(children: [
            Flexible(
              child: Text(
                _terbuka ? 'Tutup detail' : 'Lihat foto & berita acara',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.pink),
              ),
            ),
            Icon(_terbuka ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.pink),
          ]),
        ],
        if (_terbuka) ...[
          if (a.fotoUrl != null) ...[
            const SizedBox(height: 10),
            _FotoBukti(url: a.fotoUrl!),
          ],
          if (a.beritaAcara != null) ...[
            const SizedBox(height: 10),
            const Text('Berita acara', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(a.beritaAcara!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ]),
    );
  }
}

/// Foto bukti dari guru. Ketuk untuk memperbesar.
class _FotoBukti extends StatelessWidget {
  const _FotoBukti({required this.url});

  final String url;

  Widget _gambar({BoxFit fit = BoxFit.cover, double? tinggi}) => Image.network(
        url,
        height: tinggi,
        width: double.infinity,
        fit: fit,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(height: tinggi ?? 160, color: AppColors.softPink),
        errorBuilder: (_, _, _) => Container(
          height: tinggi ?? 160,
          color: AppColors.softPink,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(child: _gambar(fit: BoxFit.contain)),
          ),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _gambar(tinggi: 160)),
      );
}
