import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/pages/aktivitas_harian_page.dart';
import 'package:schoolcare/features/orang_tua/pages/form_izin_page.dart';
import 'package:schoolcare/features/orang_tua/pages/kontak_guru_page.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

typedef _DataBeranda = (AbsensiHarian?, List<AktivitasKelas>, List<PengumumanSingkat>);

/// Tab Beranda: kehadiran hari ini, pelajaran yang sedang berlangsung,
/// menu cepat, dan pengumuman terbaru.
class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key, required this.anak, required this.onLihatKehadiran});

  final Anak anak;
  final VoidCallback onLihatKehadiran;

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  final _repo = OrtuRepository();
  late Future<_DataBeranda> _future = _muat();
  late final VoidCallback _berhentiPantau;

  @override
  void initState() {
    super.initState();
    // Kehadiran di beranda ikut berubah otomatis (mis. setelah mengajukan izin).
    _berhentiPantau = _repo.pantauAbsensi(widget.anak.siswaId, () {
      if (mounted) _muatUlang();
    });
  }

  @override
  void dispose() {
    _berhentiPantau();
    super.dispose();
  }

  /// Tiga data diambil BERSAMAAN supaya beranda lebih cepat terbuka.
  Future<_DataBeranda> _muat() {
    final kelasId = widget.anak.kelasId;
    return (
      _repo.getAbsensiHariIni(widget.anak.siswaId),
      kelasId == null ? Future.value(<AktivitasKelas>[]) : _repo.getAktivitasHarian(kelasId, DateTime.now()),
      _repo.getPengumumanTerbaru(),
    ).wait;
  }

  void _muatUlang() => setState(() => _future = _muat());

  void _buka(Widget halaman) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => halaman));

  @override
  Widget build(BuildContext context) {
    final anak = widget.anak;

    return RefreshIndicator(
      onRefresh: () async {
        _muatUlang();
        await _future;
      },
      child: TungguData<_DataBeranda>(
        future: _future,
        onCobaLagi: _muatUlang,
        builder: (context, data) {
          final (absen, aktivitas, pengumuman) = data;
          final berlangsung = aktivitas.where((a) => a.sedangBerlangsung);
          final sekarang = berlangsung.isEmpty ? null : berlangsung.first;

          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(OrtuFmt.hari(DateTime.now()), style: const TextStyle(color: OrtuWarna.textSecondary)),
            const SizedBox(height: 12),

            // ---- Kehadiran hari ini
            Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Kehadiran hari ini'),
                subtitle: Text(
                  absen == null
                      ? 'Belum diabsen wali kelas'
                      : absen.keterangan ?? 'Diperbarui ${OrtuFmt.jamMenit(absen.diperbarui)}',
                ),
                trailing: absen == null ? null : StatusChip(absen.status),
                onTap: widget.onLihatKehadiran,
              ),
            ),
            const SizedBox(height: 12),

            // ---- Pelajaran sekarang
            Card(
              child: ListTile(
                leading: const Icon(Icons.class_outlined),
                title: Text(sekarang == null ? 'Tidak ada pelajaran berlangsung' : 'Sekarang: ${sekarang.mapel}'),
                subtitle: Text(
                  sekarang == null
                      ? 'Lihat semua aktivitas kelas hari ini'
                      : sekarang.infoKegiatan ??
                          '${OrtuFmt.jam(sekarang.jamMulai)}–${OrtuFmt.jam(sekarang.jamSelesai)} · ${sekarang.guruMengajar}',
                ),
                trailing: sekarang == null ? const Icon(Icons.chevron_right) : StatusChip(sekarang.statusKelas),
                onTap: () => _buka(AktivitasHarianPage(anak: anak)),
              ),
            ),

            // ---- Menu
            const JudulBagian('Menu'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                MenuKotak(ikon: Icons.edit_note, label: 'Izin / Sakit', onTap: () => _buka(FormIzinPage(anak: anak))),
                MenuKotak(
                  ikon: Icons.timeline,
                  label: 'Aktivitas Harian',
                  onTap: () => _buka(AktivitasHarianPage(anak: anak)),
                ),
                MenuKotak(ikon: Icons.chat_outlined, label: 'Kontak Guru', onTap: () => _buka(KontakGuruPage(anak: anak))),
              ],
            ),

            // ---- Pengumuman terbaru
            const JudulBagian('Pengumuman terbaru'),
            if (pengumuman.isEmpty) const Text('Belum ada pengumuman.'),
            for (final p in pengumuman)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(p.judul),
                    subtitle: Text('${OrtuFmt.tanggal(p.tanggal)} · ${p.isi}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _detailPengumuman(p),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  void _detailPengumuman(PengumumanSingkat p) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(p.judul, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(OrtuFmt.waktu(p.tanggal), style: const TextStyle(color: OrtuWarna.textSecondary)),
            const Divider(height: 32),
            Text(p.isi),
          ],
        ),
      );
}
