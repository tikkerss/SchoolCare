import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_repository.dart';
import 'package:schoolcare/features/sekolah/widgets/admin_ui.dart';
import 'package:schoolcare/shared/widgets/state_views.dart';

/// Kelola tahun ajaran. Hanya satu yang boleh aktif; semester aktif menentukan jadwal yang tampil.
class TahunAjaranPage extends StatefulWidget {
  const TahunAjaranPage({super.key});

  @override
  State<TahunAjaranPage> createState() => _TahunAjaranPageState();
}

class _TahunAjaranPageState extends State<TahunAjaranPage> {
  final _repo = SekolahRepository();
  late Future<List<TahunAjaran>> _future = _repo.getTahunAjaran();

  void _muatUlang() => setState(() => _future = _repo.getTahunAjaran());

  Future<void> _bukaForm([TahunAjaran? ta]) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => _TahunAjaranForm(ta: ta)));
    if (ok == true) _muatUlang();
  }

  Future<void> _aktifkan(TahunAjaran ta) async {
    final ok = await AdminUi.jalankan(context, () => _repo.aktifkanTahunAjaran(ta.id),
        sukses: 'Tahun ajaran ${ta.nama} sekarang aktif');
    if (ok) _muatUlang();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Tahun Ajaran')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _bukaForm(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        body: AsyncView<List<TahunAjaran>>(
          future: _future,
          onRetry: _muatUlang,
          isEmpty: (d) => d.isEmpty,
          emptyMessage: 'Belum ada tahun ajaran.\nTekan Tambah untuk membuat, misalnya 2026/2027.',
          builder: (context, list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final ta = list[i];
              return Card(
                child: ListTile(
                  title: Text(ta.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${Fmt.tanggal(ta.tanggalMulai)} – ${Fmt.tanggal(ta.tanggalSelesai)}\n'
                      'Semester aktif: ${hurufBesarAwal(ta.semesterAktif)}'),
                  isThreeLine: true,
                  trailing: ta.isActive
                      ? const Chip(
                          label: Text('Aktif', style: TextStyle(color: AppColors.success)),
                          side: BorderSide(color: AppColors.success),
                        )
                      : TextButton(onPressed: () => _aktifkan(ta), child: const Text('Aktifkan')),
                  onTap: () => _bukaForm(ta),
                ),
              );
            },
          ),
        ),
      );
}

class _TahunAjaranForm extends StatefulWidget {
  const _TahunAjaranForm({this.ta});

  final TahunAjaran? ta;

  @override
  State<_TahunAjaranForm> createState() => _TahunAjaranFormState();
}

class _TahunAjaranFormState extends State<_TahunAjaranForm> {
  final _repo = SekolahRepository();
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.ta?.nama);
  late String _semester = widget.ta?.semesterAktif ?? 'ganjil';
  late DateTime? _mulai = widget.ta?.tanggalMulai;
  late DateTime? _selesai = widget.ta?.tanggalSelesai;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_selesai!.isAfter(_mulai!)) {
      AdminUi.snack(context, 'Tanggal selesai harus setelah tanggal mulai', error: true);
      return;
    }
    setState(() => _menyimpan = true);
    final ok = await AdminUi.jalankan(
      context,
      () => _repo.simpanTahunAjaran(
        id: widget.ta?.id,
        nama: _nama.text.trim(),
        semesterAktif: _semester,
        mulai: _mulai!,
        selesai: _selesai!,
      ),
      sukses: 'Tahun ajaran disimpan',
    );
    if (!mounted) return;
    setState(() => _menyimpan = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.ta == null ? 'Tahun Ajaran Baru' : 'Ubah Tahun Ajaran')),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama', hintText: '2026/2027'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _semester,
              decoration: const InputDecoration(labelText: 'Semester aktif'),
              items: const [
                DropdownMenuItem(value: 'ganjil', child: Text('Ganjil')),
                DropdownMenuItem(value: 'genap', child: Text('Genap')),
              ],
              onChanged: (v) => setState(() => _semester = v ?? _semester),
            ),
            const SizedBox(height: 16),
            TanggalField(label: 'Tanggal mulai', nilai: _mulai, onChanged: (d) => setState(() => _mulai = d)),
            const SizedBox(height: 16),
            TanggalField(label: 'Tanggal selesai', nilai: _selesai, onChanged: (d) => setState(() => _selesai = d)),
            const SizedBox(height: 24),
            TombolSimpan(menyimpan: _menyimpan, onPressed: _simpan),
            if (widget.ta == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Setelah disimpan, tekan "Aktifkan" di daftar supaya tahun ajaran ini dipakai.'),
              ),
          ]),
        ),
      );
}
