import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/data/info_models.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

const _kategoriAgenda = {
  'kegiatan': 'Kegiatan',
  'ujian': 'Ujian',
  'libur': 'Libur',
  'pembagian_rapor': 'Pembagian rapor',
  'lainnya': 'Lainnya',
};

/// Kelola agenda / kalender sekolah: kegiatan, ujian, libur, pembagian rapor.
/// Agenda dengan "menggantikan pelajaran" akan tampil sebagai "Sedang ada kegiatan" di aktivitas harian.
class AgendaAdminPage extends StatefulWidget {
  const AgendaAdminPage({super.key});

  @override
  State<AgendaAdminPage> createState() => _AgendaAdminPageState();
}

class _AgendaAdminPageState extends State<AgendaAdminPage> {
  final _repo = SekolahRepository();
  late Future<List<Agenda>> _future = _repo.getAgendaAdmin();

  void _muatUlang() => setState(() => _future = _repo.getAgendaAdmin());

  Future<void> _bukaForm([Agenda? a]) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _AgendaForm(agenda: a)));
    if (ok == true) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Agenda / Kalender')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _bukaForm(),
          icon: const Icon(Icons.add),
          label: const Text('Agenda baru'),
        ),
        body: RefreshIndicator(
          onRefresh: () async => _muatUlang(),
          child: AsyncView<List<Agenda>>(
            future: _future,
            onRetry: _muatUlang,
            isEmpty: (d) => d.isEmpty,
            emptyMessage: 'Belum ada agenda.',
            builder: (context, list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = list[i];
                final tanggal = a.mulai == a.selesai
                    ? Fmt.tanggal(a.mulai)
                    : '${Fmt.tanggal(a.mulai)} – ${Fmt.tanggal(a.selesai)}';
                return Card(
                  child: ListTile(
                    title: Text(a.judul),
                    subtitle: Text([
                      _kategoriAgenda[a.kategori] ?? a.kategori,
                      tanggal,
                      if (!a.untukSemuaKelas) '${a.kelasIds.length} kelas',
                      if (a.menggantikanPelajaran) 'menggantikan pelajaran',
                    ].join(' · ')),
                    onTap: () => _bukaForm(a),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _AgendaForm extends StatefulWidget {
  const _AgendaForm({this.agenda});

  final Agenda? agenda;

  @override
  State<_AgendaForm> createState() => _AgendaFormState();
}

class _AgendaFormState extends State<_AgendaForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _judul = TextEditingController(text: widget.agenda?.judul);
  late final _deskripsi = TextEditingController(text: widget.agenda?.deskripsi);
  late final _lokasi = TextEditingController(text: widget.agenda?.lokasi);
  late final _pakaian = TextEditingController(text: widget.agenda?.pakaian);
  late final _perlengkapan = TextEditingController(text: widget.agenda?.perlengkapan);
  late final _lain = TextEditingController(text: widget.agenda?.ketentuanLain);
  late String _kategori = widget.agenda?.kategori ?? 'kegiatan';
  late DateTime? _mulai = widget.agenda?.mulai;
  late DateTime? _selesai = widget.agenda?.selesai;
  late String? _jamMulai = widget.agenda?.jamMulai;
  late String? _jamSelesai = widget.agenda?.jamSelesai;
  late bool _pakaiJam = widget.agenda?.jamMulai != null;
  late bool _gantiPelajaran = widget.agenda?.menggantikanPelajaran ?? false;
  late bool _semuaKelas = widget.agenda?.untukSemuaKelas ?? true;
  late final Set<String> _kelasIds = {...?widget.agenda?.kelasIds};
  late final Future<List<Kelas>> _kelas = _kelasTahunAktif();
  bool _menyimpan = false;

  Future<List<Kelas>> _kelasTahunAktif() async {
    final ta = await _repo.getTahunAjaranAktif();
    return _repo.getKelas(tahunAjaranId: ta?.id);
  }

  @override
  void dispose() {
    for (final c in [_judul, _deskripsi, _lokasi, _pakaian, _perlengkapan, _lain]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _teks(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selesai!.isBefore(_mulai!)) {
      AdminUi.snack(context, 'Tanggal selesai tidak boleh sebelum tanggal mulai', error: true);
      return;
    }
    if (_pakaiJam && (_jamMulai == null || _jamSelesai == null)) {
      AdminUi.snack(context, 'Lengkapi jam mulai dan jam selesai', error: true);
      return;
    }
    if (!_semuaKelas && _kelasIds.isEmpty) {
      AdminUi.snack(context, 'Pilih minimal satu kelas', error: true);
      return;
    }
    setState(() => _menyimpan = true);
    final data = <String, dynamic>{
      'judul': _judul.text.trim(),
      'deskripsi': _teks(_deskripsi),
      'kategori': _kategori,
      'tanggal_mulai': Fmt.db(_mulai!),
      'tanggal_selesai': Fmt.db(_selesai!),
      'jam_mulai': _pakaiJam ? Fmt.jam(_jamMulai!) : null,
      'jam_selesai': _pakaiJam ? Fmt.jam(_jamSelesai!) : null,
      'lokasi': _teks(_lokasi),
      'ketentuan_pakaian': _teks(_pakaian),
      'perlengkapan': _teks(_perlengkapan),
      'ketentuan_lain': _teks(_lain),
      'menggantikan_pelajaran': _gantiPelajaran,
      'untuk_semua_kelas': _semuaKelas,
    };
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanAgenda(id: widget.agenda?.id, data: data, kelasIds: _kelasIds.toList()),
      sukses: 'Agenda disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _hapus() async {
    if (!await AdminUi.konfirmasi(context, 'Hapus agenda?', widget.agenda!.judul)) return;
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusAgenda(widget.agenda!.id), sukses: 'Dihapus') && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.agenda == null ? 'Agenda Baru' : 'Ubah Agenda'),
          actions: [
            if (widget.agenda != null) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _hapus),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Judul', hintText: 'Jumat Sehat'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final e in _kategoriAgenda.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _kategori = v ?? _kategori),
            ),
            const SizedBox(height: 16),
            TanggalField(
              label: 'Tanggal mulai',
              nilai: _mulai,
              onChanged: (d) => setState(() {
                _mulai = d;
                _selesai ??= d;
              }),
            ),
            const SizedBox(height: 16),
            TanggalField(label: 'Tanggal selesai', nilai: _selesai, onChanged: (d) => setState(() => _selesai = d)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ada jam tertentu'),
              value: _pakaiJam,
              onChanged: (v) => setState(() => _pakaiJam = v),
            ),
            if (_pakaiJam)
              Row(children: [
                Expanded(child: JamField(label: 'Mulai', nilai: _jamMulai, onChanged: (t) => setState(() => _jamMulai = t))),
                const SizedBox(width: 12),
                Expanded(
                  child: JamField(label: 'Selesai', nilai: _jamSelesai, onChanged: (t) => setState(() => _jamSelesai = t)),
                ),
              ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Menggantikan jam pelajaran'),
              subtitle: const Text('Di aktivitas harian akan tampil "Sedang ada kegiatan: …"'),
              value: _gantiPelajaran,
              onChanged: (v) => setState(() => _gantiPelajaran = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Untuk semua kelas'),
              value: _semuaKelas,
              onChanged: (v) => setState(() => _semuaKelas = v),
            ),
            if (!_semuaKelas)
              FutureBuilder<List<Kelas>>(
                future: _kelas,
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final k in snap.data!)
                      FilterChip(
                        label: Text(k.namaKelas),
                        selected: _kelasIds.contains(k.id),
                        onSelected: (pilih) => setState(() => pilih ? _kelasIds.add(k.id) : _kelasIds.remove(k.id)),
                      ),
                  ]);
                },
              ),
            const SizedBox(height: 16),
            TextFormField(controller: _lokasi, decoration: const InputDecoration(labelText: 'Lokasi (opsional)')),
            const SizedBox(height: 16),
            TextFormField(controller: _pakaian, decoration: const InputDecoration(labelText: 'Ketentuan pakaian (opsional)')),
            const SizedBox(height: 16),
            TextFormField(controller: _perlengkapan, decoration: const InputDecoration(labelText: 'Perlengkapan (opsional)')),
            const SizedBox(height: 16),
            TextFormField(controller: _lain, decoration: const InputDecoration(labelText: 'Ketentuan lain (opsional)')),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsi,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
          ]),
        ),
      );
}
