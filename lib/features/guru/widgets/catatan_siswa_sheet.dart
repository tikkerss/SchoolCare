import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/guru/data/siswa_repository.dart';
import 'package:schoolcare/features/guru/models/siswa_kelas.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';

/// Lembar bawah berisi catatan hari ini untuk satu siswa + kolom menambah catatan.
/// Selesai ditutup, muat ulang daftar siswa supaya catatan terbaru tampil.
Future<void> tampilkanCatatanSiswa(BuildContext context, {required SiswaKelas siswa, required String jadwalId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CatatanSheet(siswa: siswa, jadwalId: jadwalId),
    );

class _CatatanSheet extends StatefulWidget {
  const _CatatanSheet({required this.siswa, required this.jadwalId});

  final SiswaKelas siswa;
  final String jadwalId;

  @override
  State<_CatatanSheet> createState() => _CatatanSheetState();
}

class _CatatanSheetState extends State<_CatatanSheet> {
  final _repo = SiswaRepository();
  final _isi = TextEditingController();
  late final _catatan = List.of(widget.siswa.catatan);
  bool _menyimpan = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    setState(() => _menyimpan = true);
    try {
      await _repo.tambahCatatan(siswaId: widget.siswa.id, jadwalId: widget.jadwalId, isi: _isi.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('CatatanSheet: $e');
      _pesan('Gagal menyimpan catatan.');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Future<void> _hapus(CatatanSiswa c) async {
    try {
      await _repo.hapusCatatan(c.id);
      setState(() => _catatan.remove(c));
    } catch (e) {
      debugPrint('CatatanSheet: $e');
      _pesan('Gagal menghapus catatan.');
    }
  }

  void _pesan(String teks) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.siswa;
    final kecil = Theme.of(context).textTheme.bodySmall;

    return Permukaan.putih(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nama,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      Text('NIS ${s.nis}', style: kecil),
                    ],
                  ),
                ),
                s.status == null
                    ? Text('Belum diabsen', style: kecil?.copyWith(color: AppColors.textSecondary))
                    : StatusBadge(s.status!),
              ],
            ),
            if (s.keterangan != null) ...[
              const SizedBox(height: 4),
              Text('Keterangan wali kelas: ${s.keterangan}', style: kecil),
            ],
            const Divider(height: 24),
            const Text(
              'Catatan hari ini',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text('Dapat dibaca wali kelas dan orang tua siswa ini.', style: kecil?.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            if (_catatan.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada catatan.', style: kecil),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final c in _catatan)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: AppColors.softYellow, borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 14, right: 4),
                        title: Text(c.isi, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black)),
                        subtitle: Text(
                          [
                            c.dibuatOleh,
                            if (c.mapel != null) c.mapel!,
                            DateFormat('HH:mm').format(c.waktu),
                          ].join(' · '),
                        ),
                        trailing: _repo.milikSaya(c)
                            ? IconButton(
                                tooltip: 'Hapus catatan',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _hapus(c),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _isi,
              minLines: 1,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Contoh: pusing saat pelajaran, istirahat di UKS'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: _menyimpan
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Simpan Catatan'),
                onPressed: _isi.text.trim().isEmpty || _menyimpan ? null : _kirim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
