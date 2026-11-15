import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';

/// SEMENTARA – nanti diisi FE Wali Kelas. Jangan ganti nama file/class.
class WaliHomePage extends StatelessWidget {
  const WaliHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final kelasId = context.watch<AuthProvider>().kelasWaliId;
    return Scaffold(
      appBar: AppBar(title: const Text('Wali Kelas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'TODO FE Wali Kelas: absensi pagi, rekap kehadiran, kontak orang tua, rapor.\n\n'
          'Kelas yang diwalikan: $kelasId',
        ),
      ),
    );
  }
}
