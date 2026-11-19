<<<<<<< HEAD
import 'dart:io';

import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';
import 'package:schoolcare/features/guru/models/jadwal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Semua data untuk tampilan Guru, langsung dari Supabase.
///
/// Tabel  : jadwal_pelajaran, absensi_guru, profiles, tahun_ajaran
/// Storage: bucket privat `bukti-absensi-guru` (foto) dan `surat` (surat izin/dokter).
///          File disimpan di folder ber-nama id guru: `<uid>/...` (sama seperti bucket rapor).
=======
import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bukti_foto.dart';
import '../models/jadwal.dart';

/// Data untuk tampilan Guru, diambil dari Supabase.
/// Hak akses dijaga RLS: guru hanya bisa mengabsen jadwal miliknya sendiri, pada hari ini.
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
class GuruRepository {
  static const _hari = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];

  String get _uid => supabase.auth.currentUser!.id;

<<<<<<< HEAD
  Future<({String id, String semester})> _tahunAjaranAktif() async {
    final row = await supabase
=======
  /// '07:00:00' → '07.00'
  static String _jam(String t) => t.substring(0, 5).replaceAll(':', '.');

  static StatusKelas _status(String? s) => switch (s) {
    null => StatusKelas.belumAbsen,
    'berlangsung' => StatusKelas.berlangsung,
    'digantikan' => StatusKelas.digantikan,
    _ => StatusKelas.dibatalkan, // dibatalkan, dijadwalkan_ulang, kosong
  };

  /// Jadwal mengajar guru yang login untuk hari ini, beserta status absennya.
  Future<List<Jadwal>> getJadwalHariIni() async {
    final hariIni = DateTime.now();
    if (hariIni.weekday == DateTime.sunday) return [];

    final ta = await supabase
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
        .from('tahun_ajaran')
        .select('id, semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
<<<<<<< HEAD
    if (row == null) throw Exception('Belum ada tahun ajaran aktif.');
    return (id: row['id'] as String, semester: row['semester_aktif'] as String);
  }

  // ------------------------------------------------------------------ Jadwal

  /// Jadwal mengajar guru yang login pada hari ini, beserta status absensinya.
  Future<List<Jadwal>> getJadwalHariIni() async {
    final hariIni = DateTime.now();
    if (hariIni.weekday == DateTime.sunday) return [];
    final ta = await _tahunAjaranAktif();

    final jadwal = await supabase
        .from('jadwal_pelajaran')
        .select(
          'id, jam_ke, jam_mulai, jam_selesai, ruang, '
          'kelas!inner(id, nama_kelas, tahun_ajaran_id), mata_pelajaran(nama)',
        )
        .eq('guru_id', _uid)
        .eq('hari', _hari[hariIni.weekday - 1])
        .eq('semester', ta.semester)
        .eq('kelas.tahun_ajaran_id', ta.id)
        .order('jam_ke');
=======
    if (ta == null) return [];

    final jadwal = await supabase
        .from('jadwal_pelajaran')
        .select('id, jam_mulai, jam_selesai, ruang, kelas!inner(nama_kelas, tahun_ajaran_id), mata_pelajaran(nama)')
        .eq('guru_id', _uid)
        .eq('hari', _hari[hariIni.weekday - 1])
        .eq('semester', ta['semester_aktif'] as String)
        .eq('kelas.tahun_ajaran_id', ta['id'] as String)
        .order('jam_mulai');
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
    if (jadwal.isEmpty) return [];

    final absen = await supabase
        .from('absensi_guru')
<<<<<<< HEAD
        // '*' supaya kolom tambahan (created_at / updated_at) ikut terbaca kalau ada.
        .select('*, pengganti:profiles!guru_pengganti_id(nama_lengkap)')
        .eq('tanggal', Fmt.db(hariIni))
        .inFilter('jadwal_id', [for (final j in jadwal) j['id'] as String]);
    final perJadwal = {for (final a in absen) a['jadwal_id'] as String: a};

    return [for (final j in jadwal) Jadwal.fromRows(j, perJadwal[j['id'] as String])];
  }

  /// Daftar guru aktif selain diri sendiri, untuk dipilih sebagai pengganti.
  /// Guru yang punya jadwal di jam yang sama ditandai `sibuk`.
  Future<List<GuruSingkat>> getGuruPengganti(Jadwal jadwal) async {
    final guru = await supabase
        .from('profiles')
        .select('id, nama_lengkap')
        .eq('role', 'guru')
        .eq('is_active', true)
        .neq('id', _uid)
        .order('nama_lengkap');

    var sibuk = <String>{};
    try {
      final ta = await _tahunAjaranAktif();
      final bentrok = await supabase
          .from('jadwal_pelajaran')
          .select('guru_id, kelas!inner(tahun_ajaran_id)')
          .eq('hari', _hari[DateTime.now().weekday - 1])
          .eq('semester', ta.semester)
          .eq('jam_ke', jadwal.jamKe)
          .eq('kelas.tahun_ajaran_id', ta.id);
      sibuk = {for (final b in bentrok) b['guru_id'] as String};
    } catch (_) {
      // Kalau tidak boleh membaca jadwal guru lain (RLS), cukup tampilkan semua guru.
    }

    final hasil = [
      for (final g in guru)
        GuruSingkat(
          id: g['id'] as String,
          nama: g['nama_lengkap'] as String,
          sibuk: sibuk.contains(g['id']),
        ),
    ];
    // guru yang kosong di jam itu ditaruh di atas
    hasil.sort((a, b) => a.sibuk == b.sibuk ? 0 : (a.sibuk ? 1 : -1));
    return hasil;
  }

  // ------------------------------------------------------------------ Absensi mengajar
  //
  // Absensi yang sudah disimpan bisa diubah lagi (pada hari yang sama).
  // Saat mengubah, foto boleh tidak diambil ulang ([bukti] = null → foto lama dipakai).

  /// Guru hadir → status kelas `berlangsung`.
  Future<void> absenHadir({
    required Jadwal jadwal,
    required BuktiFoto? bukti,
    required String beritaAcara,
  }) async {
    await _simpan(jadwal, bukti, {
      'status_kehadiran': 'hadir',
      'status_kelas': 'berlangsung',
      'berita_acara': beritaAcara,
      'keterangan_tidak_hadir': null,
      'surat_url': null,
      'guru_pengganti_id': null,
    });
  }

  /// Guru tidak hadir → status kelas `digantikan` (ada pengganti) atau `dibatalkan`.
  /// [surat] = file baru (opsional). [hapusSurat] = true untuk menghapus surat lama.
  /// Mengembalikan status kelas yang baru.
  Future<String> absenTidakHadir({
    required Jadwal jadwal,
    required BuktiFoto? bukti,
    required String keterangan,
    File? surat,
    String? namaSurat,
    bool hapusSurat = false,
    String? guruPenggantiId,
  }) async {
    final status = guruPenggantiId == null ? 'dibatalkan' : 'digantikan';
    await _simpan(jadwal, bukti, {
      'status_kehadiran': 'tidak_hadir',
      'status_kelas': status,
      'berita_acara': null,
      'keterangan_tidak_hadir': keterangan,
      'guru_pengganti_id': guruPenggantiId,
      if (surat != null)
        'surat_url': await _uploadSurat(jadwal, surat, namaSurat ?? 'surat')
      else if (hapusSurat || jadwal.hadir)
        'surat_url': null,
    });
    return status;
  }

  /// Insert (absen pertama kali) atau update (mengubah absensi yang sudah ada).
  Future<void> _simpan(Jadwal jadwal, BuktiFoto? bukti, Map<String, dynamic> isi) async {
    final baris = <String, dynamic>{
      ...isi,
      if (bukti != null) ...{
        'foto_url': await _uploadFoto(jadwal, bukti), // path di Storage, dibuka dengan createSignedUrl
        'latitude': bukti.latitude,
        'longitude': bukti.longitude,
        'akurasi_meter': bukti.akurasiMeter,
        'foto_diambil_pada': bukti.waktu.toUtc().toIso8601String(),
      },
    };

    if (jadwal.absensiId == null) {
      if (bukti == null) throw Exception('Foto bukti wajib diambil.');
      try {
        await supabase.from('absensi_guru').insert({
          ...baris,
          'jadwal_id': jadwal.id,
          'tanggal': Fmt.db(DateTime.now()),
          'guru_id': _uid,
        });
      } on PostgrestException catch (e) {
        // 23505 = melanggar unique (jadwal_id, tanggal)
        if (e.code == '23505') throw Exception('Jam pelajaran ini sudah diabsen. Tarik layar jadwal untuk memuat ulang.');
        rethrow;
      }
    } else {
      final hasil = await supabase
          .from('absensi_guru')
          .update({
            ...baris,
            // Kalau tabel punya kolom updated_at, isi dengan waktu sekarang
            // (kalau Backend memasang trigger, nilainya ditimpa trigger, hasilnya sama).
            if (jadwal.adaKolomUpdatedAt) 'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', jadwal.absensiId!)
          .select('id');
      // RLS yang menolak update tidak memunculkan error, hanya 0 baris berubah.
      if (hasil.isEmpty) throw Exception('Tidak punya izin mengubah absensi ini. Hubungi Backend (RLS update).');
    }
  }

  Future<String> _uploadFoto(Jadwal jadwal, BuktiFoto bukti) async {
    final path = '$_uid/${Fmt.db(DateTime.now())}_${jadwal.id}.jpg';
=======
        .select('jadwal_id, status_kelas')
        .eq('tanggal', Fmt.db(hariIni))
        .inFilter('jadwal_id', [for (final j in jadwal) j['id'] as String]);
    final status = {for (final a in absen) a['jadwal_id'] as String: a['status_kelas'] as String};

    return [
      for (final j in jadwal)
        Jadwal(
          id: j['id'] as String,
          mapel: (j['mata_pelajaran']?['nama'] as String?) ?? '-',
          kelas: j['kelas']['nama_kelas'] as String,
          ruang: (j['ruang'] as String?) ?? '-',
          jamMulai: _jam(j['jam_mulai'] as String),
          jamSelesai: _jam(j['jam_selesai'] as String),
          status: _status(status[j['id']]),
        ),
    ];
  }

  /// Absen HADIR: upload foto ke bucket `bukti-absensi-guru` (folder = id guru),
  /// lalu simpan baris absensi_guru. Trigger database memvalidasi jadwal & tanggalnya.
  Future<void> simpanHadir({
    required String jadwalId,
    required BuktiFoto bukti,
    required String beritaAcara,
  }) async {
    final tanggal = Fmt.db(DateTime.now());
    final path = '$_uid/${tanggal}_$jadwalId.jpg';
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
    await supabase.storage.from('bukti-absensi-guru').upload(
          path,
          bukti.file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
<<<<<<< HEAD
    return path;
  }

  Future<String> _uploadSurat(Jadwal jadwal, File file, String nama) async {
    final ext = nama.contains('.') ? nama.split('.').last.toLowerCase() : 'pdf';
    final path = '$_uid/${Fmt.db(DateTime.now())}_${jadwal.id}.$ext';
    await supabase.storage.from('surat').upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'pdf' ? 'application/pdf' : 'image/${ext == 'jpg' ? 'jpeg' : ext}',
          ),
        );
    return path;
=======

    await supabase.from('absensi_guru').insert({
      'jadwal_id': jadwalId,
      'tanggal': tanggal,
      'guru_id': _uid,
      'status_kehadiran': 'hadir',
      'status_kelas': 'berlangsung',
      'foto_url': path,
      'latitude': bukti.latitude,
      'longitude': bukti.longitude,
      'foto_diambil_pada': bukti.waktu.toUtc().toIso8601String(),
      'berita_acara': beritaAcara.trim(),
    });
>>>>>>> 2c73845239f5fe979a88ce28feb339eb0cedf83b
  }
}
