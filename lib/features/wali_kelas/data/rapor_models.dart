import 'models.dart';

enum StatusRapor {
  belumDisusun('Belum disusun'),
  draft('Draft'),
  terbit('Terbit'),
  diambil('Sudah diambil');

  const StatusRapor(this.label);
  final String label;
}

/// Aturan predikat sementara. Pastikan ke sekolah/tim, lalu ubah di sini saja.
String predikatDari(double nilai) {
  if (nilai >= 90) return 'A';
  if (nilai >= 80) return 'B';
  if (nilai >= 70) return 'C';
  return 'D';
}

/// Satu baris rapor_nilai.
class NilaiMapel {
  NilaiMapel({
    required this.mapelId,
    required this.namaMapel,
    this.nilaiAkhir,
    this.rataRataGuru,
  });

  final String mapelId;
  final String namaMapel;
  double? nilaiAkhir;

  /// Rata-rata dari tabel nilai (tugas + ujian) yang diinput guru mapel.
  final double? rataRataGuru;

  String? get predikat => nilaiAkhir == null ? null : predikatDari(nilaiAkhir!);
}

/// Satu baris tabel rapor + nilai-nilainya.
class RaporDetail {
  RaporDetail({
    required this.siswa,
    required this.semester,
    required this.nilai,
    this.catatanWali = '',
    this.filePdf,
    this.isPublished = false,
    this.diambilPada,
  });

  final Siswa siswa;
  final String semester;
  final List<NilaiMapel> nilai;
  String catatanWali;
  String? filePdf; // path di Storage
  bool isPublished;
  DateTime? diambilPada;

  StatusRapor get status {
    if (diambilPada != null) return StatusRapor.diambil;
    if (isPublished) return StatusRapor.terbit;
    final adaIsi =
        nilai.any((n) => n.nilaiAkhir != null) ||
        catatanWali.isNotEmpty ||
        filePdf != null;
    return adaIsi ? StatusRapor.draft : StatusRapor.belumDisusun;
  }

  /// Syarat terbit: semua nilai terisi dan PDF sudah diunggah.
  bool get lengkap =>
      nilai.every((n) => n.nilaiAkhir != null) && filePdf != null;

  RaporDetail copy() => RaporDetail(
    siswa: siswa,
    semester: semester,
    nilai: [
      for (final n in nilai)
        NilaiMapel(
          mapelId: n.mapelId,
          namaMapel: n.namaMapel,
          nilaiAkhir: n.nilaiAkhir,
          rataRataGuru: n.rataRataGuru,
        ),
    ],
    catatanWali: catatanWali,
    filePdf: filePdf,
    isPublished: isPublished,
    diambilPada: diambilPada,
  );
}

class RaporRingkas {
  const RaporRingkas({required this.siswa, required this.status});
  final Siswa siswa;
  final StatusRapor status;
}
