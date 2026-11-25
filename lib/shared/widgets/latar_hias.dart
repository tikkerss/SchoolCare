import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Latar halaman SchoolCare: pink polos + 2 lingkaran transparan lembut di pojok
/// (softPink 16% kanan atas, softYellow 14% kiri bawah). Tanpa rotasi, tanpa gradasi.
///
/// Dipasang otomatis untuk setiap halaman lewat [LatarHiasTransitionsBuilder]
/// (lihat `AppTheme`), jadi Scaffold cukup berlatar transparan.
class LatarHias extends StatelessWidget {
  const LatarHias({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.pink,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(top: -90, right: -70, child: _Lingkaran(diameter: 260, warna: AppColors.hiasSoftPink)),
            const Positioned(
              bottom: -80,
              left: -90,
              child: _Lingkaran(diameter: 240, warna: AppColors.hiasSoftYellow),
            ),
            child,
          ],
        ),
      );
}

class _Lingkaran extends StatelessWidget {
  const _Lingkaran({required this.diameter, required this.warna});

  final double diameter;
  final Color warna;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: DecoratedBox(decoration: BoxDecoration(color: warna, shape: BoxShape.circle)),
        ),
      );
}

/// Membungkus transisi halaman bawaan supaya setiap halaman memakai [LatarHias]
/// (latar tetap pejal selama transisi, jadi halaman lama tidak tembus).
/// Transisinya tetap bawaan platform: [PageTransitionsTheme] default yang memilih.
class LatarHiasTransitionsBuilder extends PageTransitionsBuilder {
  const LatarHiasTransitionsBuilder();

  static const _bawaan = PageTransitionsTheme();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      _bawaan.buildTransitions(route, context, animation, secondaryAnimation, LatarHias(child: child));
}
