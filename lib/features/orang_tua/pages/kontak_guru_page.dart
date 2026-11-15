import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

/// Daftar wali kelas + guru yang mengajar anak, dengan tombol chat WhatsApp.
class KontakGuruPage extends StatefulWidget {
  const KontakGuruPage({super.key, required this.anak});

  final Anak anak;

  @override
  State<KontakGuruPage> createState() => _KontakGuruPageState();
}

class _KontakGuruPageState extends State<KontakGuruPage> {
  final _repo = OrtuRepository();
  late Future<List<KontakGuru>> _future = _muat();

  Future<List<KontakGuru>> _muat() {
    final kelasId = widget.anak.kelasId;
    return kelasId == null ? Future.value(<KontakGuru>[]) : _repo.getKontakGuru(kelasId);
  }

  void _muatUlang() => setState(() => _future = _muat());

  Future<void> _chat(KontakGuru k) async {
    final a = widget.anak;
    final pesan = 'Halo Bapak/Ibu ${k.nama}, saya orang tua dari ${a.nama} (kelas ${a.namaKelas}). ';
    final ok = await OrtuLink.whatsapp(k.noWhatsapp, pesan: pesan);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp tidak dapat dibuka.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kontak Guru')),
        body: TungguData<List<KontakGuru>>(
          future: _future,
          onCobaLagi: _muatUlang,
          kosong: (d) => d.isEmpty,
          pesanKosong: 'Belum ada data guru untuk kelas ini.',
          builder: (context, list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final k = list[i];
              final keterangan = [if (k.isWali) 'Wali Kelas', if (k.mapel != null) k.mapel!].join(' · ');
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(k.nama[0])),
                  title: Text(k.nama),
                  subtitle: keterangan.isEmpty ? null : Text(keterangan),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat),
                    color: OrtuWarna.success,
                    tooltip: 'Chat WhatsApp',
                    onPressed: k.noWhatsapp == null ? null : () => _chat(k),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
