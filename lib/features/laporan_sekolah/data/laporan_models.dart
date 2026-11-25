import 'dart:math';

import '../../wali_kelas/data/models.dart';
import '../../wali_kelas/data/rapor_models.dart';

// ======================= Absensi guru =======================

enum StatusKehadiranGuru {
  hadir('Hadir'),
  tidakHadir('Tidak hadir'),
  belumAbsen('Belum absen');

  const StatusKehadiranGuru(this.label);
  final String label;
}

/// Sesuai constraint di database:
/// hadir -> berlangsung, tidak hadir + pengganti -> digantikan, tanpa pengganti -> dibatalkan.
enum StatusKelas {
  berlangsung('Berlangsung'),
  digantikan('Digantikan'),
  dibatalkan('Dibatalkan');

  const StatusKelas(this.label);
  final String label;
}

/// Ganti dengan koordinat sekolah yang asli.
const lokasiSekolah = (lat: -7.2852792, lng: 112.7952975); // Gedung Tower 2 ITS
const radiusSekolahMeter = 200.0;

/// Jarak dua titik GPS dalam meter (rumus haversine).
double jarakMeter(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * r * asin(sqrt(a));
}

/// Satu baris absensi_guru (satu jam pelajaran pada satu tanggal).
class AbsensiGuruItem {
  const AbsensiGuruItem({
    required this.id,
    required this.tanggal,
    required this.jamKe,
    required this.jamMulai,
    required this.mapel,
    required this.kelas,
    required this.guru,
    required this.status,
    this.statusKelas,
    this.fotoPath,
    this.lat,
    this.lng,
    this.waktuFoto,
    this.beritaAcara,
    this.keterangan,
    this.suratPath,
    this.guruPengganti,
  });

  final String id;
  final DateTime tanggal;
  final int jamKe;
  final DateTime jamMulai;
  final String mapel;
  final String kelas;
  final String guru;
  final StatusKehadiranGuru status;
  final StatusKelas? statusKelas;

  // Kalau hadir
  final String? fotoPath; // path di Storage, tampilkan dengan createSignedUrl
  final double? lat;
  final double? lng;
  final DateTime? waktuFoto;
  final String? beritaAcara;

  // Kalau tidak hadir
  final String? keterangan;
  final String? suratPath;
  final String? guruPengganti;

  double? get jarakDariSekolah => (lat == null || lng == null)
      ? null
      : jarakMeter(lat!, lng!, lokasiSekolah.lat, lokasiSekolah.lng);

  bool get diLuarArea => (jarakDariSekolah ?? 0) > radiusSekolahMeter;
}

class RekapGuru {
  const RekapGuru({
    required this.guru,
    required this.mapel,
    required this.hadir,
    required this.tidakHadir,
    required this.diLuarArea,
  });

  final String guru;
  final String mapel;
  final int hadir;
  final int tidakHadir;
  final int diLuarArea;

  int get total => hadir + tidakHadir;
  double get persenHadir => total == 0 ? 0 : hadir / total * 100;
}

// ======================= Kehadiran siswa =======================

class RekapKelas {
  const RekapKelas({
    required this.kelas,
    required this.waliKelas,
    required this.siswa,
  });

  final Kelas kelas;
  final String waliKelas;
  final List<RekapSiswa> siswa;

  Map<StatusAbsen, int> get total => {
    for (final s in StatusAbsen.values)
      s: siswa.fold(0, (sum, r) => sum + r.jml(s)),
  };

  double get rataRata => siswa.isEmpty
      ? 0
      : siswa.fold<double>(0, (sum, r) => sum + r.persenHadir) / siswa.length;

  /// Siswa dengan kehadiran di bawah 80%.
  int get perluPerhatian => siswa.where((r) => r.persenHadir < 80).length;
}

// ======================= Rapor =======================

class RaporKelas {
  const RaporKelas({
    required this.kelas,
    required this.waliKelas,
    required this.semester,
    required this.siswa,
  });

  final Kelas kelas;
  final String waliKelas;
  final String semester;
  final List<RaporRingkas> siswa;

  int jml(StatusRapor s) => siswa.where((r) => r.status == s).length;

  /// Sudah terbit atau sudah diambil = dianggap selesai.
  int get selesai => jml(StatusRapor.terbit) + jml(StatusRapor.diambil);
  double get progres => siswa.isEmpty ? 0 : selesai / siswa.length;
}
