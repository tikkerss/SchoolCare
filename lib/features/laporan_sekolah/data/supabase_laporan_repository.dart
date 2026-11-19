import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../wali_kelas/data/models.dart';
import '../../wali_kelas/data/rapor_models.dart';
import 'laporan_models.dart';
import 'laporan_repository.dart';

/// Versi Supabase dari LaporanRepository (pengganti DummyLaporanRepository).
/// Hanya akun Pihak Sekolah (manajemen) yang bisa membaca semua data ini (dijaga RLS).
class SupabaseLaporanRepository implements LaporanRepository {
  static const _hari = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];

  // ------------------------------------------------------------------ helper

  /// Tahun ajaran aktif: id, nama, dan semester aktif.
  Future<({String id, String nama, String semester})> _tahunAjaranAktif() async {
    final row = await supabase
        .from('tahun_ajaran')
        .select('id, nama, semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) throw Exception('Belum ada tahun ajaran aktif.');
    return (id: row['id'] as String, nama: row['nama'] as String, semester: row['semester_aktif'] as String);
  }

  /// Supabase membatasi 1000 baris per permintaan, jadi data besar diambil per halaman.
  Future<List<Map<String, dynamic>>> _semua(
    PostgrestTransformBuilder<PostgrestList> Function(int dari, int sampai) ambil,
  ) async {
    const ukuran = 1000;
    final hasil = <Map<String, dynamic>>[];
    for (var dari = 0;; dari += ukuran) {
      final halaman = await ambil(dari, dari + ukuran - 1);
      hasil.addAll(halaman);
      if (halaman.length < ukuran) return hasil;
    }
  }

  /// Kelas pada tahun ajaran aktif + nama wali kelasnya.
  Future<List<(Kelas, String)>> _kelasAktif(String tahunAjaranId) async {
    final rows = await supabase
        .from('kelas')
        .select('id, nama_kelas, wali:profiles!wali_kelas_id(nama_lengkap)')
        .eq('tahun_ajaran_id', tahunAjaranId)
        .order('tingkat')
        .order('nama_kelas');
    return [
      for (final r in rows)
        (
          Kelas(id: r['id'] as String, namaKelas: r['nama_kelas'] as String),
          (r['wali']?['nama_lengkap'] as String?) ?? 'Belum ada wali kelas',
        ),
    ];
  }

  /// Siswa aktif di kelas-kelas tersebut, dikelompokkan per kelas.
  Future<Map<String, List<Siswa>>> _siswaPerKelas(List<String> kelasIds) async {
    if (kelasIds.isEmpty) return {};
    final rows = await _semua(
      (a, b) => supabase
          .from('siswa')
          .select('id, nis, nama_lengkap, kelas_id')
          .inFilter('kelas_id', kelasIds)
          .eq('status', 'aktif')
          .order('nama_lengkap')
          .order('id')
          .range(a, b),
    );
    final hasil = <String, List<Siswa>>{};
    for (final r in rows) {
      hasil
          .putIfAbsent(r['kelas_id'] as String, () => [])
          .add(Siswa(id: r['id'] as String, nis: r['nis'] as String, nama: r['nama_lengkap'] as String));
    }
    return hasil;
  }

  (String, String) _rentangBulan(DateTime bulan) => (
    Fmt.db(DateTime(bulan.year, bulan.month, 1)),
    Fmt.db(DateTime(bulan.year, bulan.month + 1, 1)),
  );

  static DateTime _gabung(DateTime tanggal, String jam) {
    final p = jam.split(':');
    return DateTime(tanggal.year, tanggal.month, tanggal.day, int.parse(p[0]), int.parse(p[1]));
  }

  static StatusKelas? _statusKelas(String? s) => switch (s) {
    null => null,
    'berlangsung' => StatusKelas.berlangsung,
    'digantikan' => StatusKelas.digantikan,
    _ => StatusKelas.dibatalkan, // dibatalkan, dijadwalkan_ulang, kosong
  };

  // ------------------------------------------------------------------ absensi guru

  @override
  Future<List<AbsensiGuruItem>> getAbsensiGuruHarian(DateTime tanggal) async {
    if (tanggal.weekday == DateTime.sunday) return [];
    final ta = await _tahunAjaranAktif();

    // Semua jadwal hari itu; jadwal tanpa baris absensi = "belum absen".
    final jadwal = await supabase
        .from('jadwal_pelajaran')
        .select(
          'id, jam_ke, jam_mulai, kelas!inner(nama_kelas, tingkat, tahun_ajaran_id), '
          'mata_pelajaran(nama), guru:profiles!guru_id(nama_lengkap)',
        )
        .eq('hari', _hari[tanggal.weekday - 1])
        .eq('semester', ta.semester)
        .eq('kelas.tahun_ajaran_id', ta.id);

    final absen = await supabase
        .from('absensi_guru')
        .select(
          'id, jadwal_id, status_kehadiran, status_kelas, foto_url, latitude, longitude, '
          'foto_diambil_pada, berita_acara, keterangan_tidak_hadir, surat_url, '
          'pengganti:profiles!guru_pengganti_id(nama_lengkap)',
        )
        .eq('tanggal', Fmt.db(tanggal));
    final perJadwal = {for (final a in absen) a['jadwal_id'] as String: a};

    final hasil = <AbsensiGuruItem>[];
    for (final j in jadwal) {
      final a = perJadwal[j['id'] as String];
      final status = switch (a?['status_kehadiran']) {
        'hadir' => StatusKehadiranGuru.hadir,
        'tidak_hadir' => StatusKehadiranGuru.tidakHadir,
        _ => StatusKehadiranGuru.belumAbsen,
      };
      hasil.add(
        AbsensiGuruItem(
          id: (a?['id'] ?? j['id']) as String,
          tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
          jamKe: j['jam_ke'] as int,
          jamMulai: _gabung(tanggal, j['jam_mulai'] as String),
          mapel: (j['mata_pelajaran']?['nama'] as String?) ?? '-',
          kelas: j['kelas']['nama_kelas'] as String,
          guru: (j['guru']?['nama_lengkap'] as String?) ?? '-',
          status: status,
          statusKelas: _statusKelas(a?['status_kelas'] as String?),
          fotoPath: a?['foto_url'] as String?,
          lat: (a?['latitude'] as num?)?.toDouble(),
          lng: (a?['longitude'] as num?)?.toDouble(),
          waktuFoto: a?['foto_diambil_pada'] == null
              ? null
              : DateTime.parse(a!['foto_diambil_pada'] as String).toLocal(),
          beritaAcara: a?['berita_acara'] as String?,
          keterangan: a?['keterangan_tidak_hadir'] as String?,
          suratPath: a?['surat_url'] as String?,
          guruPengganti: a?['pengganti']?['nama_lengkap'] as String?,
        ),
      );
    }
    // urut per kelas, lalu jam ke-
    hasil.sort((x, y) {
      final k = x.kelas.compareTo(y.kelas);
      return k != 0 ? k : x.jamKe.compareTo(y.jamKe);
    });
    return hasil;
  }

  @override
  Future<List<RekapGuru>> getRekapGuruBulanan(DateTime bulan) async {
    final ta = await _tahunAjaranAktif();
    final (awal, akhir) = _rentangBulan(bulan);

    // Daftar guru + mapel/kelas yang diajar semester ini (dari jadwal).
    final jadwal = await _semua(
      (a, b) => supabase
          .from('jadwal_pelajaran')
          .select(
            'guru_id, kelas!inner(nama_kelas, tahun_ajaran_id), mata_pelajaran(nama), '
            'guru:profiles!guru_id(nama_lengkap)',
          )
          .eq('semester', ta.semester)
          .eq('kelas.tahun_ajaran_id', ta.id)
          .order('id')
          .range(a, b),
    );
    final nama = <String, String>{};
    final mapel = <String, Set<String>>{};
    final kelas = <String, Set<String>>{};
    for (final j in jadwal) {
      final id = j['guru_id'] as String;
      nama[id] = (j['guru']?['nama_lengkap'] as String?) ?? '-';
      mapel.putIfAbsent(id, () => {}).add((j['mata_pelajaran']?['nama'] as String?) ?? '-');
      kelas.putIfAbsent(id, () => {}).add(j['kelas']['nama_kelas'] as String);
    }

    final absen = await _semua(
      (a, b) => supabase
          .from('absensi_guru')
          .select('guru_id, status_kehadiran, latitude, longitude')
          .gte('tanggal', awal)
          .lt('tanggal', akhir)
          .order('id')
          .range(a, b),
    );
    final hadir = <String, int>{};
    final tidak = <String, int>{};
    final luar = <String, int>{};
    for (final a in absen) {
      final id = a['guru_id'] as String;
      if (a['status_kehadiran'] == 'hadir') {
        hadir[id] = (hadir[id] ?? 0) + 1;
        final jarak = jarakMeter(
          (a['latitude'] as num).toDouble(),
          (a['longitude'] as num).toDouble(),
          lokasiSekolah.lat,
          lokasiSekolah.lng,
        );
        if (jarak > radiusSekolahMeter) luar[id] = (luar[id] ?? 0) + 1;
      } else {
        tidak[id] = (tidak[id] ?? 0) + 1;
      }
    }

    final hasil = [
      for (final id in nama.keys)
        RekapGuru(
          guru: nama[id]!,
          // guru kelas SD mengajar banyak mapel → tampilkan kelasnya saja
          mapel: mapel[id]!.length <= 2 ? mapel[id]!.join(', ') : 'Guru kelas ${kelas[id]!.join(', ')}',
          hadir: hadir[id] ?? 0,
          tidakHadir: tidak[id] ?? 0,
          diLuarArea: luar[id] ?? 0,
        ),
    ]..sort((x, y) => x.guru.compareTo(y.guru));
    return hasil;
  }

  // ------------------------------------------------------------------ kehadiran siswa

  @override
  Future<List<RekapKelas>> getRekapKehadiranKelas(DateTime bulan) async {
    final ta = await _tahunAjaranAktif();
    final (awal, akhir) = _rentangBulan(bulan);
    final daftarKelas = await _kelasAktif(ta.id);
    final kelasIds = [for (final (k, _) in daftarKelas) k.id];
    final siswa = await _siswaPerKelas(kelasIds);

    final absen = kelasIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _semua(
            (a, b) => supabase
                .from('absensi_siswa')
                .select('siswa_id, status')
                .inFilter('kelas_id', kelasIds)
                .gte('tanggal', awal)
                .lt('tanggal', akhir)
                .order('id')
                .range(a, b),
          );
    final hitung = <String, Map<StatusAbsen, int>>{};
    for (final r in absen) {
      final perStatus = hitung.putIfAbsent(r['siswa_id'] as String, () => {});
      final s = StatusAbsen.fromDb(r['status'] as String);
      perStatus[s] = (perStatus[s] ?? 0) + 1;
    }

    return [
      for (final (k, wali) in daftarKelas)
        RekapKelas(
          kelas: k,
          waliKelas: wali,
          siswa: [
            for (final s in siswa[k.id] ?? const <Siswa>[])
              RekapSiswa(siswa: s, jumlah: hitung[s.id] ?? const {}),
          ],
        ),
    ];
  }

  // ------------------------------------------------------------------ rapor

  @override
  Future<List<RaporKelas>> getStatusRapor() async {
    final ta = await _tahunAjaranAktif();
    final daftarKelas = await _kelasAktif(ta.id);
    final siswa = await _siswaPerKelas([for (final (k, _) in daftarKelas) k.id]);

    final rapor = await _semua(
      (a, b) => supabase
          .from('rapor')
          .select('siswa_id, catatan_wali_kelas, file_url, is_published, diambil_pada, rapor_nilai(nilai_akhir)')
          .eq('tahun_ajaran_id', ta.id)
          .eq('semester', ta.semester)
          .order('id')
          .range(a, b),
    );
    final perSiswa = {for (final r in rapor) r['siswa_id'] as String: r};

    StatusRapor statusDari(Map<String, dynamic>? r) {
      if (r == null) return StatusRapor.belumDisusun;
      if (r['diambil_pada'] != null) return StatusRapor.diambil;
      if (r['is_published'] == true) return StatusRapor.terbit;
      final adaIsi = (r['rapor_nilai'] as List).any((n) => n['nilai_akhir'] != null) ||
          ((r['catatan_wali_kelas'] as String?) ?? '').isNotEmpty ||
          r['file_url'] != null;
      return adaIsi ? StatusRapor.draft : StatusRapor.belumDisusun;
    }

    final semester = '${ta.semester[0].toUpperCase()}${ta.semester.substring(1)} ${ta.nama}';
    return [
      for (final (k, wali) in daftarKelas)
        RaporKelas(
          kelas: k,
          waliKelas: wali,
          semester: semester,
          siswa: [
            for (final s in siswa[k.id] ?? const <Siswa>[])
              RaporRingkas(siswa: s, status: statusDari(perSiswa[s.id])),
          ],
        ),
    ];
  }
}

// ------------------------------------------------------------------ file di Storage

/// URL sementara (1 jam) untuk foto bukti absensi guru (bucket privat).
Future<String> urlFotoBuktiGuru(String path) =>
    supabase.storage.from('bukti-absensi-guru').createSignedUrl(path, 3600);

/// URL sementara (1 jam) untuk surat keterangan tidak hadir (bucket privat).
Future<String> urlSuratGuru(String path) => supabase.storage.from('surat').createSignedUrl(path, 3600);
