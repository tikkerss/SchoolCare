import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';

/// Menu Wali Kelas (SEMENTARA, dibuat FE Orang Tua untuk tes routing).
/// TODO(FE Wali Kelas): ganti isinya. JANGAN ganti nama file / nama class.
/// Id kelas yang diwalikan: context.read<AuthProvider>().kelasWaliId
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
