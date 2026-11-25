/// Kombinasi kelas + mapel yang diajar guru (dari jadwal), untuk pilihan saat membuat tugas.
class KelasMapel {
  final String kelasId, namaKelas, mapelId, mapel;

  const KelasMapel({required this.kelasId, required this.namaKelas, required this.mapelId, required this.mapel});

  String get kunci => '$kelasId|$mapelId';
  String get label => '$mapel • Kelas $namaKelas';
}

/// Satu baris tabel `tugas` buatan guru yang login.
class TugasGuru {
  final String id, judul, kelasId, namaKelas, mapelId, mapel;
  final String? deskripsi;
  final DateTime tenggat;

  /// Jumlah siswa yang sudah dinilai / jumlah siswa aktif di kelas.
  final int dinilai, jumlahSiswa;

  const TugasGuru({
    required this.id,
    required this.judul,
    required this.kelasId,
    required this.namaKelas,
    required this.mapelId,
    required this.mapel,
    required this.tenggat,
    this.deskripsi,
    this.dinilai = 0,
    this.jumlahSiswa = 0,
  });

  factory TugasGuru.fromJson(Map<String, dynamic> j, {int dinilai = 0, int jumlahSiswa = 0}) => TugasGuru(
        id: j['id'] as String,
        judul: j['judul'] as String,
        deskripsi: j['deskripsi'] as String?,
        tenggat: DateTime.parse(j['tenggat'] as String).toLocal(),
        kelasId: j['kelas_id'] as String,
        namaKelas: j['kelas']['nama_kelas'] as String,
        mapelId: j['mapel_id'] as String,
        mapel: (j['mata_pelajaran']?['nama'] as String?) ?? '-',
        dinilai: dinilai,
        jumlahSiswa: jumlahSiswa,
      );

  bool get lewat => tenggat.isBefore(DateTime.now());
  KelasMapel get kelasMapel => KelasMapel(kelasId: kelasId, namaKelas: namaKelas, mapelId: mapelId, mapel: mapel);
}

/// Nilai satu siswa untuk satu tugas (baris tabel `nilai`, jenis = 'tugas').
class NilaiSiswa {
  final String siswaId, nama, nis;
  final String? nilaiId; // null = belum dinilai
  final double? nilai;

  const NilaiSiswa({required this.siswaId, required this.nama, required this.nis, this.nilaiId, this.nilai});
}
