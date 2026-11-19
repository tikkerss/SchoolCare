import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

/// Form pengajuan izin / sakit oleh orang tua.
/// Setelah dikirim, status kehadiran anak langsung berubah pada tanggal yang dipilih
/// (hari Minggu dilewati). Tab Kehadiran & Beranda ikut ter-update otomatis.
class FormIzinPage extends StatefulWidget {
  const FormIzinPage({super.key, required this.anak});

  final Anak anak;

  @override
  State<FormIzinPage> createState() => _FormIzinPageState();
}

class _FormIzinPageState extends State<FormIzinPage> {
  static const _maksUkuran = 5 * 1024 * 1024; // 5 MB

  final _formKey = GlobalKey<FormState>();
  final _alasan = TextEditingController();
  String _jenis = 'sakit';
  DateTimeRange? _rentang;
  File? _lampiran;
  bool _mengirim = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  void _snack(String pesan) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));

  Future<void> _pilihTanggal() async {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    final r = await showDateRangePicker(
      context: context,
      firstDate: hariIni.subtract(const Duration(days: 7)),
      lastDate: hariIni.add(const Duration(days: 30)),
      initialDateRange: _rentang ?? DateTimeRange(start: hariIni, end: hariIni),
      helpText: 'Pilih tanggal tidak masuk',
    );
    if (r != null) setState(() => _rentang = r);
  }

  Future<void> _pilihFile() async {
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (hasil.isEmpty) return; // user batal memilih
    final path = hasil.single.path;
    if (path == null) return;
    final file = File(path);
    if (await file.length() > _maksUkuran) {
      _snack('Ukuran file maksimal 5 MB.');
      return;
    }
    setState(() => _lampiran = file);
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    final rentang = _rentang;
    if (rentang == null) {
      _snack('Pilih tanggal terlebih dahulu.');
      return;
    }
    setState(() => _mengirim = true);
    try {
      await OrtuRepository().ajukanIzin(
        siswaId: widget.anak.siswaId,
        jenis: _jenis,
        mulai: rentang.start,
        selesai: rentang.end,
        alasan: _alasan.text.trim(),
        namaLampiran: _lampiran?.uri.pathSegments.last,
      );
      if (!mounted) return;
      _snack('Pengajuan terkirim. Kehadiran ${widget.anak.nama} sudah diperbarui.');
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('FormIzinPage._kirim: $e');
      _snack('Gagal mengirim pengajuan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anak = widget.anak;
    final r = _rentang;

    return Scaffold(
      appBar: AppBar(title: const Text('Izin / Sakit')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(anak.nama[0])),
                title: Text(anak.nama),
                subtitle: Text('Kelas ${anak.namaKelas}'),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'sakit', label: Text('Sakit'), icon: Icon(Icons.healing)),
                ButtonSegment(value: 'izin', label: Text('Izin'), icon: Icon(Icons.event_busy)),
              ],
              selected: {_jenis},
              onSelectionChanged: (s) => setState(() => _jenis = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: OrtuWarna.border),
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: OrtuWarna.surface,
              leading: const Icon(Icons.date_range),
              title: Text(
                r == null
                    ? 'Pilih tanggal'
                    : r.start == r.end
                    ? OrtuFmt.hari(r.start)
                    : '${OrtuFmt.tanggal(r.start)} – ${OrtuFmt.tanggal(r.end)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pilihTanggal,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _alasan,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan',
                hintText: _jenis == 'sakit' ? 'Contoh: demam sejak semalam' : 'Contoh: acara keluarga',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 5) ? 'Tulis alasan minimal 5 karakter' : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: Icon(_lampiran == null ? Icons.attach_file : Icons.check_circle),
              label: Text(
                _lampiran == null
                    ? (_jenis == 'sakit' ? 'Lampirkan surat dokter (opsional)' : 'Lampirkan surat (opsional)')
                    : _lampiran!.uri.pathSegments.last,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: _mengirim ? null : _pilihFile,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _mengirim ? null : _kirim,
              child: _mengirim
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim pengajuan'),
            ),
            const SizedBox(height: 12),
            Text(
              'Status kehadiran anak akan langsung berubah menjadi Izin/Sakit pada tanggal '
              'yang dipilih (hari Minggu dilewati). Wali kelas dapat melihat pengajuan ini.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
