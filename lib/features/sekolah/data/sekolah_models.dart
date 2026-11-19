// Model untuk halaman admin Pihak Sekolah. Nama key = nama kolom di Supabase.

const daftarHari = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu'];

String hurufBesarAwal(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Tabel `tahun_ajaran`
class TahunAjaran {
  final String id, nama, semesterAktif;
  final DateTime tanggalMulai, tanggalSelesai;
  final bool isActive;

  TahunAjaran.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        nama = j['nama'],
        semesterAktif = j['semester_aktif'],
        tanggalMulai = DateTime.parse(j['tanggal_mulai']),
        tanggalSelesai = DateTime.parse(j['tanggal_selesai']),
        isActive = j['is_active'] ?? false;
}

/// Tabel `kelas` (+ nama wali & tahun ajaran)
class Kelas {
  final String id, tahunAjaranId, namaKelas;
  final int tingkat;
  final String? ruang, waliKelasId, waliNama, tahunAjaranNama;

  Kelas.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        tahunAjaranId = j['tahun_ajaran_id'],
        namaKelas = j['nama_kelas'],
        tingkat = j['tingkat'],
        ruang = j['ruang'],
        waliKelasId = j['wali_kelas_id'],
        waliNama = j['wali']?['nama_lengkap'],
        tahunAjaranNama = j['tahun_ajaran']?['nama'];
}

/// Tabel `siswa` (+ nama kelas)
class Siswa {
  final String id, nis, nama, jenisKelamin, status;
  final String? nisn, alamat, kelasId, kelasNama;
  final DateTime? tanggalLahir;

  Siswa.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        nis = j['nis'],
        nisn = j['nisn'],
        nama = j['nama_lengkap'],
        jenisKelamin = j['jenis_kelamin'],
        tanggalLahir = j['tanggal_lahir'] == null ? null : DateTime.parse(j['tanggal_lahir']),
        alamat = j['alamat'],
        kelasId = j['kelas_id'],
        kelasNama = j['kelas']?['nama_kelas'],
        status = j['status'];
}

/// Orang tua yang terhubung ke seorang siswa (tabel `orang_tua_siswa` + profiles)
class OrtuTerhubung {
  final String ortuId, nama, email, hubungan;

  OrtuTerhubung.fromJson(Map<String, dynamic> j)
      : ortuId = j['ortu']['id'],
        nama = j['ortu']['nama_lengkap'],
        email = j['ortu']['email'],
        hubungan = j['hubungan'];
}

/// Tabel `mata_pelajaran`
class MataPelajaran {
  final String id, kode, nama;

  MataPelajaran.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        kode = j['kode'],
        nama = j['nama'];
}

/// Tabel `jadwal_pelajaran` (+ nama mapel & guru)
class JadwalAdmin {
  final String id, kelasId, mapelId, mapelNama, guruId, guruNama, semester, hari, jamMulai, jamSelesai;
  final int jamKe;
  final String? ruang;

  JadwalAdmin.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        kelasId = j['kelas_id'],
        mapelId = j['mapel_id'],
        mapelNama = j['mata_pelajaran']?['nama'] ?? '-',
        guruId = j['guru_id'],
        guruNama = j['guru']?['nama_lengkap'] ?? '-',
        semester = j['semester'],
        hari = j['hari'],
        jamKe = j['jam_ke'],
        jamMulai = j['jam_mulai'],
        jamSelesai = j['jam_selesai'],
        ruang = j['ruang'];
}

/// Satu baris view `v_laporan_absensi_guru`
class LaporanGuru {
  final String id, hari, jamMulai, jamSelesai, namaKelas, mapel, guru, statusKehadiran, statusKelas, fotoUrl;
  final int jamKe;
  final String? guruPengganti, beritaAcara, keteranganTidakHadir, suratUrl;
  final double latitude, longitude;
  final DateTime fotoDiambilPada;

  LaporanGuru.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        hari = j['hari'],
        jamKe = j['jam_ke'],
        jamMulai = j['jam_mulai'],
        jamSelesai = j['jam_selesai'],
        namaKelas = j['nama_kelas'],
        mapel = j['mata_pelajaran'],
        guru = j['guru'],
        statusKehadiran = j['status_kehadiran'],
        statusKelas = j['status_kelas'],
        guruPengganti = j['guru_pengganti'],
        fotoUrl = j['foto_url'],
        latitude = (j['latitude'] as num).toDouble(),
        longitude = (j['longitude'] as num).toDouble(),
        fotoDiambilPada = DateTime.parse(j['foto_diambil_pada']).toLocal(),
        beritaAcara = j['berita_acara'],
        keteranganTidakHadir = j['keterangan_tidak_hadir'],
        suratUrl = j['surat_url'];
}

/// Satu baris view `v_rekap_kehadiran_siswa`
class RekapSiswa {
  final String siswaId, nama;
  final int hadir, terlambat, izin, sakit, alpa;

  RekapSiswa.fromJson(Map<String, dynamic> j)
      : siswaId = j['siswa_id'],
        nama = j['nama_lengkap'],
        hadir = j['hadir'] ?? 0,
        terlambat = j['terlambat'] ?? 0,
        izin = j['izin'] ?? 0,
        sakit = j['sakit'] ?? 0,
        alpa = j['alpa'] ?? 0;
}
