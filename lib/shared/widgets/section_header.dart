import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Judul bagian + tombol aksi opsional di kanan ("Lihat semua").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel = 'Lihat semua', this.onAction});

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: Permukaan.teks(context)),
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: Permukaan.diPutih(context) ? null : TextButton.styleFrom(foregroundColor: AppColors.white),
              child: Text(actionLabel),
            ),
        ]),
      );
}
