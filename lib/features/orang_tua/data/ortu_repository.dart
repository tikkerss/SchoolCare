import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Semua data untuk tampilan Orang Tua, diambil dari Supabase.
/// Hak akses dijaga RLS: orang tua hanya bisa melihat data anaknya sendiri.
///
/// Nama method & tipe kembaliannya JANGAN diubah, supaya halaman tidak perlu ikut diubah.
/// (Versi dummy lama ada di ortu_dummy.dart, kalau perlu mencoba tampilan tanpa internet.)
class OrtuRepository {
  String get _uid => supabase.auth.currentUser!.id;

  /// File di bucket privat tidak bisa dibuka langsung; ganti path-nya dengan URL sementara (1 jam).
  /// Kalau gagal (file tidak ada / tidak boleh dibaca), kolomnya dikosongkan supaya tidak tampil rusak.
  Future<List<Map<String, dynamic>>> _urlSementara(
    List<Map<String, dynamic>> rows,
    String kolom,
    String bucket,
  ) async {
    for (final r in rows) {
      final path = r[kolom] as String?;
      if (path == null || path.startsWith('http')) continue;
      try {
        r[kolom] = await supabase.storage.from(bucket).createSignedUrl(path, 3600);
      } catch (_) {
        r[kolom] = null;
      }
    }
    return rows;
  }

  Future<List<Anak>> getAnak() async {
    final rows = await supabase
        .from('orang_tua_siswa')
        .select('hubungan, siswa(id, nama_lengkap, nis, foto_url, kelas_id, kelas(nama_kelas))')
        .eq('orang_tua_id', _uid);
    final anak = rows.where((r) => r['siswa'] != null).map(Anak.fromJson).toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
    return anak;
  }

  // ------------------------------------------------------------------ Kehadiran
  static const _kolomAbsensi = 'id, tanggal, status, keterangan, updated_at';

  Future<AbsensiHarian?> getAbsensiHariIni(String siswaId) async {
    final row = await supabase
        .from('absensi_siswa')
        .select(_kolomAbsensi)
        .eq('siswa_id', siswaId)
        .eq('tanggal', Fmt.db(DateTime.now()))
        .maybeSingle();
    return row == null ? null : AbsensiHarian.fromJson(row);
  }

  Future<List<AbsensiHarian>> getAbsensiBulan(String siswaId, DateTime bulan) async {
    final rows = await supabase
        .from('absensi_siswa')
        .select(_kolomAbsensi)
        .eq('siswa_id', siswaId)
        .gte('tanggal', Fmt.db(DateTime(bulan.year, bulan.month, 1)))
        .lt('tanggal', Fmt.db(DateTime(bulan.year, bulan.month + 1, 1)))
        .order('tanggal', ascending: false);
    return rows.map(AbsensiHarian.fromJson).toList();
  }

  Future<List<RiwayatStatus>> getRiwayatStatus(String absensiId) async {
    final rows = await supabase
        .from('riwayat_absensi_siswa')
        .select('status_lama, status_baru, keterangan, diubah_pada, pengubah:profiles!diubah_oleh(nama_lengkap)')
        .eq('absensi_siswa_id', absensiId)
        .order('diubah_pada');
    return rows.map(RiwayatStatus.fromJson).toList();
  }

  /// Realtime: [onBerubah] dipanggil setiap kali absensi anak ini berubah
  /// (diisi wali kelas, diubah guru, atau setelah pengajuan izin).
  /// Mengembalikan fungsi untuk BERHENTI memantau → panggil di dispose().
  VoidCallback pantauAbsensi(String siswaId, VoidCallback onBerubah) {
    // nama channel unik: tab Beranda & Kehadiran memantau anak yang sama
    final channel = supabase
        .channel('absensi-$siswaId-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'absensi_siswa',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'siswa_id', value: siswaId),
          callback: (_) => onBerubah(),
        )
        .subscribe();
    return () => supabase.removeChannel(channel);
  }

  // ------------------------------------------------------------------ Izin / sakit
  /// Setelah tersimpan, trigger di database langsung mengubah status kehadiran anak
  /// pada tanggal-tanggal tersebut.
  Future<void> ajukanIzin({
    required String siswaId,
    required String jenis, // 'izin' | 'sakit'
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    String? namaLampiran,
    File? lampiran, // surat dokter / surat izin (jpg, png, pdf)
  }) async {
    String? lampiranPath;
    if (lampiran != null) {
      final ext = lampiran.path.split('.').last.toLowerCase();
      lampiranPath = '$_uid/izin_${siswaId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('surat').upload(
            lampiranPath,
            lampiran,
            fileOptions: FileOptions(contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext'),
          );
    }
    await supabase.from('pengajuan_izin').insert({
      'siswa_id': siswaId,
      'diajukan_oleh': _uid,
      'jenis': jenis,
      'tanggal_mulai': Fmt.db(mulai),
      'tanggal_selesai': Fmt.db(selesai),
      'alasan': alasan,
      'lampiran_url': lampiranPath,
    });
  }

