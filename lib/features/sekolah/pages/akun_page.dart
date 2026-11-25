import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// Kelola akun guru, orang tua, dan pihak sekolah:
/// buat akun baru (lewat Edge Function), ubah data, aktifkan/nonaktifkan.
class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  final _repo = SekolahRepository();
  UserRole? _filter; // null = semua
  late Future<List<Profile>> _future = _repo.getAkun(role: _filter);

  void _muatUlang() => setState(() => _future = _repo.getAkun(role: _filter));

  Future<void> _bukaForm([Profile? akun]) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => _AkunFormPage(akun: akun)));
    if (ok == true) _muatUlang();
  }

  Future<void> _ubahAktif(Profile p) async {
    final nonaktifkan = p.isActive;
    if (nonaktifkan &&
        !await AdminUi.konfirmasi(context, 'Nonaktifkan akun?',
            '${p.namaLengkap} tidak akan bisa masuk ke aplikasi sampai diaktifkan lagi.',
            ya: 'Nonaktifkan')) {
      return;
    }
    if (!mounted) return;
    final ok = await AdminUi.jalankan(context, () => _repo.setAkunAktif(p.id, !p.isActive),
        sukses: nonaktifkan ? 'Akun dinonaktifkan' : 'Akun diaktifkan');
    if (ok) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kelola Akun')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _bukaForm(),
          icon: const Icon(Icons.person_add),
          label: const Text('Akun baru'),
        ),
        body: LembarPutih(child: Column(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              for (final r in <UserRole?>[null, ...UserRole.values])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r == null ? 'Semua' : r.label),
                    selected: _filter == r,
                    onSelected: (_) {
                      _filter = r;
                      _muatUlang();
                    },
                  ),
                ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _muatUlang(),
              child: AsyncView<List<Profile>>(
                future: _future,
                onRetry: _muatUlang,
                isEmpty: (d) => d.isEmpty,
                emptyMessage: 'Belum ada akun.',
                builder: (context, list) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(p.namaLengkap.isEmpty ? '?' : p.namaLengkap[0])),
                        title: Text(p.namaLengkap,
                            style: TextStyle(color: p.isActive ? null : AppColors.textSecondary)),
                        subtitle: Text('${p.role.label} · ${p.email}${p.isActive ? '' : ' · NONAKTIF'}'),
                        trailing: Switch(value: p.isActive, onChanged: (_) => _ubahAktif(p)),
                        onTap: () => _bukaForm(p),
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

class _AkunFormPage extends StatefulWidget {
  const _AkunFormPage({this.akun});

  final Profile? akun; // null = akun baru

  @override
  State<_AkunFormPage> createState() => _AkunFormPageState();
}

class _AkunFormPageState extends State<_AkunFormPage> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.akun?.namaLengkap);
  late final _email = TextEditingController(text: widget.akun?.email);
  final _password = TextEditingController();
  late final _wa = TextEditingController(text: widget.akun?.noWhatsapp);
  late final _nip = TextEditingController(text: widget.akun?.nip);
  late UserRole _role = widget.akun?.role ?? UserRole.orangTua;
  bool _menyimpan = false;

  bool get _baru => widget.akun == null;

  @override
  void dispose() {
    for (final c in [_nama, _email, _password, _wa, _nip]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _baru
          ? _repo.buatAkun(
              email: _email.text,
              password: _password.text,
              nama: _nama.text,
              role: _role,
              noWhatsapp: _wa.text,
              nip: _nip.text,
            )
          : _repo.ubahAkun(widget.akun!.id, nama: _nama.text, role: _role, noWhatsapp: _wa.text, nip: _nip.text),
      sukses: _baru ? 'Akun berhasil dibuat' : 'Perubahan disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_baru ? 'Akun Baru' : 'Ubah Akun')),
        body: LembarPutih(child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Peran'),
              items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label))],
              onChanged: (r) => setState(() => _role = r ?? _role),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 karakter' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              enabled: _baru, // email tidak bisa diganti dari aplikasi
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (untuk login)'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
            ),
            if (_baru) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Password awal',
                  helperText: 'Berikan ke pemilik akun. Minimal 6 karakter.',
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _wa,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp (opsional)',
                hintText: '6281234567890',
                helperText: 'Format 62…, tanpa + dan tanpa 0 di depan',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                return RegExp(r'^62[0-9]{8,13}$').hasMatch(t) ? null : 'Format: 62 diikuti 8–13 angka';
              },
            ),
            if (_role != UserRole.orangTua) ...[
              const SizedBox(height: 16),
              TextFormField(controller: _nip, decoration: const InputDecoration(labelText: 'NIP (opsional)')),
            ],
            const SizedBox(height: 24),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan, label: _baru ? 'Buat akun' : 'Simpan'),
          ]),
        )),
      );
}
