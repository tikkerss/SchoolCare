import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../wali_kelas/utils/format_tanggal.dart';
import '../data/laporan_models.dart';
import '../widgets/status_guru_badge.dart';

class DetailAbsensiGuruPage extends StatelessWidget {
  const DetailAbsensiGuruPage({super.key, required this.item});

  final AbsensiGuruItem item;

  Future<void> _bukaMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${item.lat},${item.lng}',
    );
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // gagal membuka, ditangani di bawah
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps tidak bisa dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = item;
    final judul = Theme.of(context).textTheme.titleSmall;

    return Scaffold(
      appBar: AppBar(title: Text('${a.mapel} • ${a.kelas}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${a.guru}\n${formatTanggal(a.tanggal)} • Jam ke-${a.jamKe} '
                  '(${formatJam(a.jamMulai)})',
                ),
              ),
              StatusGuruBadge(a),
            ],
          ),
          const SizedBox(height: 16),
          if (a.status == StatusKehadiranGuru.hadir)
            ..._bagianHadir(context, judul),
          if (a.status == StatusKehadiranGuru.tidakHadir)
            ..._bagianTidakHadir(judul),
        ],
      ),
    );
  }

  List<Widget> _bagianHadir(BuildContext context, TextStyle? judul) {
    final a = item;
    final jarak = a.jarakDariSekolah!;
    final warnaLokasi = a.diLuarArea
        ? const Color(0xFFD64545)
        : const Color(0xFF2E9E5B);

    return [
      Text('Foto Bukti', style: judul),
      const SizedBox(height: 8),
      // Di versi Supabase:
      // final url = await db.storage.from('absensi-guru').createSignedUrl(a.fotoPath!, 3600);
      // lalu tampilkan dengan Image.network(url, fit: BoxFit.cover).
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            color: Colors.grey.shade300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text('Foto dummy\n${a.fotoPath}', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Diambil ${formatJam(a.waktuFoto!)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),

      const SizedBox(height: 16),
      Text('Lokasi', style: judul),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    a.diLuarArea ? Icons.location_off : Icons.location_on,
                    color: warnaLokasi,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.diLuarArea
                          ? 'Di luar area sekolah (${_formatJarak(jarak)} dari sekolah)'
                          : 'Di area sekolah (${_formatJarak(jarak)} dari titik sekolah)',
                      style: TextStyle(
                        color: warnaLokasi,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${a.lat!.toStringAsFixed(6)}, ${a.lng!.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _bukaMaps(context),
                icon: const Icon(Icons.map),
                label: const Text('Buka di Google Maps'),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 16),
      Text('Berita Acara', style: judul),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(a.beritaAcara ?? '-'),
        ),
      ),
    ];
  }

  List<Widget> _bagianTidakHadir(TextStyle? judul) {
    final a = item;
    return [
      Text('Keterangan Tidak Hadir', style: judul),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Alasan'),
              subtitle: Text(a.keterangan ?? '-'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Surat'),
              subtitle: Text(a.suratPath?.split('/').last ?? 'Tidak ada'),
              // Versi Supabase: buka dengan createSignedUrl + url_launcher.
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Guru pengganti'),
              subtitle: Text(a.guruPengganti ?? 'Tidak ada'),
            ),
            ListTile(
              leading: const Icon(Icons.class_outlined),
              title: const Text('Status kelas'),
              subtitle: Text(a.statusKelas?.label ?? '-'),
            ),
          ],
        ),
      ),
    ];
  }

  String _formatJarak(double m) => m >= 1000
      ? '${(m / 1000).toStringAsFixed(1)} km'
      : '${m.toStringAsFixed(0)} m';
}
