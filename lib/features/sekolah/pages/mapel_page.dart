import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Kelola daftar mata pelajaran (dipakai saat menyusun jadwal).
class MapelPage extends StatefulWidget {
  const MapelPage({super.key});

  @override
  State<MapelPage> createState() => _MapelPageState();
}

class _MapelPageState extends State<MapelPage> {
  final _repo = SekolahRepository();
  late Future<List<MataPelajaran>> _future = _repo.getMapel();

  void _muatUlang() => setState(() => _future = _repo.getMapel());

  Future<void> _form([MataPelajaran? m]) async {
    final kode = TextEditingController(text: m?.kode);
    final nama = TextEditingController(text: m?.nama);
    final formKey = GlobalKey<FormState>();

    final simpan = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(m == null ? 'Mata pelajaran baru' : 'Ubah mata pelajaran'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: kode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Kode', hintText: 'MTK'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: nama,
              decoration: const InputDecoration(labelText: 'Nama', hintText: 'Matematika'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (simpan == true && mounted) {
      final ok = await AdminUi.jalankan(
        context,
        () => _repo.simpanMapel(id: m?.id, kode: kode.text, nama: nama.text),
        sukses: 'Mata pelajaran disimpan',
      );
      if (ok) _muatUlang();
    }
    kode.dispose();
    nama.dispose();
  }

  Future<void> _hapus(MataPelajaran m) async {
    if (!await AdminUi.konfirmasi(context, 'Hapus ${m.nama}?',
        'Mata pelajaran yang sudah dipakai di jadwal/nilai tidak bisa dihapus.')) {
      return;
    }
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusMapel(m.id), sukses: 'Dihapus')) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mata Pelajaran')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _form(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        body: LembarPutih(child: AsyncView<List<MataPelajaran>>(
          future: _future,
          onRetry: _muatUlang,
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Belum ada mata pelajaran.',
          builder: (context, list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(m.kode.length > 3 ? m.kode.substring(0, 3) : m.kode)),
                  title: Text(m.nama),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _hapus(m)),
                  onTap: () => _form(m),
                ),
              );
            },
          ),
        )),
      );
}
