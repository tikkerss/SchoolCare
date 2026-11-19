import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/shared/data/info_models.dart';
import 'package:schoolcare/shared/data/info_repository.dart';
import 'package:schoolcare/shared/services/link_service.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Daftar pengumuman sekolah (semua peran). Detail dibuka lewat bottom sheet.
class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  final _repo = InfoRepository();
  late Future<List<Pengumuman>> _future = _repo.getPengumuman();

  void _reload() => setState(() => _future = _repo.getPengumuman());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengumuman')),
        body: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: AsyncView<List<Pengumuman>>(
            future: _future,
            onRetry: _reload,
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Belum ada pengumuman.',
            emptyIcon: Icons.campaign_outlined,
            builder: (context, list) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = list[i];
                return Card(
                  child: ListTile(
                    title: Text(p.judul, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${Fmt.tanggal(p.tanggal)} · ${p.isi}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: p.lampiranUrl == null ? null : const Icon(Icons.attach_file, size: 18),
                    onTap: () => _detail(p),
                  ),
                );
              },
            ),
          ),
        ),
      );

  void _detail(Pengumuman p) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text(p.judul, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(Fmt.waktu(p.tanggal), style: const TextStyle(color: AppColors.textSecondary)),
              const Divider(height: 32),
              Text(p.isi),
              if (p.lampiranUrl != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Buka lampiran'),
                  onPressed: () => LinkService.buka(p.lampiranUrl!),
                ),
              ],
            ],
          ),
        ),
      );
}
