/// Satu siswa di kelas yang sedang diajar, dengan status kehadiran hari ini
/// (dari absensi pagi wali kelas) dan catatan guru hari ini.
class SiswaKelas {
  final String id, nama, nis;

  /// Nilai mentah absensi_siswa.status ('hadir', 'sakit', ...). null = belum diabsen wali kelas.
  final String? status;
  final String? keterangan;
  final List<CatatanSiswa> catatan;

  const SiswaKelas({
    required this.id,
    required this.nama,
    required this.nis,
    this.status,
    this.keterangan,
    this.catatan = const [],
  });
}

/// Satu baris tabel `catatan_siswa`: catatan guru tentang siswa,
/// bisa dibaca wali kelas dan orang tua siswa tersebut.
class CatatanSiswa {
  final String id, siswaId, isi, dibuatOlehId, dibuatOleh;
  final String? mapel;
  final DateTime waktu;

  CatatanSiswa.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        siswaId = j['siswa_id'] as String,
        isi = j['isi'] as String,
        dibuatOlehId = j['dibuat_oleh'] as String,
        dibuatOleh = (j['guru']?['nama_lengkap'] as String?) ?? '-',
        mapel = j['jadwal']?['mata_pelajaran']?['nama'] as String?,
        waktu = DateTime.parse(j['created_at'] as String).toLocal();
}

/// Daftar siswa + apakah catatan siswa berhasil dimuat.
class DaftarSiswa {
  final List<SiswaKelas> siswa;
  final bool catatanAktif;

  const DaftarSiswa(this.siswa, {required this.catatanAktif});

  int jumlah(String status) => siswa.where((s) => s.status == status).length;
  int get belumDiabsen => siswa.where((s) => s.status == null).length;
}
