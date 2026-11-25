import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';
import '../models/jadwal.dart';
import 'absensi_hadir_page.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

/// TODO(Backend): isi dengan daftar guru dari Supabase. Selama kosong, dropdown nonaktif
/// dan guru pengganti belum wajib dipilih.
const _daftarGuruPengganti = <String>[];

class AbsensiMengajarPage extends StatefulWidget {
  final Jadwal jadwal;
  const AbsensiMengajarPage({super.key, required this.jadwal});

  @override
  State<AbsensiMengajarPage> createState() => _AbsensiMengajarPageState();
}

enum _Pilihan { hadir, tidakHadir }

enum _Tindak { pengganti, dibatalkan }

class _AbsensiMengajarPageState extends State<AbsensiMengajarPage> {
  _Pilihan _pilihan = _Pilihan.hadir;

  // ---- form tidak hadir
  final _keterangan = TextEditingController();
  File? _surat;
  _Tindak _tindak = _Tindak.pengganti;
  String? _pengganti;

  @override
  void dispose() {
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _bukaHadir() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AbsensiHadirPage(jadwal: widget.jadwal)),
    );
    if (berhasil == true && mounted) {
      Navigator.pop(context, StatusKelas.berlangsung);
    }
  }

  Future<void> _pilihSurat() async {
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (hasil.isEmpty) return; // batal memilih
    final path = hasil.single.path;
    if (path == null) return;
    setState(() => _surat = File(path));
  }

  bool get _bisaKirimTidakHadir =>
      _keterangan.text.trim().isNotEmpty &&
      (_tindak == _Tindak.dibatalkan || _pengganti != null || _daftarGuruPengganti.isEmpty);

  void _kirimTidakHadir() {
    // Nanti: upload surat + simpan absensi tidak hadir ke Supabase.
    Navigator.pop(context, _tindak == _Tindak.pengganti ? StatusKelas.digantikan : StatusKelas.dibatalkan);
  }

  static const _label = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);

  @override
  Widget build(BuildContext context) {
    final j = widget.jadwal;

    return Scaffold(
      appBar: AppBar(title: const Text('Absen Mengajar')),
      body: LembarPutih(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TicketCard(
            jamMulai: j.jamMulai,
            jamSelesai: j.jamSelesai,
            sorot: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(j.mapel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${j.kelas} • ${j.ruang}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            ]),
          ),
          const SizedBox(height: 20),
          SegmentedButton<_Pilihan>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Pilihan.hadir, label: Text('Hadir'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(value: _Pilihan.tidakHadir, label: Text('Tidak Hadir'), icon: Icon(Icons.cancel_outlined)),
            ],
            selected: {_pilihan},
            onSelectionChanged: (s) => setState(() => _pilihan = s.first),
          ),
          const SizedBox(height: 20),
          if (_pilihan == _Pilihan.hadir) ..._formHadir() else ..._formTidakHadir(),
        ],
      )),
    );
  }

  List<Widget> _formHadir() => [
        SoftCard(
          warna: AppColors.softYellow,
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Yang perlu disiapkan', style: _label),
            SizedBox(height: 8),
            _Langkah(ikon: Icons.photo_camera_outlined, teks: 'Foto bukti kegiatan kelas'),
            _Langkah(ikon: Icons.location_on_outlined, teks: 'Lokasi (geotag) tercatat otomatis'),
            _Langkah(ikon: Icons.edit_note, teks: 'Berita acara: ringkasan materi'),
          ]),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Lanjut ambil foto bukti'),
          onPressed: _bukaHadir,
        ),
      ];

  List<Widget> _formTidakHadir() => [
        const Text('Keterangan', style: _label),
        const SizedBox(height: 6),
        TextField(
          controller: _keterangan,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Alasan tidak hadir, mis. sakit atau dinas luar'),
        ),
        const SizedBox(height: 16),
        const Text('Surat keterangan (opsional)', style: _label),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(
            _surat == null ? 'Unggah surat' : _surat!.path.split(Platform.pathSeparator).last,
            overflow: TextOverflow.ellipsis,
          ),
          onPressed: _pilihSurat,
        ),
        const SizedBox(height: 16),
        const Text('Kelas ini', style: _label),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: _OpsiKotak(
              label: 'Ada pengganti',
              aktif: _tindak == _Tindak.pengganti,
              onTap: () => setState(() => _tindak = _Tindak.pengganti),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OpsiKotak(
              label: 'Dibatalkan',
              aktif: _tindak == _Tindak.dibatalkan,
              onTap: () => setState(() => _tindak = _Tindak.dibatalkan),
            ),
          ),
        ]),
        if (_tindak == _Tindak.pengganti) ...[
          const SizedBox(height: 16),
          const Text('Guru pengganti', style: _label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _pengganti,
            isExpanded: true,
            hint: Text(_daftarGuruPengganti.isEmpty ? 'Daftar guru belum tersedia' : 'Pilih guru pengganti'),
            items: [
              for (final g in _daftarGuruPengganti) DropdownMenuItem(value: g, child: Text(g)),
            ],
            onChanged: (v) => setState(() => _pengganti = v),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _bisaKirimTidakHadir ? _kirimTidakHadir : null,
          child: const Text('Kirim Absensi'),
        ),
      ];
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.ikon, required this.teks});
  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(ikon, size: 18, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 12))),
        ]),
      );
}

class _OpsiKotak extends StatelessWidget {
  const _OpsiKotak({required this.label, required this.aktif, required this.onTap});
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: aktif ? AppColors.pink : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: aktif ? null : Border.all(color: AppColors.softPink, width: 1.5),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                color: aktif ? AppColors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      );
}
