import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Emotikon kehadiran siswa: hadir · terlambat · izin · sakit · alpa.
/// Status lain (mis. belum diabsen) tampil sebagai emotikon netral bergaris putus-putus pink.
class EmotikonKehadiran extends StatelessWidget {
  const EmotikonKehadiran(this.status, {super.key, this.size = 40});

  final String? status;
  final double size;

  static const _dikenal = {'hadir', 'terlambat', 'izin', 'sakit', 'alpa'};

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null || !_dikenal.contains(s)) {
      // Belum diabsen: emotikon netral (softYellow, garis putus pink, mata titik, mulut datar).
      return SvgPicture.asset(
        'assets/emotikon/emo_belum.svg',
        width: size,
        height: size,
        semanticsLabel: 'Belum diabsen',
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
