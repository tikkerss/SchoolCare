import 'package:flutter/foundation.dart';
import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/models/siswa_kelas.dart';

/// Daftar siswa per kelas + catatan guru per siswa.
///
/// Status kehadiran HANYA DIBACA dari `absensi_siswa` (diisi wali kelas saat absensi pagi).
/// Guru tidak mengubah status; kalau ada kejadian, guru menulis catatan di `catatan_siswa`
/// yang bisa dibaca wali kelas dan orang tua.
class SiswaRepository {
  String get _uid => supabase.auth.currentUser!.id;

  Future<DaftarSiswa> getSiswaHariIni(String kelasId) async {
    final hariIni = Fmt.db(DateTime.now());

    final siswa = await supabase
        .from('siswa')
        .select('id, nis, nama_lengkap')
        .eq('kelas_id', kelasId)
        .eq('status', 'aktif')
        .order('nama_lengkap');
    if (siswa.isEmpty) return const DaftarSiswa([], catatanAktif: true);

    final absen = await supabase
        .from('absensi_siswa')
        .select('siswa_id, status, keterangan')
        .eq('kelas_id', kelasId)
        .eq('tanggal', hariIni);
    final perSiswa = {for (final a in absen) a['siswa_id'] as String: a};

    // Catatan: kalau tabelnya belum dibuat Backend, daftar siswa tetap tampil.
    var catatanAktif = true;
    final catatan = <String, List<CatatanSiswa>>{};
    try {
      final rows = await supabase
          .from('catatan_siswa')
          .select(
            'id, siswa_id, isi, dibuat_oleh, created_at, '
            'guru:profiles!dibuat_oleh(nama_lengkap), jadwal:jadwal_pelajaran(mata_pelajaran(nama))',
          )
          .eq('tanggal', hariIni)
          .inFilter('siswa_id', [for (final s in siswa) s['id'] as String])
          .order('created_at');
      for (final r in rows) {
        final c = CatatanSiswa.fromJson(r);
        catatan.putIfAbsent(c.siswaId, () => []).add(c);
      }
    } catch (e) {
      debugPrint('SiswaRepository catatan_siswa: $e');
      catatanAktif = false;
    }

    return DaftarSiswa(
      [
        for (final s in siswa)
          SiswaKelas(
            id: s['id'] as String,
            nama: s['nama_lengkap'] as String,
            nis: s['nis'] as String,
            status: perSiswa[s['id']]?['status'] as String?,
            keterangan: perSiswa[s['id']]?['keterangan'] as String?,
            catatan: catatan[s['id']] ?? const [],
          ),
      ],
      catatanAktif: catatanAktif,
    );
  }

  Future<void> tambahCatatan({required String siswaId, required String jadwalId, required String isi}) async {
    await supabase.from('catatan_siswa').insert({
      'siswa_id': siswaId,
      'jadwal_id': jadwalId,
      'tanggal': Fmt.db(DateTime.now()),
      'isi': isi,
      'dibuat_oleh': _uid,
    });
  }

  /// Hanya catatan buatan sendiri yang bisa dihapus (dijaga juga oleh RLS).
  Future<void> hapusCatatan(String catatanId) async {
    final hasil = await supabase
        .from('catatan_siswa')
        .delete()
        .eq('id', catatanId)
        .eq('dibuat_oleh', _uid)
        .select('id');
    if (hasil.isEmpty) throw Exception('Catatan tidak bisa dihapus.');
  }

  bool milikSaya(CatatanSiswa c) => c.dibuatOlehId == _uid;
}
