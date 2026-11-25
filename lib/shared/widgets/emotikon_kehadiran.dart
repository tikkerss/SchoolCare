import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Emotikon kehadiran siswa: hadir · terlambat · izin · sakit · alpa.
/// Status lain (mis. belum diabsen) tampil sebagai lingkaran kosong bergaris softPink.
class EmotikonKehadiran extends StatelessWidget {
  const EmotikonKehadiran(this.status, {super.key, this.size = 40});

  final String? status;
  final double size;

  static const _dikenal = {'hadir', 'terlambat', 'izin', 'sakit', 'alpa'};

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null || !_dikenal.contains(s)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.softPink, width: 1.5),
        ),
      );
    }
    return SvgPicture.asset('assets/emotikon/emo_$s.svg', width: size, height: size);
  }
}

/// Maskot Tasi (tas sekolah).
class MaskotTasi extends StatelessWidget {
  const MaskotTasi({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/maskot/tasi.svg', width: size, height: size);
}
