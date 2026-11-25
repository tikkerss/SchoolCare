import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/data/info_models.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

const _kategori = {
  'umum': 'Umum',
  'kegiatan': 'Kegiatan',
  'kebijakan': 'Kebijakan',
  'perubahan_jadwal': 'Perubahan jadwal',
};

/// Buat, ubah, terbitkan/sembunyikan, dan hapus pengumuman.
/// Pengumuman yang diterbitkan langsung tampil di aplikasi semua peran.
class PengumumanAdminPage extends StatefulWidget {
  const PengumumanAdminPage({super.key});

  @override
  State<PengumumanAdminPage> createState() => _PengumumanAdminPageState();
}

class _PengumumanAdminPageState extends State<PengumumanAdminPage> {
  final _repo = SekolahRepository();
  late Future<List<Pengumuman>> _future = _repo.getPengumumanAdmin();

  void _muatUlang() => setState(() => _future = _repo.getPengumumanAdmin());

  Future<void> _bukaForm([Pengumuman? p]) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _PengumumanForm(p: p)));
    if (ok == true) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pengumuman')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _bukaForm(),
          icon: const Icon(Icons.campaign),
          label: const Text('Buat pengumuman'),
        ),
        body: LembarPutih(child: RefreshIndicator(
          onRefresh: () async => _muatUlang(),
          child: AsyncView<List<Pengumuman>>(
            future: _future,
            onRetry: _muatUlang,
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Belum ada pengumuman.',
            builder: (context, list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = list[i];
                return Card(
                  child: ListTile(
                    title: Text(p.judul, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${_kategori[p.kategori] ?? p.kategori} · ${Fmt.tanggal(p.tanggal)}\n${p.isi}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: p.isPublished
                        ? null
                        : const Text('Draf', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                    onTap: () => _bukaForm(p),
                  ),
                );
              },
            ),
          ),
        )),
      );
}

class _PengumumanForm extends StatefulWidget {
  const _PengumumanForm({this.p});

  final Pengumuman? p;

  @override
  State<_PengumumanForm> createState() => _PengumumanFormState();
}

class _PengumumanFormState extends State<_PengumumanForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _judul = TextEditingController(text: widget.p?.judul);
  late final _isi = TextEditingController(text: widget.p?.isi);
  late final _lampiran = TextEditingController(text: widget.p?.lampiranUrl);
  late String _kat = widget.p?.kategori ?? 'umum';
  late bool _terbit = widget.p?.isPublished ?? true;
  bool _menyimpan = false;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    _lampiran.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanPengumuman(
        id: widget.p?.id,
        judul: _judul.text,
        isi: _isi.text,
        kategori: _kat,
        terbitkan: _terbit,
        lampiranUrl: _lampiran.text,
      ),
      sukses: _terbit ? 'Pengumuman diterbitkan' : 'Disimpan sebagai draf',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _hapus() async {
    if (!await AdminUi.konfirmasi(context, 'Hapus pengumuman?', widget.p!.judul)) return;
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusPengumuman(widget.p!.id), sukses: 'Dihapus') && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.p == null ? 'Pengumuman Baru' : 'Ubah Pengumuman'),
          actions: [
            if (widget.p != null) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _hapus),
          ],
        ),
        body: LembarPutih(child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kat,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final e in _kategori.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _kat = v ?? _kat),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isi,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Isi pengumuman', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lampiran,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Link lampiran (opsional)',
                hintText: 'https://…',
                helperText: 'Misalnya link Google Drive ke file PDF',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                return (t.isEmpty || t.startsWith('http')) ? null : 'Harus diawali http:// atau https://';
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Terbitkan sekarang'),
              subtitle: const Text('Kalau dimatikan, disimpan sebagai draf dan belum terlihat pengguna.'),
              value: _terbit,
              onChanged: (v) => setState(() => _terbit = v),
            ),
            const SizedBox(height: 16),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
          ]),
        )),
      );
}
