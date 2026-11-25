import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/pages/aktivitas_harian_page.dart';
import 'package:schoolcare/features/orang_tua/pages/form_izin_page.dart';
import 'package:schoolcare/features/orang_tua/pages/kontak_guru_page.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';
import 'package:schoolcare/shared/widgets/emotikon_kehadiran.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

typedef _DataBeranda = (AbsensiHarian?, List<AktivitasKelas>, List<PengumumanSingkat>);

/// Tab Beranda: kehadiran hari ini, pelajaran yang sedang berlangsung,
/// menu cepat, dan pengumuman terbaru.
class BerandaTab extends StatefulWidget {
  const BerandaTab({
    super.key,
    required this.anak,
    required this.onLihatKehadiran,
    this.onLihatAkademik,
    this.pemilihAnak,
  });

  final Anak anak;
  final VoidCallback onLihatKehadiran;
  final VoidCallback? onLihatAkademik;

  /// Chip kelas / pemilih anak dari halaman induk (ditaruh di samping tanggal).
  final Widget? pemilihAnak;

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

  /// "Andi Pratama" → "Andi"
  static String _namaDepan(String nama) => nama.trim().split(' ').first;

  static const _ket = TextStyle(fontSize: 12, color: AppColors.inkMuted);
  static const _ketDiPink = TextStyle(fontSize: 12, color: AppColors.white);
  static const _judulKartu = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

  // Teks di atas kotak softYellow/softPink: hitam bold.
  static const _labelMuda = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black);
  static const _ketMuda = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.black);

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

          return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            // ---- judul + maskot Tasi kecil di samping
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Hari ini, '),
                      // Nama anak disorot softYellow (pink tidak terbaca di atas latar pink).
                      TextSpan(text: _namaDepan(anak.nama), style: const TextStyle(color: AppColors.softYellow)),
                      const TextSpan(text: ' di sekolah'),
                    ]),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(OrtuFmt.hari(DateTime.now()), style: _ketDiPink),
                      if (widget.pemilihAnak != null) widget.pemilihAnak!,
                    ],
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              const IgnorePointer(child: MaskotTasi(size: 104)),
            ]),
            const SizedBox(height: 16),

            // ---- Kehadiran hari ini
            SoftCard(
              warna: AppColors.softYellow,
              onTap: widget.onLihatKehadiran,
              child: Row(children: [
                EmotikonKehadiran(absen?.status, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Kehadiran hari ini', style: _labelMuda),
                    const SizedBox(height: 2),
                    Text(
                      absen == null ? 'Belum diabsen' : StatusBadge.labelOf(absen.status),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      absen == null
                          ? 'Wali kelas belum mengisi absensi pagi'
                          : absen.keterangan ?? 'Diperbarui ${OrtuFmt.jamMenit(absen.diperbarui)}',
                      style: _ketMuda,
                    ),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.black),
              ]),
            ),

            // ---- Pelajaran sekarang
            const JudulBagian('Sekarang'),
            if (sekarang == null)
              SoftCard(
                onTap: () => _buka(AktivitasHarianPage(anak: anak)),
                child: const Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Tidak ada pelajaran berlangsung', style: _judulKartu),
                      SizedBox(height: 2),
                      Text('Lihat semua aktivitas kelas hari ini', style: _ket),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.ink),
                ]),
              )
            else
              TicketCard(
                jamMulai: OrtuFmt.jam(sekarang.jamMulai),
                jamSelesai: OrtuFmt.jam(sekarang.jamSelesai),
                labelAtas: 'Jam ${sekarang.jamKe}',
                sorot: true,
                onTap: () => _buka(AktivitasHarianPage(anak: anak)),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sekarang.mapel, style: _judulKartu),
                      const SizedBox(height: 2),
                      Text(
                        sekarang.infoKegiatan ??
                            [sekarang.guruMengajar, if (sekarang.ruang != null) sekarang.ruang!].join(' · '),
                        style: _ket,
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(sekarang.statusKelas),
                ]),
              ),

            // ---- Menu
            const JudulBagian('Menu'),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              // Row (bukan GridView rasio tetap) supaya tinggi mengikuti isi dan tidak overflow
              // saat label 2 baris / ukuran teks diperbesar.
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final m in <Widget>[
                    MenuKotak(
                      ikon: Icons.edit_note,
                      label: 'Izin / Sakit',
                      warna: AppColors.pink,
                      onTap: () => _buka(FormIzinPage(anak: anak)),
                    ),
                    MenuKotak(
                      ikon: Icons.timeline,
                      label: 'Aktivitas',
                      warna: AppColors.orange,
                      onTap: () => _buka(AktivitasHarianPage(anak: anak)),
                    ),
                    MenuKotak(
                      ikon: Icons.assignment_outlined,
                      label: 'Tugas',
                      warna: AppColors.softPink,
                      onTap: widget.onLihatAkademik ?? () {},
                    ),
                    MenuKotak(
                      ikon: Icons.chat_outlined,
                      label: 'Chat Guru',
                      warna: AppColors.softYellow,
                      onTap: () => _buka(KontakGuruPage(anak: anak)),
                    ),
                ])
                  Expanded(child: m),
              ]),
            ),

            // ---- Pengumuman terbaru
            const JudulBagian('Pengumuman'),
            if (pengumuman.isEmpty) const Text('Belum ada pengumuman.', style: _ketDiPink),
            for (final p in pengumuman)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  warna: AppColors.softYellow,
                  onTap: () => _detailPengumuman(p),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.campaign_outlined, color: AppColors.black),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.judul, style: _judulKartu.copyWith(color: AppColors.black)),
                        const SizedBox(height: 2),
                        Text(p.isi, maxLines: 2, overflow: TextOverflow.ellipsis, style: _ketMuda),
                        const SizedBox(height: 4),
                        Text(OrtuFmt.tanggal(p.tanggal), style: _labelMuda),
                      ]),
                    ),
                  ]),
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
            Text(p.judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(OrtuFmt.waktu(p.tanggal), style: _ket),
            const Divider(height: 32),
            Text(p.isi, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}
