import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../wali_kelas/utils/format_tanggal.dart';
import '../data/laporan_models.dart';
import '../data/supabase_laporan_repository.dart' show urlFotoBuktiGuru, urlSuratGuru;
import '../widgets/status_guru_badge.dart';

import 'package:schoolcare/shared/widgets/permukaan.dart';

class DetailAbsensiGuruPage extends StatelessWidget {
  const DetailAbsensiGuruPage({super.key, required this.item});

  final AbsensiGuruItem item;

  /// Surat ada di bucket privat, jadi dibuka lewat URL sementara.
  Future<void> _bukaSurat(BuildContext context, String path) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(await urlSuratGuru(path)), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surat tidak dapat dibuka.')));
    }
  }

  Future<void> _bukaMaps(BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${item.lat},${item.lng}');
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // gagal membuka, ditangani di bawah
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Maps tidak bisa dibuka.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = item;
    final judul = Theme.of(context).textTheme.titleSmall;

    return Scaffold(
      appBar: AppBar(title: Text('${a.mapel} • ${a.kelas}')),
      body: LembarPutih(
        child: ListView(
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
            if (a.status == StatusKehadiranGuru.hadir) ..._bagianHadir(context, judul),
            if (a.status == StatusKehadiranGuru.tidakHadir) ..._bagianTidakHadir(context, judul),
          ],
        ),
      ),
    );
  }

  List<Widget> _bagianHadir(BuildContext context, TextStyle? judul) {
    final a = item;
    final jarak = a.jarakDariSekolah!;
    final warnaLokasi = a.diLuarArea ? AppColors.pink : AppColors.ink;

    return [
      Text('Foto Bukti', style: judul),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: _FotoBukti(path: a.fotoPath),
        ),
      ),
      const SizedBox(height: 4),
      Text('Diambil ${formatJam(a.waktuFoto!)}', style: Theme.of(context).textTheme.bodySmall),

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
                  Icon(a.diLuarArea ? Icons.location_off : Icons.location_on, color: warnaLokasi),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.diLuarArea
                          ? 'Di luar area sekolah (${_formatJarak(jarak)} dari sekolah)'
                          : 'Di area sekolah (${_formatJarak(jarak)} dari titik sekolah)',
                      style: TextStyle(color: warnaLokasi, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${a.lat!.toStringAsFixed(6)}, ${a.lng!.toStringAsFixed(6)}'),
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
        child: Padding(padding: const EdgeInsets.all(12), child: Text(a.beritaAcara ?? '-')),
      ),
    ];
  }

  List<Widget> _bagianTidakHadir(BuildContext context, TextStyle? judul) {
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
              trailing: a.suratPath == null ? null : const Icon(Icons.open_in_new),
              onTap: a.suratPath == null ? null : () => _bukaSurat(context, a.suratPath!),
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

  String _formatJarak(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toStringAsFixed(0)} m';
}

/// Foto bukti dari bucket privat `bukti-absensi-guru` (lewat URL sementara).
class _FotoBukti extends StatelessWidget {
  const _FotoBukti({required this.path});

  final String? path;

  Widget _kosong(String pesan) => Container(
    color: AppColors.softPink,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.photo_camera, size: 48, color: AppColors.inkMuted),
        const SizedBox(height: 8),
        Text(
          pesan,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkMuted),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (path == null) return _kosong('Tidak ada foto');
    return FutureBuilder<String>(
      future: urlFotoBuktiGuru(path!),
      builder: (context, snap) {
        if (snap.hasError) return _kosong('Foto tidak ditemukan');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.pink));
        return Image.network(
          snap.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _kosong('Foto tidak dapat dimuat'),
        );
      },
    );
  }
}
