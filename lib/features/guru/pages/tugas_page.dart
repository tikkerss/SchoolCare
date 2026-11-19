import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/data/tugas_repository.dart';
import 'package:schoolcare/features/guru/models/tugas.dart';
import 'package:schoolcare/features/guru/pages/tugas_detail_page.dart';
import 'package:schoolcare/features/guru/pages/tugas_form_page.dart';
import 'package:schoolcare/shared/widgets/section_header.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Tab Tugas: daftar tugas buatan guru + tombol tambah.
class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  final _repo = TugasRepository();
  late Future<List<TugasGuru>> _future = _repo.getTugasSaya();

  void _muatUlang() => setState(() => _future = _repo.getTugasSaya());

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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                if (aktif.isNotEmpty) ...[
                  const SectionHeader('Belum lewat deadline'),
                  for (final t in aktif) _TugasCard(tugas: t, onTap: () => _buka(TugasDetailPage(tugas: t))),
                ],
                if (lewat.isNotEmpty) ...[
                  const SectionHeader('Sudah lewat deadline'),
                  for (final t in lewat) _TugasCard(tugas: t, onTap: () => _buka(TugasDetailPage(tugas: t))),
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
    final theme = Theme.of(context);
    final semuaDinilai = tugas.jumlahSiswa > 0 && tugas.dinilai >= tugas.jumlahSiswa;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tugas.judul, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${tugas.mapel} • Kelas ${tugas.namaKelas}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.event_outlined, size: 16, color: tugas.lewat ? AppColors.danger : AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Deadline ${Fmt.waktu(tugas.tenggat)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: tugas.lewat ? AppColors.danger : null),
                  ),
                ),
                Text(
                  'Dinilai ${tugas.dinilai}/${tugas.jumlahSiswa}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: semuaDinilai ? AppColors.success : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
