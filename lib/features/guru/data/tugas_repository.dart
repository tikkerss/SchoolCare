import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/features/guru/models/tugas.dart';

/// Tugas & penilaian (mirip Google Classroom), langsung dari Supabase.
///
/// Tabel: `tugas` (dibaca juga oleh tampilan Orang Tua) dan `nilai` (jenis = 'tugas',
/// dibaca Orang Tua dan dipakai Wali Kelas sebagai acuan rapor).
class TugasRepository {
  String get _uid => supabase.auth.currentUser!.id;

  Future<({String id, String semester})> _tahunAjaranAktif() async {
    final row = await supabase
        .from('tahun_ajaran')
        .select('id, semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) throw Exception('Belum ada tahun ajaran aktif.');
    return (id: row['id'] as String, semester: row['semester_aktif'] as String);
  }

  // ------------------------------------------------------------------ pilihan kelas & mapel

  /// Kelas + mapel yang diajar guru ini pada semester aktif (diambil dari jadwal).
  Future<List<KelasMapel>> getKelasMapel() async {
    final ta = await _tahunAjaranAktif();
    final rows = await supabase
        .from('jadwal_pelajaran')
        .select('kelas_id, mapel_id, kelas!inner(nama_kelas, tingkat, tahun_ajaran_id), mata_pelajaran(nama)')
        .eq('guru_id', _uid)
        .eq('semester', ta.semester)
        .eq('kelas.tahun_ajaran_id', ta.id);

    final unik = <String, KelasMapel>{};
    for (final r in rows) {
      final km = KelasMapel(
        kelasId: r['kelas_id'] as String,
        namaKelas: r['kelas']['nama_kelas'] as String,
        mapelId: r['mapel_id'] as String,
        mapel: (r['mata_pelajaran']?['nama'] as String?) ?? '-',
      );
      unik[km.kunci] = km;
    }
    final hasil = unik.values.toList()
      ..sort((a, b) {
        final k = a.namaKelas.compareTo(b.namaKelas);
        return k != 0 ? k : a.mapel.compareTo(b.mapel);
      });
    return hasil;
  }

  // ------------------------------------------------------------------ tugas

  /// Tugas buatan guru ini pada tahun ajaran aktif, tenggat terbaru di atas.
  Future<List<TugasGuru>> getTugasSaya() async {
    final ta = await _tahunAjaranAktif();
    final rows = await supabase
        .from('tugas')
        .select(
          'id, judul, deskripsi, tenggat, kelas_id, mapel_id, '
          'kelas!inner(nama_kelas, tahun_ajaran_id), mata_pelajaran(nama)',
        )
        .eq('guru_id', _uid)
        .eq('kelas.tahun_ajaran_id', ta.id)
        .order('tenggat', ascending: false);
    if (rows.isEmpty) return [];

    // jumlah siswa yang sudah dinilai per tugas
    final nilai = await supabase
        .from('nilai')
        .select('tugas_id')
        .eq('jenis', 'tugas')
        .inFilter('tugas_id', [for (final r in rows) r['id'] as String]);
    final dinilai = <String, int>{};
    for (final n in nilai) {
      final id = n['tugas_id'] as String;
      dinilai[id] = (dinilai[id] ?? 0) + 1;
    }

    // jumlah siswa aktif per kelas
    final siswa = await supabase
        .from('siswa')
        .select('kelas_id')
        .eq('status', 'aktif')
        .inFilter('kelas_id', {for (final r in rows) r['kelas_id'] as String}.toList());
    final perKelas = <String, int>{};
    for (final s in siswa) {
      final id = s['kelas_id'] as String;
      perKelas[id] = (perKelas[id] ?? 0) + 1;
    }

    return [
      for (final r in rows)
        TugasGuru.fromJson(
          r,
          dinilai: dinilai[r['id']] ?? 0,
          jumlahSiswa: perKelas[r['kelas_id']] ?? 0,
        ),
    ];
  }

  /// Membuat tugas baru ([id] = null) atau mengubah tugas yang sudah ada.
  Future<void> simpanTugas({
    String? id,
    required KelasMapel kelasMapel,
    required String judul,
    String? deskripsi,
    required DateTime tenggat,
  }) async {
    final data = {
      'kelas_id': kelasMapel.kelasId,
      'mapel_id': kelasMapel.mapelId,
      'judul': judul,
      'deskripsi': (deskripsi == null || deskripsi.isEmpty) ? null : deskripsi,
      'tenggat': tenggat.toUtc().toIso8601String(),
    };

    if (id == null) {
      await supabase.from('tugas').insert({...data, 'guru_id': _uid});
      return;
    }
    final hasil = await supabase.from('tugas').update(data).eq('id', id).eq('guru_id', _uid).select('id');
    if (hasil.isEmpty) throw Exception('Tugas tidak bisa diubah.');
    // judul nilai mengikuti judul tugas, supaya di tampilan orang tua tetap sama
    await supabase.from('nilai').update({'judul': judul}).eq('tugas_id', id);
  }

  /// Menghapus tugas beserta nilainya.
  Future<void> hapusTugas(String id) async {
    await supabase.from('nilai').delete().eq('tugas_id', id);
    final hasil = await supabase.from('tugas').delete().eq('id', id).eq('guru_id', _uid).select('id');
    if (hasil.isEmpty) throw Exception('Tugas tidak bisa dihapus.');
  }

  // ------------------------------------------------------------------ penilaian

  /// Semua siswa aktif di kelas tugas + nilainya (null = belum dinilai).
  Future<List<NilaiSiswa>> getNilaiTugas(TugasGuru tugas) async {
    final siswa = await supabase
        .from('siswa')
        .select('id, nis, nama_lengkap')
        .eq('kelas_id', tugas.kelasId)
        .eq('status', 'aktif')
        .order('nama_lengkap');
    final nilai = await supabase.from('nilai').select('id, siswa_id, nilai').eq('tugas_id', tugas.id);
    final perSiswa = {for (final n in nilai) n['siswa_id'] as String: n};

    return [
      for (final s in siswa)
        NilaiSiswa(
          siswaId: s['id'] as String,
          nama: s['nama_lengkap'] as String,
          nis: s['nis'] as String,
          nilaiId: perSiswa[s['id']]?['id'] as String?,
          nilai: (perSiswa[s['id']]?['nilai'] as num?)?.toDouble(),
        ),
    ];
  }

  /// Menyimpan nilai. [nilaiBaru]: siswaId → nilai (null = kosongkan/hapus nilai).
  Future<void> simpanNilai(TugasGuru tugas, List<NilaiSiswa> lama, Map<String, double?> nilaiBaru) async {
    final ta = await _tahunAjaranAktif();
    final tambah = <Map<String, dynamic>>[];

    for (final s in lama) {
      if (!nilaiBaru.containsKey(s.siswaId)) continue;
      final baru = nilaiBaru[s.siswaId];
      if (baru == s.nilai) continue;

      if (s.nilaiId == null) {
        if (baru == null) continue;
        tambah.add({
          'siswa_id': s.siswaId,
          'mapel_id': tugas.mapelId,
          'guru_id': _uid,
          'tahun_ajaran_id': ta.id,
          'semester': ta.semester,
          'jenis': 'tugas',
          'tugas_id': tugas.id,
          'judul': tugas.judul,
          'nilai': baru,
        });
      } else if (baru == null) {
        await supabase.from('nilai').delete().eq('id', s.nilaiId!);
      } else {
        await supabase.from('nilai').update({'nilai': baru}).eq('id', s.nilaiId!);
      }
    }
    if (tambah.isNotEmpty) await supabase.from('nilai').insert(tambah);
  }
}
