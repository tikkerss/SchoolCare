import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

class AppBottomNavItem {
  const AppBottomNavItem({required this.ikon, required this.label});
  final IconData ikon;
  final String label;
}

/// Navigasi bawah SchoolCare, model lekukan (notch), serba putih:
/// - bar putih melayang (margin 14 kiri-kanan, 16 dari bawah, tinggi 64, radius 20, bayangan lembut);
/// - ikon tidak aktif: garis ink tanpa label;
/// - item aktif: lingkaran putih 54px berikon pink yang naik setengah di atas bar, dengan
///   lekukan melengkung di bar di bawahnya, plus label (w800, 10px) di bawah lingkaran;
/// - lingkaran & lekukan bergeser ±250ms saat pindah tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.items, required this.index, required this.onTap});

  final List<AppBottomNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  static const _tinggiBar = 64.0;
  static const _diameter = 54.0;

  /// Bagian lingkaran yang menonjol di atas bar (setengahnya).
  static const _naik = _diameter / 2;

  /// Jarak lekukan dari tepi lingkaran.
  static const _celah = 5.0;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: SizedBox(
            height: _naik + _tinggiBar,
            child: LayoutBuilder(builder: (context, c) {
              final lebarItem = c.maxWidth / items.length;
              return TweenAnimationBuilder<double>(
                tween: Tween(end: index.toDouble()),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, posisi, _) {
                  final cx = (posisi + 0.5) * lebarItem;
                  return Stack(clipBehavior: Clip.none, children: [
                    // ---- bar putih dengan lekukan
                    Positioned.fill(
                      child: CustomPaint(painter: _BarLekukPainter(cx: cx, atas: _naik, radiusLekuk: _naik + _celah)),
                    ),
                    // ---- ikon tidak aktif + area ketuk tiap item
                    Positioned.fill(
                      child: Row(children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == index,
                              label: items[i].label,
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onTap(i),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: _naik),
                                  child: Center(
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 150),
                                      opacity: i == index ? 0 : 1,
                                      child: Icon(items[i].ikon, size: 24, color: AppColors.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ),
                    // ---- lingkaran aktif (naik setengah di atas bar)
                    Positioned(
                      left: cx - _diameter / 2,
                      top: 0,
                      child: IgnorePointer(
                        child: Container(
                          width: _diameter,
                          height: _diameter,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Icon(items[index].ikon, size: 26, color: AppColors.pink),
                        ),
                      ),
                    ),
                    // ---- label item aktif
                    Positioned(
                      left: cx - lebarItem / 2,
                      width: lebarItem,
                      top: _diameter + 4,
                      child: IgnorePointer(
                        child: Text(
                          items[index].label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ]);
                },
              );
            }),
          ),
        ),
      );
}

/// Bar putih radius 20 dengan lekukan melengkung di bawah lingkaran aktif.
class _BarLekukPainter extends CustomPainter {
  _BarLekukPainter({required this.cx, required this.atas, required this.radiusLekuk});

  /// Titik tengah lekukan (sumbu x).
  final double cx;

  /// Jarak tepi atas bar dari atas kanvas.
  final double atas;
  final double radiusLekuk;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Rect.fromLTWH(0, atas, size.width, size.height - atas);
    final lekuk = Rect.fromCircle(center: Offset(cx, atas), radius: radiusLekuk);
    final bentuk = Path.combine(
      PathOperation.intersect,
      const CircularNotchedRectangle().getOuterPath(bar, lekuk),
      Path()..addRRect(RRect.fromRectAndRadius(bar, const Radius.circular(20))),
    );
    // Bayangan lembut (warna & tebal sama dengan bayangan kartu).
    canvas.drawShadow(bentuk, AppColors.cardShadow.first.color, 10, false);
    canvas.drawPath(bentuk, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_BarLekukPainter old) => old.cx != cx || old.atas != atas || old.radiusLekuk != radiusLekuk;
}
