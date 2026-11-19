import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Kotak menu berikon untuk grid menu di beranda.
class MenuTile extends StatelessWidget {
  const MenuTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}
