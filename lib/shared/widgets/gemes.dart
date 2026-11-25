import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// "Komponen gemes" (DESIGN_HANDOFF bagian 4). Pakai 2–3 per layar saja.

// =====================================================================
// Label pill (oranye/pink, teks putih Bold, bayangan dalam di bawah)
// =====================================================================
class LabelPill extends StatelessWidget {
  const LabelPill(this.teks, {super.key, this.warna = AppColors.orange});

  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(999)),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 5),
            child: Text(
              teks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.white, height: 1.3),
            ),
          ),
          // bayangan dalam bawah
          const Positioned(left: 0, right: 0, bottom: 0, height: 2.5, child: ColoredBox(color: AppColors.bayanganDalam)),
        ]),
      );
}

// =====================================================================
// Kartu balon chat + label nama
// =====================================================================
/// Frame putih dengan ekor kecil di kiri atas dan [label] yang menempel di pinggir atas.
/// [gigitan] = dua lingkaran kecil berwarna latar pink di pojok kanan atas.
/// [intip] = widget (mis. maskot) yang mengintip dari pojok kanan bawah, terpotong kartu.
class BalonChat extends StatelessWidget {
  const BalonChat({
    super.key,
    required this.child,
    this.label,
    this.warnaLabel = AppColors.orange,
    this.gigitan = false,
    this.intip,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 16),
    this.onTap,
  });

  final Widget child;
  final String? label;
  final Color warnaLabel;
  final bool gigitan;
  final Widget? intip;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_radius);
    return Padding(
      // ruang untuk ekor & label yang menonjol di atas kartu
      padding: EdgeInsets.only(top: label == null ? 8 : 12),
      child: Stack(clipBehavior: Clip.none, children: [
        // ---- ekor kiri atas
        const Positioned(
          top: -8,
          left: 18,
          child: CustomPaint(size: Size(16, 10), painter: _EkorPainter()),
        ),
        // ---- kartu
        Container(
          decoration: BoxDecoration(color: AppColors.white, borderRadius: radius, boxShadow: AppColors.cardShadow),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Permukaan.putih(
                child: Stack(children: [
                  Padding(padding: padding, child: child),
                  if (intip != null) Positioned(right: 6, bottom: -62, child: IgnorePointer(child: intip!)),
                  if (gigitan) ...const [
                    Positioned(top: -10, right: 26, child: _Gigitan(diameter: 20)),
                    Positioned(top: 12, right: -9, child: _Gigitan(diameter: 18)),
                  ],
                ]),
              ),
            ),
          ),
        ),
        // ---- label nama
        if (label != null) Positioned(top: -11, left: 40, right: 40, child: Align(alignment: Alignment.centerLeft, child: LabelPill(label!, warna: warnaLabel))),
      ]),
    );
  }
}

class _Gigitan extends StatelessWidget {
  const _Gigitan({required this.diameter});
  final double diameter;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: const DecoratedBox(decoration: BoxDecoration(color: AppColors.pink, shape: BoxShape.circle)),
        ),
      );
}

class _EkorPainter extends CustomPainter {
  const _EkorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height + 1)
      ..quadraticBezierTo(size.width * 0.15, 0, size.width * 0.35, 0)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.55, size.width, size.height + 1)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_EkorPainter old) => false;
}

// =====================================================================
// Kotak glossy (menu/tombol)
// =====================================================================
/// Kotak berwarna dengan kilau putih 38% tipis di atas dan bayangan dalam gelap di bawah.
class KotakGlossy extends StatelessWidget {
  const KotakGlossy({super.key, required this.warna, required this.child, this.ukuran = 56, this.radius = 16});

  final Color warna;
  final Widget child;
  final double ukuran;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // kilau atas
          Positioned(
            top: 5,
            left: 9,
            right: 9,
            height: 6.5,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.kilau, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          // bayangan dalam bawah
          const Positioned(left: 0, right: 0, bottom: 0, height: 5, child: ColoredBox(color: AppColors.bayanganDalam)),
          Center(child: child),
        ]),
      );
}

// =====================================================================
// Progress bar bergaris
// =====================================================================
/// Tinggi 16, radius penuh, track softPink, isi pink bergaris miring putih 28%.
class ProgressBergaris extends StatelessWidget {
  const ProgressBergaris({super.key, required this.nilai});

  /// 0.0 – 1.0
  final double nilai;

  @override
  Widget build(BuildContext context) => Semantics(
        value: '${(nilai.clamp(0, 1) * 100).round()}%',
        child: Container(
          height: 16,
          decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(999)),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: nilai.clamp(0, 1).toDouble(),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(999)),
              child: const CustomPaint(painter: _GarisMiringPainter()),
            ),
          ),
        ),
      );
}

class _GarisMiringPainter extends CustomPainter {
  const _GarisMiringPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2)));
    final paint = Paint()..color = AppColors.garisProgress;
    const lebar = 6.0, jarak = 12.0;
    final h = size.height;
    for (var x = -h; x < size.width + h; x += jarak) {
      canvas.drawPath(
        Path()
          ..moveTo(x, h)
          ..lineTo(x + h, 0)
          ..lineTo(x + h + lebar, 0)
          ..lineTo(x + lebar, h)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GarisMiringPainter old) => false;
}

// =====================================================================
// Kertas tempel
// =====================================================================
/// Kertas softYellow dengan selotip pink transparan di atas dan pojok kanan bawah terlipat.
class KertasTempel extends StatelessWidget {
  const KertasTempel({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  static const _lipat = 22.0;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: radius, boxShadow: AppColors.cardShadow),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Permukaan.putih(
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16 + _lipat / 2, 16), child: child),
              ),
            ),
          ),
        ),
        // pojok kanan bawah terlipat
        const Positioned(
          right: 0,
          bottom: 0,
          child: IgnorePointer(child: CustomPaint(size: Size(_lipat, _lipat), painter: _LipatanPainter())),
        ),
        // selotip
        Positioned(
          top: -8,
          left: 0,
          right: 0,
          child: Center(
            child: IgnorePointer(
              child: Container(
                width: 64,
                height: 18,
                decoration: BoxDecoration(color: AppColors.selotip, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LipatanPainter extends CustomPainter {
  const _LipatanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // bagian yang "terlipat" memperlihatkan latar pink
    canvas.drawPath(
      Path()
        ..moveTo(w, 0)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = AppColors.pink,
    );
    // lipatan kertas
    final lipatan = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(lipatan, Paint()..color = AppColors.softYellow);
    canvas.drawPath(lipatan, Paint()..color = AppColors.bayanganDalam);
  }

  @override
  bool shouldRepaint(_LipatanPainter old) => false;
}
