import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/tugas_repository.dart';
import 'package:schoolcare/features/guru/models/tugas.dart';
import 'package:schoolcare/features/guru/pages/tugas_detail_page.dart';
import 'package:schoolcare/features/guru/pages/tugas_form_page.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Tab Tugas: daftar tugas buatan guru + tombol tambah.
class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  final _repo = TugasRepository();
  late Future<List<TugasGuru>> _future = _repo.getTugasSaya();

  void _muatUlang() => setState(() {
        _future = _repo.getTugasSaya();
      });

  Future<void> _buka(Widget halaman) async {
    await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => halaman));
    if (mounted) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tugas')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
        onPressed: () => _buka(const TugasFormPage()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _muatUlang();
          await _future;
        },
        child: AsyncView<List<TugasGuru>>(
          future: _future,
          onRetry: _muatUlang,
          isEmpty: (list) => list.isEmpty,
          emptyMessage: 'Belum ada tugas.\nTekan "Tambah Tugas" untuk membuat tugas pertama.',
          emptyIcon: Icons.assignment_outlined,
          builder: (context, list) {
            final aktif = list.where((t) => !t.lewat).toList()..sort((a, b) => a.tenggat.compareTo(b.tenggat));
            final lewat = list.where((t) => t.lewat).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: [
                if (aktif.isNotEmpty) ...[
                  const SectionHeader('Belum lewat deadline'),
                  for (final t in aktif)
                    _TugasCard(
                      tugas: t,
                      onTap: () => _buka(TugasDetailPage(tugas: t)),
                    ),
                ],
                if (lewat.isNotEmpty) ...[
                  const SectionHeader('Sudah lewat deadline'),
                  for (final t in lewat)
                    _TugasCard(
                      tugas: t,
                      onTap: () => _buka(TugasDetailPage(tugas: t)),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TugasCard extends StatelessWidget {
  const _TugasCard({required this.tugas, required this.onTap});

  final TugasGuru tugas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semuaDinilai = tugas.jumlahSiswa > 0 && tugas.dinilai >= tugas.jumlahSiswa;
    const kecil = TextStyle(fontSize: 11, color: AppColors.inkMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tugas.judul,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(label: tugas.mapel, gaya: GayaChip.softPink),
              ],
            ),
            const SizedBox(height: 2),
            Text('Kelas ${tugas.namaKelas}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: tugas.lewat ? AppColors.pink : AppColors.inkMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Deadline ${Fmt.waktu(tugas.tenggat)}',
                    style: kecil.copyWith(color: tugas.lewat ? AppColors.pink : null),
                  ),
                ),
                StatusPill(
                  label: 'Dinilai ${tugas.dinilai}/${tugas.jumlahSiswa}',
                  gaya: semuaDinilai ? GayaChip.pink : GayaChip.softYellow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
