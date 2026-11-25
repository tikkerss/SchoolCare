import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Susun jadwal pelajaran per kelas untuk semester aktif.
/// Data ini dipakai halaman Guru (jadwal mengajar) dan Orang Tua (jadwal & aktivitas harian).
class JadwalAdminPage extends StatefulWidget {
  const JadwalAdminPage({super.key});

  @override
  State<JadwalAdminPage> createState() => _JadwalAdminPageState();
}

class _JadwalAdminPageState extends State<JadwalAdminPage> {
  final _repo = SekolahRepository();
  TahunAjaran? _ta;
  List<Kelas>? _kelas;
  String? _kelasId;
  Future<List<JadwalAdmin>>? _future;
  String? _error;

  @override
  void initState() {
    super.initState();
    _awal();
  }

  Future<void> _awal() async {
    try {
      final ta = await _repo.getTahunAjaranAktif();
      final kelas = ta == null ? <Kelas>[] : await _repo.getKelas(tahunAjaranId: ta.id);
      if (!mounted) return;
      setState(() {
        _ta = ta;
        _kelas = kelas;
        _kelasId = kelas.isEmpty ? null : kelas.first.id;
        _future = _kelasId == null ? null : _repo.getJadwal(kelasId: _kelasId!, semester: ta!.semesterAktif);
      });
    } catch (e) {
      if (mounted) setState(() => _error = AdminUi.pesanError(e));
    }
  }

  void _muatUlang() =>
      setState(() => _future = _repo.getJadwal(kelasId: _kelasId!, semester: _ta!.semesterAktif));

  Future<void> _bukaForm({JadwalAdmin? j, String? hari}) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => _JadwalForm(jadwal: j, kelasId: _kelasId!, semester: _ta!.semesterAktif, hariAwal: hari),
    ));
    if (ok == true) _muatUlang();
  }

  Future<void> _hapus(JadwalAdmin j) async {
    if (!await AdminUi.konfirmasi(context, 'Hapus jadwal?',
        '${hurufBesarAwal(j.hari)} jam ke-${j.jamKe}: ${j.mapelNama}. Riwayat absensi guru untuk jadwal ini ikut terhapus.')) {
      return;
    }
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusJadwal(j.id), sukses: 'Jadwal dihapus')) _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final kelas = _kelas;
    Widget body;
    if (_error != null) {
      body = ErrorView(message: _error!, onRetry: _awal);
    } else if (kelas == null) {
      body = const LoadingView();
    } else if (_ta == null) {
      body = const EmptyState(message: 'Belum ada tahun ajaran aktif. Aktifkan dulu di menu Tahun Ajaran.');
    } else if (kelas.isEmpty) {
      body = const EmptyState(message: 'Belum ada kelas di tahun ajaran aktif. Buat dulu di menu Kelas.');
    } else {
      body = Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DropdownButtonFormField<String>(
            initialValue: _kelasId,
            decoration: InputDecoration(
              labelText: 'Kelas',
              helperText: 'Tahun ajaran ${_ta!.nama} · semester ${_ta!.semesterAktif}',
            ),
            items: [for (final k in kelas) DropdownMenuItem(value: k.id, child: Text('Kelas ${k.namaKelas}'))],
            onChanged: (v) {
              _kelasId = v;
              _muatUlang();
            },
          ),
        ),
        Expanded(
          child: AsyncView<List<JadwalAdmin>>(
            future: _future!,
            onRetry: _muatUlang,
            builder: (context, list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final h in daftarHari) ..._blokHari(h, list.where((j) => j.hari == h).toList()),
              ],
            ),
          ),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pelajaran')),
      floatingActionButton: _kelasId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _bukaForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah jadwal'),
            ),
      body: LembarPutih(child: body),
    );
  }

  List<Widget> _blokHari(String hari, List<JadwalAdmin> items) => [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(children: [
            Expanded(
              child: Text(hurufBesarAwal(hari),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () => _bukaForm(hari: hari),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ]),
        ),
        if (items.isEmpty) const Text('Belum ada jadwal.'),
        for (final j in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Card(
              child: ListTile(
                dense: true,
                leading: CircleAvatar(radius: 16, child: Text('${j.jamKe}')),
                title: Text(j.mapelNama),
                subtitle: Text('${Fmt.jam(j.jamMulai)}–${Fmt.jam(j.jamSelesai)} · ${j.guruNama}'
                    '${j.ruang != null ? ' · ${j.ruang}' : ''}'),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _hapus(j)),
                onTap: () => _bukaForm(j: j),
              ),
            ),
          ),
      ];
}

