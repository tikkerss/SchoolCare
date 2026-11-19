import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

/// Tampil sebentar saat aplikasi dibuka dan profil sedang dimuat.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.school_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'SchoolCare',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ]),
        ),
      );
}
