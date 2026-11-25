import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/emotikon_kehadiran.dart';

/// Tampil sebentar saat aplikasi dibuka dan profil sedang dimuat.
/// Router pindah otomatis ke login/beranda, jadi tidak ada tombol "Mulai".
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        // Transparan: latar pink + hiasan dari LatarHias.
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ---- balon chat
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: AppColors.ink, height: 1.45),
                      children: [
                        TextSpan(text: 'Halo! Aku '),
                        TextSpan(
                          text: 'Tasi',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.pink),
                        ),
                        TextSpan(text: '. Aku yang kabarin kalau si kecil udah sampai sekolah.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const MaskotTasi(size: 220),
                const SizedBox(height: 8),
                const Text(
                  'SchoolCare',
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.white, height: 1.1),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hadir, belajar, dan nilai anak. Semua kabar sekolah di satu tempat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.white, height: 1.5),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                ),
              ]),
            ),
          ),
        ),
      );
}
