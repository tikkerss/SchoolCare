import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/pages/absensi_mengajar_page.dart';
import 'package:schoolcare/features/guru/pages/jadwal_detail_page.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Daftar jam pelajaran yang diampu guru hari ini (dari Supabase).
/// Ketuk satu jam pelajaran untuk absensi mengajar, berita acara, dan daftar siswa.
class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _repo = GuruRepository();
  late Future<List<Jadwal>> _future = _repo.getJadwalHariIni();

  void _muatUlang() => setState(() {
        _future = _repo.getJadwalHariIni();
      });

  /// Membuka detail jam pelajaran (absensi + daftar siswa). Jadwal dimuat ulang sesudahnya.
  Future<void> _buka(Jadwal j) async {
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => JadwalDetailPage(jadwal: j)));
    if (mounted) _muatUlang();
  }

  /// Pintasan "Absen Mengajar" di kartu kelas yang sedang berjalan.
  Future<void> _absen(Jadwal j) async {
    final tersimpan = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AbsensiMengajarPage(jadwal: j)),
    );
    if (tersimpan == true && mounted) _muatUlang();
  }

  /// true kalau jam sekarang ada di rentang jam pelajaran ini (jadwal = hari ini).
  static bool _sedangBerjalan(Jadwal j) {
    final n = DateTime.now();
    final sekarang = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    return Fmt.jam(j.jamMulai).compareTo(sekarang) <= 0 && sekarang.compareTo(Fmt.jam(j.jamSelesai)) < 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            _muatUlang();
            await _future;
          },
          child: AsyncView<List<Jadwal>>(
            future: _future,
            onRetry: _muatUlang,
            builder: (context, list) {
              final sudah = list.where((j) => j.sudahDiabsen).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _Sapaan(nama: auth.profile?.namaLengkap, wali: auth.isWaliKelas),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _KotakStatistik(angka: list.length, label: 'Jam hari ini', warna: AppColors.orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KotakStatistik(angka: sudah, label: 'Sudah absen', warna: AppColors.softPink),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KotakStatistik(
                          angka: list.length - sudah,
                          label: 'Belum absen',
                          warna: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SectionHeader('Jadwal Mengajar'),
                  if (list.isEmpty)
                    const EmptyState(
                      message: 'Tidak ada jadwal mengajar hari ini.',
                      icon: Icons.event_available_outlined,
                    ),
                  for (final j in list) ...[
                    _JadwalCard(
                      jadwal: j,
                      berjalan: _sedangBerjalan(j),
                      onTap: () => _buka(j),
                      onAbsen: () => _absen(j),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "Halo, Bu Sri" + chip Wali Kelas + tanggal, langsung di atas latar pink.
class _Sapaan extends StatelessWidget {
  const _Sapaan({required this.nama, required this.wali});

  final String? nama;
  final bool wali;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: nama == null ? 'Halo!' : 'Halo, '),
                  // Nama di sapaan = softYellow.
                  if (nama != null) TextSpan(text: nama, style: const TextStyle(color: AppColors.softYellow)),
                ],
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white, height: 1.25),
            ),
          ),
          if (wali) ...[const SizedBox(width: 8), const StatusPill(label: 'Wali Kelas', gaya: GayaChip.orange)],
        ],
      ),
      const SizedBox(height: 4),
      Text(Fmt.hari(DateTime.now()), style: const TextStyle(fontSize: 12, color: AppColors.white)),
    ],
  );
}

class _KotakStatistik extends StatelessWidget {
  const _KotakStatistik({required this.angka, required this.label, required this.warna});

  final int angka;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    // Rata tengah: label di atas, angka besar di bawah.
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teksDi(warna)),
        ),
        const SizedBox(height: 2),
        Text(
          '$angka',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.teksDi(warna), height: 1.1),
        ),
      ],
    ),
  );
}

class _JadwalCard extends StatelessWidget {
  const _JadwalCard({required this.jadwal, required this.berjalan, required this.onTap, required this.onAbsen});

  final Jadwal jadwal;
  final bool berjalan;
  final VoidCallback onTap;
  final VoidCallback onAbsen;

  @override
  Widget build(BuildContext context) {
    const kecil = TextStyle(fontSize: 11, color: AppColors.inkMuted);

    return TicketCard(
      jamMulai: Fmt.jam(jadwal.jamMulai),
      jamSelesai: Fmt.jam(jadwal.jamSelesai),
      labelAtas: 'Jam ${jadwal.jamKe}',
      sorot: berjalan,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  jadwal.mapel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(jadwal.statusKelas),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Kelas ${jadwal.namaKelas} • ${jadwal.ruang ?? '-'}',
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          if (jadwal.guruPengganti != null) Text('Pengganti: ${jadwal.guruPengganti}', style: kecil),
          if (jadwal.hadir && jadwal.beritaAcara == null)
            const Text(
              'Berita acara belum diisi',
              style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
            ),
          if (jadwal.pernahDiubah) Text('Diubah ${Fmt.waktu(jadwal.diubahPada!)}', style: kecil),
          if (berjalan && !jadwal.sudahDiabsen) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: const Text('Absen Mengajar'),
              onPressed: onAbsen,
            ),
          ],
        ],
      ),
    );
  }
}
