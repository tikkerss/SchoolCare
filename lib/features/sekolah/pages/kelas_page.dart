import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Kelola kelas per tahun ajaran + penetapan wali kelas.
class KelasPage extends StatefulWidget {
  const KelasPage({super.key});

  @override
  State<KelasPage> createState() => _KelasPageState();
}

class _KelasPageState extends State<KelasPage> {
  final _repo = SekolahRepository();
  List<TahunAjaran>? _daftarTa;
  String? _taId; // tahun ajaran yang sedang ditampilkan
  Future<List<Kelas>>? _future;

  @override
  void initState() {
    super.initState();
    _muatTahunAjaran();
  }

  Future<void> _muatTahunAjaran() async {
    try {
      final list = await _repo.getTahunAjaran();
      if (!mounted) return;
      final aktif = list.where((t) => t.isActive);
      setState(() {
        _daftarTa = list;
        _taId = aktif.isNotEmpty ? aktif.first.id : (list.isEmpty ? null : list.first.id);
        _future = _taId == null ? null : _repo.getKelas(tahunAjaranId: _taId);
      });
    } catch (e) {
      if (mounted) AdminUi.snack(context, AdminUi.pesanError(e), error: true);
    }
  }

  void _muatUlang() => setState(() => _future = _repo.getKelas(tahunAjaranId: _taId));

  Future<void> _bukaForm([Kelas? k]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _KelasForm(kelas: k, tahunAjaranId: _taId!)),
    );
    if (ok == true) _muatUlang();
  }

  Future<void> _hapus(Kelas k) async {
    if (!await AdminUi.konfirmasi(context, 'Hapus kelas ${k.namaKelas}?',
        'Jadwal kelas ini juga ikut terhapus. Siswa di kelas ini menjadi tanpa kelas.')) {
      return;
    }
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusKelas(k.id), sukses: 'Kelas dihapus')) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final daftarTa = _daftarTa;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelas & Wali Kelas')),
      floatingActionButton: _taId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _bukaForm(),
              icon: const Icon(Icons.add),
              label: const Text('Kelas baru'),
            ),
      body: daftarTa == null
          ? const LoadingView()
          : daftarTa.isEmpty
              ? const EmptyState(message: 'Buat tahun ajaran dulu di menu Tahun Ajaran.')
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<String>(
                      initialValue: _taId,
                      decoration: const InputDecoration(labelText: 'Tahun ajaran'),
                      items: [
                        for (final t in daftarTa)
                          DropdownMenuItem(value: t.id, child: Text('${t.nama}${t.isActive ? ' (aktif)' : ''}')),
                      ],
                      onChanged: (v) {
                        _taId = v;
                        _muatUlang();
                      },
                    ),
                  ),
                  Expanded(
                    child: AsyncView<List<Kelas>>(
                      future: _future!,
                      onRetry: _muatUlang,
                      isEmpty: (d) => d.isEmpty,
                      emptyMessage: 'Belum ada kelas di tahun ajaran ini.',
                      builder: (context, list) => ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final k = list[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Text(k.namaKelas)),
                              title: Text('Kelas ${k.namaKelas}'),
                              subtitle: Text('Wali: ${k.waliNama ?? 'belum ditentukan'}'
                                  '${k.ruang != null ? ' · ${k.ruang}' : ''}'),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _hapus(k)),
                              onTap: () => _bukaForm(k),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ]),
    );
  }
}

class _KelasForm extends StatefulWidget {
  const _KelasForm({this.kelas, required this.tahunAjaranId});

  final Kelas? kelas;
  final String tahunAjaranId;

  @override
  State<_KelasForm> createState() => _KelasFormState();
}

class _KelasFormState extends State<_KelasForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.kelas?.namaKelas);
  late final _tingkat = TextEditingController(text: widget.kelas?.tingkat.toString());
  late final _ruang = TextEditingController(text: widget.kelas?.ruang);
  late String? _waliId = widget.kelas?.waliKelasId;
  late final Future<List<Profile>> _guru = _repo.getAkun(role: UserRole.guru);
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    _tingkat.dispose();
    _ruang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanKelas(
        id: widget.kelas?.id,
        tahunAjaranId: widget.kelas?.tahunAjaranId ?? widget.tahunAjaranId,
        namaKelas: _nama.text,
        tingkat: int.parse(_tingkat.text.trim()),
        ruang: _ruang.text,
        waliKelasId: _waliId,
      ),
      sukses: 'Kelas disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.kelas == null ? 'Kelas Baru' : 'Ubah Kelas')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama kelas', hintText: '7A'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tingkat,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tingkat (1–12)', hintText: '7'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1 || n > 12) ? 'Isi angka 1–12' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _ruang, decoration: const InputDecoration(labelText: 'Ruang (opsional)')),
            const SizedBox(height: 16),
            FutureBuilder<List<Profile>>(
              future: _guru,
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final guru = snap.data!.where((g) => g.isActive).toList();
                return DropdownButtonFormField<String?>(
                  initialValue: guru.any((g) => g.id == _waliId) ? _waliId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Wali kelas',
                    helperText: 'Satu guru hanya boleh menjadi wali satu kelas per tahun ajaran',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('— Belum ditentukan —')),
                    for (final g in guru) DropdownMenuItem<String?>(value: g.id, child: Text(g.namaLengkap)),
                  ],
                  onChanged: (v) => setState(() => _waliId = v),
                );
              },
            ),
            const SizedBox(height: 24),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
          ]),
        ),
      );
}
