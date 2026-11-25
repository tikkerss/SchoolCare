import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Kelola data siswa + hubungkan siswa dengan akun orang tuanya.
class SiswaPage extends StatefulWidget {
  const SiswaPage({super.key});

  @override
  State<SiswaPage> createState() => _SiswaPageState();
}

class _SiswaPageState extends State<SiswaPage> {
  final _repo = SekolahRepository();
  final _cari = TextEditingController();
  Timer? _jedaKetik;
  String? _kelasId; // filter, null = semua
  late Future<List<Siswa>> _future = _muat();
  late final Future<List<Kelas>> _kelas = _kelasTahunAktif();

  Future<List<Kelas>> _kelasTahunAktif() async {
    final ta = await _repo.getTahunAjaranAktif();
    return _repo.getKelas(tahunAjaranId: ta?.id);
  }

  Future<List<Siswa>> _muat() => _repo.getSiswa(kelasId: _kelasId, cari: _cari.text);

  void _muatUlang() => setState(() => _future = _muat());

  @override
  void dispose() {
    _jedaKetik?.cancel();
    _cari.dispose();
    super.dispose();
  }

  Future<void> _bukaForm([Siswa? s]) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => _SiswaForm(siswa: s)));
    if (ok == true) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Siswa & Orang Tua')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _bukaForm(),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Siswa baru'),
        ),
        body: LembarPutih(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              TextField(
                controller: _cari,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama atau NIS'),
                onChanged: (_) {
                  _jedaKetik?.cancel();
                  _jedaKetik = Timer(const Duration(milliseconds: 400), _muatUlang);
                },
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Kelas>>(
                future: _kelas,
                builder: (context, snap) => DropdownButtonFormField<String?>(
                  initialValue: _kelasId,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Semua kelas')),
                    for (final k in snap.data ?? const <Kelas>[])
                      DropdownMenuItem<String?>(value: k.id, child: Text('Kelas ${k.namaKelas}')),
                  ],
                  onChanged: (v) {
                    _kelasId = v;
                    _muatUlang();
                  },
                ),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _muatUlang(),
              child: AsyncView<List<Siswa>>(
                future: _future,
                onRetry: _muatUlang,
                isEmpty: (d) => d.isEmpty,
                emptyMessage: 'Tidak ada siswa.',
                builder: (context, list) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(s.nama.isEmpty ? '?' : s.nama[0])),
                        title: Text(s.nama),
                        subtitle: Text('NIS ${s.nis} · ${s.kelasNama == null ? 'Tanpa kelas' : 'Kelas ${s.kelasNama}'}'
                            '${s.status == 'aktif' ? '' : ' · ${hurufBesarAwal(s.status)}'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.family_restroom),
                          tooltip: 'Orang tua',
                          onPressed: () => _OrtuSheet.tampilkan(context, s),
                        ),
                        onTap: () => _bukaForm(s),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ])),
      );
}

// ===================================================================== FORM SISWA
class _SiswaForm extends StatefulWidget {
  const _SiswaForm({this.siswa});

  final Siswa? siswa;

  @override
  State<_SiswaForm> createState() => _SiswaFormState();
}

class _SiswaFormState extends State<_SiswaForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _nis = TextEditingController(text: widget.siswa?.nis);
  late final _nisn = TextEditingController(text: widget.siswa?.nisn);
  late final _nama = TextEditingController(text: widget.siswa?.nama);
  late final _alamat = TextEditingController(text: widget.siswa?.alamat);
  late String _jk = widget.siswa?.jenisKelamin ?? 'L';
  late String _status = widget.siswa?.status ?? 'aktif';
  late String? _kelasId = widget.siswa?.kelasId;
  late DateTime? _lahir = widget.siswa?.tanggalLahir;
  late final Future<List<Kelas>> _kelas = _repo.getKelas();
  bool _menyimpan = false;

  @override
  void dispose() {
    for (final c in [_nis, _nisn, _nama, _alamat]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanSiswa(
        id: widget.siswa?.id,
        nis: _nis.text,
        nisn: _nisn.text,
        nama: _nama.text,
        jenisKelamin: _jk,
        tanggalLahir: _lahir,
        alamat: _alamat.text,
        kelasId: _kelasId,
        status: _status,
      ),
      sukses: 'Data siswa disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  Future<void> _hapus() async {
    final s = widget.siswa!;
    if (!await AdminUi.konfirmasi(context, 'Hapus ${s.nama}?',
        'Semua data absensi, nilai, dan rapor siswa ini juga ikut terhapus. '
        'Untuk siswa yang lulus/pindah, sebaiknya ubah statusnya saja.')) {
      return;
    }
    if (!mounted) return;
    if (await AdminUi.jalankan(context, () => _repo.hapusSiswa(s.id), sukses: 'Siswa dihapus') && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.siswa == null ? 'Siswa Baru' : 'Ubah Data Siswa'),
          actions: [
            if (widget.siswa != null)
              IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Hapus', onPressed: _hapus),
          ],
        ),
        body: LembarPutih(child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 karakter' : null,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _nis,
                  decoration: const InputDecoration(labelText: 'NIS'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(controller: _nisn, decoration: const InputDecoration(labelText: 'NISN (opsional)')),
              ),
            ]),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'L', label: Text('Laki-laki')),
                ButtonSegment(value: 'P', label: Text('Perempuan')),
              ],
              selected: {_jk},
              onSelectionChanged: (s) => setState(() => _jk = s.first),
            ),
            const SizedBox(height: 16),
            TanggalField(
              label: 'Tanggal lahir (opsional)',
              nilai: _lahir,
              wajib: false,
              onChanged: (d) => setState(() => _lahir = d),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Kelas>>(
              future: _kelas,
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final kelas = snap.data!;
                return DropdownButtonFormField<String?>(
                  initialValue: kelas.any((k) => k.id == _kelasId) ? _kelasId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('— Tanpa kelas —')),
                    for (final k in kelas)
                      DropdownMenuItem<String?>(
                        value: k.id,
                        child: Text('Kelas ${k.namaKelas} (${k.tahunAjaranNama ?? '-'})'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _kelasId = v),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in ['aktif', 'lulus', 'pindah', 'keluar'])
                  DropdownMenuItem(value: s, child: Text(hurufBesarAwal(s))),
              ],
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alamat,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
            ),
            const SizedBox(height: 24),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
          ]),
        )),
      );
}

