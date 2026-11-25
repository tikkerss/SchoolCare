import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';
import '../data/guru_dummy.dart';
import '../models/jadwal.dart';
import '../widgets/status_kelas_chip.dart';
import 'absensi_mengajar_page.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _jadwal = List<Jadwal>.of(jadwalHariIni);

  Future<void> _bukaAbsensi(int i) async {
    if (_jadwal[i].status != StatusKelas.belumAbsen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam pelajaran ini sudah diabsen.')),
      );
      return;
    }

    final status = await Navigator.push<StatusKelas>(
      context,
      MaterialPageRoute(builder: (_) => AbsensiMengajarPage(jadwal: _jadwal[i])),
    );
    if (status != null) {
      setState(() => _jadwal[i] = _jadwal[i].copyWith(status: status));
    }
  }

  /// '07.00' / '07:00' → menit sejak tengah malam.
  static int _menit(String jam) {
    final p = jam.replaceAll('.', ':').split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static bool _sedangBerjalan(Jadwal j) {
    final n = DateTime.now();
    final now = n.hour * 60 + n.minute;
    return now >= _menit(j.jamMulai) && now < _menit(j.jamSelesai);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nama = auth.profile?.namaLengkap ?? '';
    final sudah = _jadwal.where((j) => j.status != StatusKelas.belumAbsen).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ---- sapaan
            Row(children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Halo, '),
                    // Nama disorot softYellow (pink tidak terbaca di atas latar pink).
                    TextSpan(text: nama, style: const TextStyle(color: AppColors.softYellow)),
                  ]),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
              ),
              if (auth.isWaliKelas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Wali Kelas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 4),
            const Text('Jadwal mengajar hari ini', style: TextStyle(fontSize: 12, color: AppColors.white)),
            const SizedBox(height: 16),

            // ---- statistik (di kartu putih supaya kotak pink tetap terlihat)
            SoftCard(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Expanded(
                  child: _KotakStat(nilai: '${_jadwal.length}', label: 'Kelas hari ini', warna: AppColors.pink),
                ),
                const SizedBox(width: 8),
                Expanded(child: _KotakStat(nilai: '$sudah', label: 'Sudah absen', warna: AppColors.orange)),
                const SizedBox(width: 8),
                Expanded(
                  child: _KotakStat(
                    nilai: '${_jadwal.length - sudah}',
                    label: 'Belum absen',
                    warna: AppColors.softYellow,
                  ),
                ),
              ]),
            ),

            // ---- absensi siswa pagi (khusus wali kelas)
            if (auth.isWaliKelas) ...[
              const SizedBox(height: 14),
              SoftCard(
                warna: AppColors.softYellow,
                onTap: () => context.push('/wali'),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.how_to_reg, color: AppColors.pink),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Absensi siswa pagi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                        'Isi kehadiran kelas perwalian hari ini',
                        style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                      ),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.ink),
                ]),
              ),
            ],

            // ---- jadwal
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 10),
              child: Text('Jadwal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
            for (var i = 0; i < _jadwal.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JadwalCard(
                  jadwal: _jadwal[i],
                  berjalan: _sedangBerjalan(_jadwal[i]),
                  onTap: () => _bukaAbsensi(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KotakStat extends StatelessWidget {
  const _KotakStat({required this.nilai, required this.label, required this.warna});

  final String nilai, label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = warna == AppColors.pink ? AppColors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(nilai, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: teks)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: teks),
        ),
      ]),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final bool berjalan;
  final VoidCallback onTap;
  const _JadwalCard({required this.jadwal, required this.berjalan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final perluAbsen = berjalan && jadwal.status == StatusKelas.belumAbsen;
    return TicketCard(
      jamMulai: jadwal.jamMulai,
      jamSelesai: jadwal.jamSelesai,
      sorot: berjalan,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jadwal.mapel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${jadwal.kelas} • ${jadwal.ruang}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          StatusKelasChip(status: jadwal.status),
        ]),
        if (perluAbsen) ...[
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.how_to_reg, size: 18),
            label: const Text('Absen Mengajar'),
            onPressed: onTap,
          ),
        ],
      ]),
    );
  }
}
