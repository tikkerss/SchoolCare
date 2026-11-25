import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/data/siswa_repository.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/models/siswa_kelas.dart';
import 'package:schoolcare/features/guru/pages/absensi_mengajar_page.dart';
import 'package:schoolcare/features/guru/pages/ganti_foto_page.dart';
import 'package:schoolcare/features/guru/pages/ubah_berita_acara_page.dart';
import 'package:schoolcare/features/guru/widgets/catatan_siswa_sheet.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Satu jam pelajaran: absensi mengajar + berita acara + daftar siswa (status dari wali kelas)
/// + catatan per siswa.
class JadwalDetailPage extends StatefulWidget {
  const JadwalDetailPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  @override
  State<JadwalDetailPage> createState() => _JadwalDetailPageState();
}

class _JadwalDetailPageState extends State<JadwalDetailPage> {
  final _guruRepo = GuruRepository();
  final _siswaRepo = SiswaRepository();
  late Jadwal _jadwal = widget.jadwal;
  late Future<DaftarSiswa> _siswa = _siswaRepo.getSiswaHariIni(_jadwal.kelasId);

  void _muatUlangSiswa() => setState(() {
        _siswa = _siswaRepo.getSiswaHariIni(_jadwal.kelasId);
      });

  /// Absen pertama kali (pilih Hadir / Tidak Hadir).
  Future<void> _absen() => _buka(AbsensiMengajarPage(jadwal: _jadwal));

  /// Membuka halaman ubah, lalu memuat ulang data absensi kalau ada yang tersimpan.
  Future<void> _buka(Widget halaman) async {
    final tersimpan = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => halaman));
    if (tersimpan != true) return;
    try {
      final semua = await _guruRepo.getJadwalHariIni();
      final baru = semua.where((j) => j.id == _jadwal.id).firstOrNull;
      if (baru != null && mounted) setState(() => _jadwal = baru);
    } catch (e) {
      debugPrint('JadwalDetailPage: $e');
    }
  }

  Future<void> _bukaCatatan(SiswaKelas s) async {
    await tampilkanCatatanSiswa(context, siswa: s, jadwalId: _jadwal.id);
    if (mounted) _muatUlangSiswa();
  }

  @override
  Widget build(BuildContext context) {
    final j = _jadwal;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${j.mapel} • ${j.namaKelas}')),
      body: RefreshIndicator(
        onRefresh: () async {
          _muatUlangSiswa();
          await _siswa;
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              'Jam ke-${j.jamKe} • ${j.rentangJam} • ${j.ruang ?? '-'}',
              style: const TextStyle(fontSize: 13, color: AppColors.white),
            ),

            // ------------------------------------------------ absensi mengajar
            const SectionHeader('Absensi Mengajar'),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: j.sudahDiabsen ? _isiAbsensi(j, theme) : _belumAbsen(),
              ),
            ),

            // ------------------------------------------------ daftar siswa
            const SectionHeader('Daftar Siswa'),
            AsyncView<DaftarSiswa>(
              future: _siswa,
              onRetry: _muatUlangSiswa,
              isEmpty: (d) => d.siswa.isEmpty,
              emptyMessage: 'Belum ada siswa di kelas ini.',
              builder: (context, d) => SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _Ringkasan(daftar: d),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Text(
                        d.catatanAktif
                            ? 'Status diisi wali kelas saat absensi pagi. Ada kejadian? Ketuk nama siswa untuk menulis catatan.'
                            : 'Status diisi wali kelas saat absensi pagi. Fitur catatan belum aktif (tabel catatan_siswa belum dibuat Backend).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: d.catatanAktif ? AppColors.textSecondary : AppColors.pink,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    for (final s in d.siswa) ...[
                      _SiswaTile(siswa: s, onTap: d.catatanAktif ? () => _bukaCatatan(s) : null),
                      if (s != d.siswa.last) const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _belumAbsen() => [
    const Text(
      'Anda belum mengisi absensi untuk jam pelajaran ini.',
      style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(
      icon: const Icon(Icons.how_to_reg_outlined),
      label: const Text('Absen Sekarang'),
      onPressed: _absen,
    ),
  ];

  List<Widget> _isiAbsensi(Jadwal j, ThemeData theme) => [
    Row(
      children: [
        Text(
          j.hadir ? 'Hadir' : 'Tidak hadir',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const Spacer(),
        StatusBadge(j.statusKelas),
      ],
    ),
    if (j.infoWaktu.isNotEmpty) Text(j.infoWaktu, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
    if (j.hadir) ...[
      const SizedBox(height: 12),
      const _Label('Berita acara'),
      j.beritaAcara == null
          ? const Text(
              'Belum diisi. Lengkapi di akhir pelajaran.',
              style: TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600),
            )
          : Text(j.beritaAcara!, style: const TextStyle(fontSize: 13)),
    ],
    if (j.keterangan != null) ...[
      const SizedBox(height: 12),
      const _Label('Keterangan tidak hadir'),
      Text(j.keterangan!, style: const TextStyle(fontSize: 13)),
    ],
    if (j.guruPengganti != null) ...[
      const SizedBox(height: 12),
      Text('Guru pengganti: ${j.guruPengganti}', style: const TextStyle(fontSize: 13)),
    ],
    const SizedBox(height: 14),
    // Setelah absen, status kehadiran tidak bisa diubah lagi.
    // Yang masih bisa: berita acara (untuk Hadir, mis. dilengkapi di akhir pelajaran) dan foto bukti.
    if (j.hadir) ...[
      FilledButton.icon(
        icon: const Icon(Icons.edit_note),
        label: Text(j.beritaAcara == null ? 'Isi Berita Acara' : 'Ubah Berita Acara'),
        onPressed: () => _buka(UbahBeritaAcaraPage(jadwal: j)),
      ),
      const SizedBox(height: 8),
    ],
    OutlinedButton.icon(
      icon: const Icon(Icons.photo_camera_outlined),
      label: const Text('Ganti Foto Bukti'),
      onPressed: () => _buka(GantiFotoPage(jadwal: j)),
    ),
  ];
}

class _Label extends StatelessWidget {
  const _Label(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      teks,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}

/// Jumlah siswa per status, mis. "Hadir 8 · Sakit 1 · Belum diabsen 1".
class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.daftar});

  final DaftarSiswa daftar;

  @override
  Widget build(BuildContext context) {
    const urutan = ['hadir', 'terlambat', 'izin', 'sakit', 'alpa'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final st in urutan)
          if (daftar.jumlah(st) > 0)
            StatusPill(label: '${StatusBadge.labelOf(st)} ${daftar.jumlah(st)}', gaya: StatusBadge.gayaOf(st)),
        if (daftar.belumDiabsen > 0) StatusPill(label: 'Belum diabsen ${daftar.belumDiabsen}', gaya: GayaChip.putih),
      ],
    );
  }
}

class _SiswaTile extends StatelessWidget {
  const _SiswaTile({required this.siswa, required this.onTap});

  final SiswaKelas siswa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kecil = Theme.of(context).textTheme.bodySmall;
    final baris = <String>[
      'NIS ${siswa.nis}',
      if (siswa.keterangan != null) siswa.keterangan!,
      if (siswa.catatan.isNotEmpty) '${siswa.catatan.length} catatan hari ini',
    ];

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(siswa.nama),
      subtitle: Text(baris.join(' · '), style: kecil),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (siswa.catatan.isNotEmpty) const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 6),
          siswa.status == null
              ? Text('Belum diabsen', style: kecil?.copyWith(color: AppColors.textSecondary))
              : StatusBadge(siswa.status!),
        ],
      ),
    );
  }
}