// ===================================================================== ORANG TUA SISWA
/// Bottom sheet: daftar orang tua yang terhubung + tombol hubungkan/lepas.
class _OrtuSheet extends StatefulWidget {
  const _OrtuSheet({required this.siswa});

  final Siswa siswa;

  static Future<void> tampilkan(BuildContext context, Siswa s) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _OrtuSheet(siswa: s),
      );

  @override
  State<_OrtuSheet> createState() => _OrtuSheetState();
}

class _OrtuSheetState extends State<_OrtuSheet> {
  final _repo = SekolahRepository();
  late Future<List<OrtuTerhubung>> _future = _repo.getOrtuSiswa(widget.siswa.id);

  void _muatUlang() => setState(() => _future = _repo.getOrtuSiswa(widget.siswa.id));

  Future<void> _tambah() async {
    final hasil = await showDialog<(Profile, String)>(context: context, builder: (_) => const _PilihOrtuDialog());
    if (hasil == null || !mounted) return;
    final (ortu, hubungan) = hasil;
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.hubungkanOrtu(siswaId: widget.siswa.id, ortuId: ortu.id, hubungan: hubungan),
      sukses: '${ortu.namaLengkap} terhubung ke ${widget.siswa.nama}',
    );
    if (ok) _muatUlang();
  }

  Future<void> _lepas(OrtuTerhubung o) async {
    if (!await AdminUi.konfirmasi(context, 'Lepas ${o.nama}?',
        '${o.nama} tidak akan bisa melihat data ${widget.siswa.nama} lagi.',
        ya: 'Lepas')) {
      return;
    }
    if (!mounted) return;
    final ok = await AdminUi.jalankan(context, () => _repo.lepasOrtu(siswaId: widget.siswa.id, ortuId: o.ortuId));
    if (ok) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Orang tua ${widget.siswa.nama}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Orang tua yang terhubung bisa memantau anak ini di aplikasi.',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          FutureBuilder<List<OrtuTerhubung>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
              if (snap.hasError) return Text(AdminUi.pesanError(snap.error!));
              final list = snap.data!;
              if (list.isEmpty) return const Text('Belum ada orang tua yang terhubung.');
              return Column(children: [
                for (final o in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: Text(o.nama),
                    subtitle: Text('${hurufBesarAwal(o.hubungan)} · ${o.email}'),
                    trailing: IconButton(icon: const Icon(Icons.link_off), tooltip: 'Lepas', onPressed: () => _lepas(o)),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('Hubungkan akun orang tua'),
              onPressed: _tambah,
            ),
          ),
        ]),
      );
}

/// Dialog memilih akun orang tua + hubungan (ayah/ibu/wali).
class _PilihOrtuDialog extends StatefulWidget {
  const _PilihOrtuDialog();

  @override
  State<_PilihOrtuDialog> createState() => _PilihOrtuDialogState();
}

class _PilihOrtuDialogState extends State<_PilihOrtuDialog> {
  late final Future<List<Profile>> _ortu = SekolahRepository().getAkun(role: UserRole.orangTua);
  Profile? _dipilih;
  String _hubungan = 'ibu';

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Hubungkan orang tua'),
        content: FutureBuilder<List<Profile>>(
          future: _ortu,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox(height: 80, child: LoadingView());
            final ortu = snap.data!.where((p) => p.isActive).toList();
            if (ortu.isEmpty) {
              return const Text('Belum ada akun orang tua. Buat dulu di menu Akun.');
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<Profile>(
                initialValue: _dipilih,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Akun orang tua'),
                items: [
                  for (final p in ortu)
                    DropdownMenuItem(value: p, child: Text('${p.namaLengkap} (${p.email})', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (p) => setState(() => _dipilih = p),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _hubungan,
                decoration: const InputDecoration(labelText: 'Hubungan'),
                items: const [
                  DropdownMenuItem(value: 'ayah', child: Text('Ayah')),
                  DropdownMenuItem(value: 'ibu', child: Text('Ibu')),
                  DropdownMenuItem(value: 'wali', child: Text('Wali')),
                ],
                onChanged: (v) => setState(() => _hubungan = v ?? _hubungan),
              ),
            ]);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: _dipilih == null ? null : () => Navigator.pop(context, (_dipilih!, _hubungan)),
            child: const Text('Hubungkan'),
          ),
        ],
      );
}
