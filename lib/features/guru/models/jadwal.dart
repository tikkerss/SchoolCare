enum StatusKelas { belumAbsen, berlangsung, digantikan, dibatalkan }

extension StatusKelasLabel on StatusKelas {
  String get label => switch (this) {
        StatusKelas.belumAbsen => 'Belum absen',
        StatusKelas.berlangsung => 'Berlangsung',
        StatusKelas.digantikan => 'Digantikan',
        StatusKelas.dibatalkan => 'Dibatalkan',
      };
}

class Jadwal {
  final String id;
  final String mapel;
  final String kelas;
  final String ruang;
  final String jamMulai;
  final String jamSelesai;
  final StatusKelas status;

  const Jadwal({
    required this.id,
    required this.mapel,
    required this.kelas,
    required this.ruang,
    required this.jamMulai,
    required this.jamSelesai,
    this.status = StatusKelas.belumAbsen,
  });
}