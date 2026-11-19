import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/shared/services/link_service.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

/// Laporan absensi mengajar guru per tanggal: status hadir, status kelas, foto bukti + lokasi GPS.
/// Data diisi oleh guru lewat halaman absen mengajar.
class LaporanGuruPage extends StatefulWidget {
  const LaporanGuruPage({super.key});

  @override
  State<LaporanGuruPage> createState() => _LaporanGuruPageState();
}

class _LaporanGuruPageState extends State<LaporanGuruPage> {
  final _repo = SekolahRepository();
  DateTime _tanggal = DateTime.now();
  late Future<List<LaporanGuru>> _future = _repo.getLaporanGuru(_tanggal);

  void _muatUlang() => setState(() => _future = _repo.getLaporanGuru(_tanggal));

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (t == null) return;
    _tanggal = t;
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('Laporan Absensi Guru'),
            Text(Fmt.hari(_tanggal), style: Theme.of(context).textTheme.bodySmall),
          ]),
          actions: [IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pilihTanggal)],
        ),
        body: RefreshIndicator(
          onRefresh: () async => _muatUlang(),
          child: AsyncView<List<LaporanGuru>>(
            future: _future,
            onRetry: _muatUlang,
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Belum ada absensi guru di tanggal ini.',
            builder: (context, list) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final l = list[i];
                final hadir = l.statusKehadiran == 'hadir';
                return Card(
                  child: ListTile(
                    leading: Icon(hadir ? Icons.check_circle : Icons.cancel,
                        color: hadir ? AppColors.success : AppColors.danger),
                    title: Text('${l.guru} · ${l.mapel}'),
                    subtitle: Text('Kelas ${l.namaKelas} · jam ke-${l.jamKe} '
                        '(${Fmt.jam(l.jamMulai)}–${Fmt.jam(l.jamSelesai)})'
                        '${l.guruPengganti != null ? '\nDigantikan ${l.guruPengganti}' : ''}'),
                    trailing: StatusBadge(l.statusKelas),
                    onTap: () => _detail(l),
                  ),
                );
              },
            ),
          ),
        ),
      );

  void _detail(LaporanGuru l) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
            Text('${l.guru} · ${l.mapel}', style: Theme.of(context).textTheme.titleLarge),
            Text('Kelas ${l.namaKelas} · ${Fmt.jam(l.jamMulai)}–${Fmt.jam(l.jamSelesai)}'),
            const SizedBox(height: 12),
            Row(children: [StatusBadge(l.statusKelas)]),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _repo.urlFotoBukti(l.fotoUrl),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Container(
                    height: 200,
                    color: AppColors.border,
                    child: snap.hasError ? const Center(child: Text('Foto tidak bisa dimuat')) : null,
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    snap.data!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(height: 200, color: AppColors.border, child: const Icon(Icons.broken_image)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Foto diambil ${Fmt.waktu(l.fotoDiambilPada)}', style: const TextStyle(color: AppColors.textSecondary)),
            TextButton.icon(
              icon: const Icon(Icons.place_outlined),
              label: Text('Lokasi ${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)} (buka peta)'),
              onPressed: () => LinkService.buka('https://www.google.com/maps?q=${l.latitude},${l.longitude}'),
            ),
            const Divider(height: 24),
            if (l.beritaAcara != null) ...[
              const Text('Berita acara', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(l.beritaAcara!),
            ],
            if (l.keteranganTidakHadir != null) ...[
              const Text('Keterangan tidak hadir', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(l.keteranganTidakHadir!),
            ],
            if (l.guruPengganti != null) Text('Guru pengganti: ${l.guruPengganti}'),
          ]),
        ),
      );
}
