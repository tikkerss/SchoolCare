import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Penanda bahwa widget di bawahnya digambar di atas permukaan putih (kartu,
/// lembar putih). Tanpa penanda ini, widget dianggap ada langsung di atas latar
/// halaman yang pink, sehingga teks & ikonnya harus putih.
class Permukaan extends InheritedWidget {
  const Permukaan.putih({super.key, required super.child});

  /// true = di dalam kartu/lembar putih; false = langsung di atas latar pink.
  static bool diPutih(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Permukaan>() != null;

  /// Warna teks utama yang sesuai permukaan.
  static Color teks(BuildContext context) => diPutih(context) ? AppColors.ink : AppColors.white;

  /// Warna teks keterangan yang sesuai permukaan.
  static Color teksRedup(BuildContext context) => diPutih(context) ? AppColors.inkMuted : AppColors.white;

  @override
  bool updateShouldNotify(Permukaan oldWidget) => false;
}

/// Lembar putih bersudut membulat di atas latar pink. Dipakai sebagai isi
/// halaman yang kontennya berupa daftar/form polos, supaya tetap "di kartu putih".
class LembarPutih extends StatelessWidget {
  const LembarPutih({super.key, required this.child, this.margin = const EdgeInsets.only(top: 4)});

  final Widget child;
  final EdgeInsetsGeometry margin;

  static const _radius = BorderRadius.vertical(top: Radius.circular(22));

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin,
        // Material (bukan ColoredBox) supaya ripple ListTile/InkWell tergambar di lembar ini.
        child: Material(
          color: AppColors.white,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: Permukaan.putih(child: SizedBox.expand(child: child)),
        ),
      );
}

/// Bilah putih untuk tombol di bawah halaman (bottomNavigationBar), supaya
/// tombol pink tidak menempel di atas latar pink.
class BilahBawahPutih extends StatelessWidget {
  const BilahBawahPutih({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.white, boxShadow: AppColors.navShadow),
        child: Material(
          type: MaterialType.transparency,
          child: Permukaan.putih(child: SafeArea(top: false, child: child)),
        ),
      );
}
