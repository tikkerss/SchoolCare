import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/guru_repository.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:schoolcare/features/guru/widgets/bukti_foto_picker.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

/// Alur Tidak Hadir (Gambar 3.3): foto bukti → keterangan → surat (opsional)
/// → ada guru pengganti? Ya = digantikan, Tidak = dibatalkan.
class AbsensiTidakHadirPage extends StatefulWidget {
  const AbsensiTidakHadirPage({super.key, required this.jadwal});

  final Jadwal jadwal;

  @override
  State<AbsensiTidakHadirPage> createState() => _AbsensiTidakHadirPageState();
}

class _AbsensiTidakHadirPageState extends State<AbsensiTidakHadirPage> {
  final _repo = GuruRepository();
  late Future<List<GuruSingkat>> _daftarGuru = _repo.getGuruPengganti(widget.jadwal);

  // Kalau sedang mengubah absensi Tidak Hadir, isi dengan data lama.
  late final bool _lama = widget.jadwal.sudahDiabsen && !widget.jadwal.hadir;
  late final _keterangan = TextEditingController(text: _lama ? widget.jadwal.keterangan : null);
  late bool _adaPengganti = _lama && widget.jadwal.guruPenggantiId != null;
  late String? _penggantiId = _lama ? widget.jadwal.guruPenggantiId : null;
  late bool _adaSuratLama = _lama && widget.jadwal.suratPath != null;

  BuktiFoto? _bukti;
  PlatformFile? _surat;
  bool _menyimpan = false;

  bool get _ubah => widget.jadwal.sudahDiabsen;

  @override
  void dispose() {
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _pilihSurat() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (files.isNotEmpty) setState(() => _surat = files.first);
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      final path = _surat?.path;
      final status = await _repo.absenTidakHadir(
        jadwal: widget.jadwal,
        bukti: _bukti,
        keterangan: _keterangan.text.trim(),
        surat: path == null ? null : File(path),
        namaSurat: _surat?.name,
        hapusSurat: _surat == null && !_adaSuratLama,
        guruPenggantiId: _adaPengganti ? _penggantiId : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_ubah ? 'Perubahan absensi tersimpan' : 'Absensi tersimpan'}. '
            'Status kelas: ${StatusBadge.labelOf(status)}.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('AbsensiTidakHadirPage: $e');
      if (mounted) {
        final pesan = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $pesan')));
      }
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Saat mengubah, foto lama tetap dipakai kalau tidak diambil ulang.
    final bisaSimpan =
        (_bukti != null || _ubah) &&
        _keterangan.text.trim().isNotEmpty &&
        (!_adaPengganti || _penggantiId != null) &&
        !_menyimpan;

    return Scaffold(
      appBar: AppBar(title: Text('${_ubah ? 'Ubah: ' : ''}Tidak Hadir • Kelas ${widget.jadwal.namaKelas}')),
      body: LembarPutih(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _Langkah(_ubah ? '1. Foto bukti (ambil ulang bila perlu)' : '1. Foto bukti (wajib)'),
            BuktiFotoPicker(bukti: _bukti, onBerubah: (b) => setState(() => _bukti = b)),
            const SizedBox(height: 24),
            const _Langkah('2. Keterangan tidak hadir'),
            TextField(
              controller: _keterangan,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Contoh: sakit, dinas luar, keperluan keluarga'),
            ),
            const SizedBox(height: 24),
            const _Langkah('3. Surat izin / surat dokter (opsional)'),
            if (_surat == null && _adaSuratLama) ...[
              ListTile(
                contentPadding: const EdgeInsets.only(left: 12),
                tileColor: AppColors.softYellow,
                textColor: AppColors.black,
                iconColor: AppColors.black,
                titleTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                subtitleTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.description_outlined),
                title: Text(widget.jadwal.suratPath!.split('/').last, overflow: TextOverflow.ellipsis),
                subtitle: const Text('Surat yang sudah diunggah'),
                trailing: IconButton(
                  tooltip: 'Hapus surat',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _adaSuratLama = false),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(
                _surat?.name ?? (_adaSuratLama ? 'Ganti Surat' : 'Unggah Surat'),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: _pilihSurat,
            ),
            if (_surat != null)
              TextButton(onPressed: () => setState(() => _surat = null), child: const Text('Batal unggah surat ini')),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '4. Ada guru pengganti?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              subtitle: const Text('Ya = kelas digantikan, Tidak = kelas dibatalkan'),
              value: _adaPengganti,
              onChanged: (v) => setState(() => _adaPengganti = v),
            ),
            if (_adaPengganti)
              FutureBuilder<List<GuruSingkat>>(
                future: _daftarGuru,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return TextButton(
                      onPressed: () => setState(() {
                        _daftarGuru = _repo.getGuruPengganti(widget.jadwal);
                      }),
                      child: const Text('Gagal memuat daftar guru. Coba lagi'),
                    );
                  }
                  if (!snap.hasData) return const LinearProgressIndicator();
                  final daftar = snap.data!;
                  return DropdownButtonFormField<String>(
                    // pengganti lama mungkin sudah tidak aktif → jangan dipilih otomatis
                    initialValue: daftar.any((g) => g.id == _penggantiId) ? _penggantiId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pilih guru pengganti'),
                    items: [
                      for (final g in daftar)
                        DropdownMenuItem(
                          value: g.id,
                          child: Text(
                            g.sibuk ? '${g.nama} (sedang mengajar)' : g.nama,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _penggantiId = v),
                  );
                },
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Expanded(child: Text(
                    'Status kelas akan menjadi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                  )),
                  StatusBadge(_adaPengganti ? 'digantikan' : 'dibatalkan'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: bisaSimpan ? _simpan : null,
              child: _menyimpan
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_ubah ? 'Simpan Perubahan' : 'Simpan Absensi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Judul langkah form (Bold 15).
class _Langkah extends StatelessWidget {
  const _Langkah(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      teks,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
  );
}