class _JadwalForm extends StatefulWidget {
  const _JadwalForm({this.jadwal, required this.kelasId, required this.semester, this.hariAwal});

  final JadwalAdmin? jadwal;
  final String kelasId, semester;
  final String? hariAwal;

  @override
  State<_JadwalForm> createState() => _JadwalFormState();
}

class _JadwalFormState extends State<_JadwalForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final Future<(List<MataPelajaran>, List<Profile>)> _pilihan = (
    _repo.getMapel(),
    _repo.getAkun(role: UserRole.guru),
  ).wait;

  late String _hari = widget.jadwal?.hari ?? widget.hariAwal ?? 'senin';
  late String? _mapelId = widget.jadwal?.mapelId;
  late String? _guruId = widget.jadwal?.guruId;
  late String? _mulai = widget.jadwal?.jamMulai;
  late String? _selesai = widget.jadwal?.jamSelesai;
  late final _jamKe = TextEditingController(text: widget.jadwal?.jamKe.toString());
  late final _ruang = TextEditingController(text: widget.jadwal?.ruang);
  bool _menyimpan = false;

  @override
  void dispose() {
    _jamKe.dispose();
    _ruang.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (Fmt.jam(_selesai!).compareTo(Fmt.jam(_mulai!)) <= 0) {
      AdminUi.snack(context, 'Jam selesai harus setelah jam mulai', error: true);
      return;
    }
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanJadwal(
        id: widget.jadwal?.id,
        kelasId: widget.kelasId,
        mapelId: _mapelId!,
        guruId: _guruId!,
        semester: widget.semester,
        hari: _hari,
        jamKe: int.parse(_jamKe.text.trim()),
        jamMulai: Fmt.jam(_mulai!),
        jamSelesai: Fmt.jam(_selesai!),
        ruang: _ruang.text,
      ),
      sukses: 'Jadwal disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.jadwal == null ? 'Jadwal Baru' : 'Ubah Jadwal')),
        body: LembarPutih(child: FutureBuilder<(List<MataPelajaran>, List<Profile>)>(
          future: _pilihan,
          builder: (context, snap) {
            if (snap.hasError) return ErrorView(message: AdminUi.pesanError(snap.error!));
            if (!snap.hasData) return const LoadingView();
            final (mapel, semuaGuru) = snap.data!;
            final guru = semuaGuru.where((g) => g.isActive).toList();
            if (mapel.isEmpty || guru.isEmpty) {
              return const EmptyState(
                message: 'Tambahkan dulu mata pelajaran (menu Mata Pelajaran) dan akun guru (menu Akun).',
              );
            }
            return Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                DropdownButtonFormField<String>(
                  initialValue: _hari,
                  decoration: const InputDecoration(labelText: 'Hari'),
                  items: [for (final h in daftarHari) DropdownMenuItem(value: h, child: Text(hurufBesarAwal(h)))],
                  onChanged: (v) => setState(() => _hari = v ?? _hari),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jamKe,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jam ke-', hintText: '1'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n < 1 || n > 15) ? 'Isi angka 1–15' : null;
                  },
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: JamField(label: 'Mulai', nilai: _mulai, onChanged: (t) => setState(() => _mulai = t))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: JamField(label: 'Selesai', nilai: _selesai, onChanged: (t) => setState(() => _selesai = t)),
                  ),
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: mapel.any((m) => m.id == _mapelId) ? _mapelId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Mata pelajaran'),
                  items: [for (final m in mapel) DropdownMenuItem(value: m.id, child: Text(m.nama))],
                  validator: (v) => v == null ? 'Pilih mata pelajaran' : null,
                  onChanged: (v) => setState(() => _mapelId = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: guru.any((g) => g.id == _guruId) ? _guruId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Guru pengampu'),
                  items: [for (final g in guru) DropdownMenuItem(value: g.id, child: Text(g.namaLengkap))],
                  validator: (v) => v == null ? 'Pilih guru' : null,
                  onChanged: (v) => setState(() => _guruId = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ruang,
                  decoration: const InputDecoration(labelText: 'Ruang (opsional, kosong = ruang kelas)'),
                ),
                const SizedBox(height: 24),
                TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
              ]),
            );
          },
        )),
      );
}
