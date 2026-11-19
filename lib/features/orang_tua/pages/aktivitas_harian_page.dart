import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

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
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _KartuAktivitas(a: data[i], sorot: hariIni && data[i].sedangBerlangsung),
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
            Text('${widget.anak.nama} · ${OrtuFmt.hari(_tanggal)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          if (!hariIni)
            TextButton(
              onPressed: () {
                _tanggal = DateTime.now();
                _muatUlang();
              },
              child: const Text('Hari ini'),
            ),
          IconButton(icon: const Icon(Icons.calendar_today), tooltip: 'Pilih tanggal', onPressed: _pilihTanggal),
        ],
      ),
      body: body,
    );
  }
}

class _KartuAktivitas extends StatelessWidget {
  const _KartuAktivitas({required this.a, required this.sorot});

  final AktivitasKelas a;
  final bool sorot; // pelajaran yang sedang berlangsung

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      color: sorot ? OrtuWarna.primary.withValues(alpha: 0.06) : null,
      shape: sorot
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: OrtuWarna.primary, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                'Jam ${a.jamKe} · ${OrtuFmt.jam(a.jamMulai)}–${OrtuFmt.jam(a.jamSelesai)}'
                '${a.ruang != null ? ' · ${a.ruang}' : ''}',
                style: const TextStyle(color: OrtuWarna.textSecondary),
              ),
            ),
            StatusChip(a.statusKelas),
          ]),
          const SizedBox(height: 6),
          Text(a.mapel, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(a.digantikan ? 'Digantikan ${a.guruMengajar} (seharusnya ${a.guruTerjadwal})' : a.guruTerjadwal),
          if (a.infoKegiatan != null) ...[
            const SizedBox(height: 8),
            Text(a.infoKegiatan!, style: const TextStyle(color: OrtuWarna.purple, fontWeight: FontWeight.w600)),
          ],
          if (a.beritaAcara != null) ...[
            const SizedBox(height: 8),
            Text('Kegiatan: ${a.beritaAcara}'),
          ],
          if (a.fotoUrl != null) ...[
            const SizedBox(height: 12),
            _FotoBukti(url: a.fotoUrl!),
          ],
        ]),
      ),
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
            progress == null ? child : Container(height: tinggi ?? 160, color: OrtuWarna.border),
        errorBuilder: (_, _, _) => Container(
          height: tinggi ?? 160,
          color: OrtuWarna.border,
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
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: _gambar(tinggi: 160)),
      );
}
