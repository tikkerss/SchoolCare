import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.ikon, required this.label});
  final IconData ikon;
  final String label;
}

/// Navigasi bawah SchoolCare: frame putih bersudut atas 26, bayangan lembut ke atas, tinggi ±80.
/// Item aktif = kotak pink 40×40 radius 10, ikon putih, label Bold.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.index, required this.onTap});

  final List<AppBottomNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: AppColors.navShadow,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _Item(item: items[i], aktif: i == index, onTap: () => onTap(i))),
            ]),
          ),
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.item, required this.aktif, required this.onTap});

  final AppBottomNavItem item;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: aktif,
        label: item.label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: aktif ? AppColors.pink : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.ikon, size: 22, color: aktif ? AppColors.white : AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.ink,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ]),
        ),
      );
}
