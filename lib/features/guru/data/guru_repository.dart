import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bukti_foto.dart';
import '../models/jadwal.dart';

/// Data untuk tampilan Guru, diambil dari Supabase.
/// Hak akses dijaga RLS: guru hanya bisa mengabsen jadwal miliknya sendiri, pada hari ini.
class GuruRepository {
  static const _hari = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];

  String get _uid => supabase.auth.currentUser!.id;

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
        .from('tahun_ajaran')
        .select('id, semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
    if (ta == null) return [];

    final jadwal = await supabase
        .from('jadwal_pelajaran')
        .select('id, jam_mulai, jam_selesai, ruang, kelas!inner(nama_kelas, tahun_ajaran_id), mata_pelajaran(nama)')
        .eq('guru_id', _uid)
        .eq('hari', _hari[hariIni.weekday - 1])
        .eq('semester', ta['semester_aktif'] as String)
        .eq('kelas.tahun_ajaran_id', ta['id'] as String)
        .order('jam_mulai');
    if (jadwal.isEmpty) return [];

    final absen = await supabase
        .from('absensi_guru')
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
    await supabase.storage.from('bukti-absensi-guru').upload(
          path,
          bukti.file,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

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
  }
}