  // ------------------------------------------------------------------ Aktivitas harian
  Future<List<AktivitasKelas>> getAktivitasHarian(String kelasId, DateTime tanggal) async {
    final rows = await supabase.rpc<List<dynamic>>(
      'get_aktivitas_harian',
      params: {'p_kelas_id': kelasId, 'p_tanggal': Fmt.db(tanggal)},
    );
    final data = await _urlSementara(
      [for (final r in rows) Map<String, dynamic>.from(r as Map)],
      'foto_url',
      'bukti-absensi-guru',
    );
    return data.map(AktivitasKelas.fromJson).toList();
  }

  // ------------------------------------------------------------------ Akademik
  Future<List<Tugas>> getTugas(String kelasId) async {
    final rows = await supabase
        .from('tugas')
        .select('id, judul, deskripsi, lampiran_url, tenggat, mata_pelajaran(nama)')
        .eq('kelas_id', kelasId)
        .order('tenggat', ascending: false);
    return (await _urlSementara(rows, 'lampiran_url', 'lampiran')).map(Tugas.fromJson).toList();
  }

  Future<List<Ujian>> getUjian(String kelasId) async {
    final rows = await supabase
        .from('ujian')
        .select('id, judul, jenis, materi, jam_mulai, ruang, tanggal, mata_pelajaran(nama)')
        .eq('kelas_id', kelasId)
        .order('tanggal');
    return rows.map(Ujian.fromJson).toList();
  }

  Future<List<Nilai>> getNilai(String siswaId) async {
    final rows = await supabase
        .from('nilai')
        .select('id, judul, jenis, semester, nilai, mata_pelajaran(nama)')
        .eq('siswa_id', siswaId)
        .order('created_at', ascending: false);
    return rows.map(Nilai.fromJson).toList();
  }

  /// RLS hanya menampilkan rapor yang sudah terbit DAN sudah diambil di sekolah.
  Future<List<Rapor>> getRapor(String siswaId) async {
    final rows = await supabase
        .from('rapor')
        .select(
          'id, semester, file_url, catatan_wali_kelas, tahun_ajaran(nama), '
          'rapor_nilai(nilai_akhir, predikat, deskripsi, mata_pelajaran(nama))',
        )
        .eq('siswa_id', siswaId)
        .order('created_at', ascending: false);
    return (await _urlSementara(rows, 'file_url', 'rapor')).map(Rapor.fromJson).toList();
  }

  // ------------------------------------------------------------------ Kontak & info
  /// Satu baris per guru (view bisa berisi satu baris per mapel, jadi digabung di sini).
  Future<List<KontakGuru>> getKontakGuru(String kelasId) async {
    final rows = await supabase.from('v_kontak_guru_kelas').select().eq('kelas_id', kelasId);
    final perGuru = <String, Map<String, dynamic>>{};
    final mapel = <String, Set<String>>{};
    for (final r in rows) {
      final id = r['guru_id'] as String;
      final g = perGuru.putIfAbsent(id, () => Map<String, dynamic>.from(r)..['is_wali_kelas'] = false);
      if (r['is_wali_kelas'] == true) g['is_wali_kelas'] = true;
      final m = r['mata_pelajaran'] as String?;
      if (m != null) mapel.putIfAbsent(id, () => {}).addAll(m.split(', '));
    }
    for (final e in perGuru.entries) {
      final daftar = mapel[e.key] ?? const <String>{};
      // guru kelas SD mengajar banyak mapel → cukup ditulis "Guru kelas"
      e.value['mata_pelajaran'] = daftar.isEmpty ? null : (daftar.length > 2 ? 'Guru kelas' : daftar.join(', '));
    }
    final hasil = perGuru.values.map(KontakGuru.fromJson).toList()
      ..sort((a, b) => a.isWali == b.isWali ? a.nama.compareTo(b.nama) : (a.isWali ? -1 : 1));
    return hasil;
  }

  Future<List<PengumumanSingkat>> getPengumumanTerbaru({int limit = 3}) async {
    final rows = await supabase
        .from('pengumuman')
        .select('id, judul, isi, dipublikasikan_pada')
        .eq('is_published', true)
        .order('dipublikasikan_pada', ascending: false)
        .limit(limit);
    return rows.map(PengumumanSingkat.fromJson).toList();
  }
}
