import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';

/// Profil pengguna. Dipakai keempat peran.
/// [showAppBar] = false bila halaman ini dipakai sebagai tab di dalam halaman lain.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;
    if (p == null) return const SizedBox.shrink(); // sesaat setelah logout
    final peran = auth.isWaliKelas ? 'Guru · Wali Kelas' : p.role.label;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Profil')) : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(p.namaLengkap[0], style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(p.namaLengkap, style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text(peran)),
          const SizedBox(height: 24),
          if (auth.isWaliKelas)
            Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Menu Wali Kelas'),
                subtitle: const Text('Absensi pagi, rekap kehadiran, kontak orang tua, rapor'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/wali'),
              ),
            ),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(p.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('WhatsApp'),
                subtitle: Text(p.noWhatsapp == null ? '-' : '+${p.noWhatsapp}'),
              ),
              if (p.nip != null)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('NIP'),
                  subtitle: Text(p.nip!),
                ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Perubahan data dilakukan oleh pihak sekolah.',
              textAlign: TextAlign.center,
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Keluar dari akun?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Keluar')),
                  ],
                ),
              );
              if (ok == true && context.mounted) await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
    );
  }
}
