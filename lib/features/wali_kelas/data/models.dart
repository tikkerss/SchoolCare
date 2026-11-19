/// Status sesuai enum status absensi di database (absensi_siswa.status).
enum StatusAbsen {
  hadir('H', 'Hadir'),
  terlambat('T', 'Terlambat'),
  izin('I', 'Izin'),
  sakit('S', 'Sakit'),
  alpa('A', 'Alpa');

  const StatusAbsen(this.kode, this.label);
  final String kode;
  final String label;

  /// Nilai yang dikirim ke Supabase (nama enum = teks di database).
  String get dbValue => name;

  static StatusAbsen fromDb(String value) =>
      StatusAbsen.values.firstWhere((s) => s.name == value);
}

class Kelas {
  const Kelas({required this.id, required this.namaKelas});
  final String id;
  final String namaKelas;
}

class Siswa {
  const Siswa({required this.id, required this.nis, required this.nama});
  final String id;
  final String nis;
  final String nama;
}

/// Satu baris absensi pagi yang ditampilkan di halaman.
class BarisAbsensi {
  BarisAbsensi({
    required this.siswa,
    this.status = StatusAbsen.hadir,
    this.dariPengajuanIzin = false,
    this.keterangan,
  });

  final Siswa siswa;
  StatusAbsen status;

  /// true = status sudah diisi otomatis dari pengajuan izin orang tua,
  /// jadi wali kelas tidak bisa mengubahnya di halaman ini.
  final bool dariPengajuanIzin;
  final String? keterangan;
}

/// Satu baris dari tabel absensi_siswa (status terkini per hari).
class AbsensiHarian {
  const AbsensiHarian({
    required this.tanggal,
    required this.status,
    this.keterangan,
  });
  final DateTime tanggal;
  final StatusAbsen status;
  final String? keterangan;
}

/// Satu baris dari tabel riwayat_absensi_siswa (diisi trigger).
class RiwayatPerubahan {
  const RiwayatPerubahan({
    required this.tanggal,
    required this.statusLama,
    required this.statusBaru,
    required this.diubahOleh,
    required this.waktu,
  });

  final DateTime tanggal; // tanggal absensinya
  final StatusAbsen? statusLama; // null = baris baru dibuat
  final StatusAbsen statusBaru;
  final String diubahOleh;
  final DateTime waktu; // kapan perubahan dilakukan
}

/// Rekap satu siswa dalam satu bulan.
class RekapSiswa {
  const RekapSiswa({required this.siswa, required this.jumlah});

  final Siswa siswa;
  final Map<StatusAbsen, int> jumlah;

  int jml(StatusAbsen s) => jumlah[s] ?? 0;
  int get totalHari => jumlah.values.fold(0, (a, b) => a + b);

  /// Terlambat tetap dihitung masuk.
  double get persenHadir => totalHari == 0
      ? 0
      : (jml(StatusAbsen.hadir) + jml(StatusAbsen.terlambat)) / totalHari * 100;
}
