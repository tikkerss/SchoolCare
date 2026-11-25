import 'package:schoolcare/core/utils/fmt.dart';

/// Satu jam pelajaran yang diampu guru hari ini, digabung dengan absensinya (kalau sudah ada).
/// Sumber: tabel `jadwal_pelajaran` + `absensi_guru` (lihat guru_repository.dart).
class Jadwal {
  final String id, kelasId, namaKelas, mapel, jamMulai, jamSelesai;
  final int jamKe;
  final String? ruang;

  /// Nilai mentah kolom `absensi_guru.status_kelas`, atau 'terjadwal' kalau belum diabsen.
  /// Tampilkan dengan `StatusBadge(jadwal.statusKelas)`.
  final String statusKelas;

  // ---- data absensi (semua null kalau belum diabsen) ----
  final String? absensiId;
  final String? statusKehadiran; // 'hadir' | 'tidak_hadir'
  final String? beritaAcara, keterangan, suratPath, fotoPath;
  final String? guruPenggantiId, guruPengganti;
  final DateTime? dibuatPada, diubahPada;

  /// true kalau tabel absensi_guru punya kolom updated_at.
  final bool adaKolomUpdatedAt;

  const Jadwal({
    required this.id,
    required this.kelasId,
    required this.namaKelas,
    required this.mapel,
    required this.jamKe,
    required this.jamMulai,
    required this.jamSelesai,
    required this.statusKelas,
    this.ruang,
    this.absensiId,
    this.statusKehadiran,
    this.beritaAcara,
    this.keterangan,
    this.suratPath,
    this.fotoPath,
    this.guruPenggantiId,
    this.guruPengganti,
    this.dibuatPada,
    this.diubahPada,
    this.adaKolomUpdatedAt = false,
  });

  /// [j] = baris jadwal_pelajaran (dengan relasi kelas & mata_pelajaran),
  /// [a] = baris absensi_guru hari ini untuk jadwal itu (null = belum diabsen).
  factory Jadwal.fromRows(Map<String, dynamic> j, Map<String, dynamic>? a) => Jadwal(
        id: j['id'] as String,
        jamKe: j['jam_ke'] as int,
        jamMulai: j['jam_mulai'] as String,
        jamSelesai: j['jam_selesai'] as String,
        ruang: j['ruang'] as String?,
        kelasId: j['kelas']['id'] as String,
        namaKelas: j['kelas']['nama_kelas'] as String,
        mapel: (j['mata_pelajaran']?['nama'] as String?) ?? '-',
        statusKelas: (a?['status_kelas'] as String?) ?? 'terjadwal',
        absensiId: a?['id'] as String?,
        statusKehadiran: a?['status_kehadiran'] as String?,
        beritaAcara: a?['berita_acara'] as String?,
        keterangan: a?['keterangan_tidak_hadir'] as String?,
        suratPath: a?['surat_url'] as String?,
        fotoPath: a?['foto_url'] as String?,
        guruPenggantiId: a?['guru_pengganti_id'] as String?,
        guruPengganti: a?['pengganti']?['nama_lengkap'] as String?,
        dibuatPada: _waktu(a?['created_at'] ?? a?['foto_diambil_pada']),
        diubahPada: _waktu(a?['updated_at']),
        adaKolomUpdatedAt: a?.containsKey('updated_at') ?? false,
      );

  static DateTime? _waktu(Object? v) => v is String ? DateTime.parse(v).toLocal() : null;

  bool get sudahDiabsen => absensiId != null;
  bool get hadir => statusKehadiran == 'hadir';

  /// true kalau absensi pernah diubah setelah pertama kali disimpan.
  bool get pernahDiubah =>
      dibuatPada != null && diubahPada != null && diubahPada!.difference(dibuatPada!).inSeconds > 5;

  /// Contoh: "Diabsen 19 Nov 2026, 07:02 · Terakhir diubah 19 Nov 2026, 08:10"
  String get infoWaktu {
    final bagian = <String>[
      if (dibuatPada != null) 'Diabsen ${Fmt.waktu(dibuatPada!)}',
      if (pernahDiubah) 'Terakhir diubah ${Fmt.waktu(diubahPada!)}',
    ];
    return bagian.join(' · ');
  }

  String get rentangJam => '${Fmt.jam(jamMulai)} - ${Fmt.jam(jamSelesai)}';
}

/// Pilihan guru pengganti.
class GuruSingkat {
  final String id, nama;

  /// true kalau guru ini juga punya jadwal mengajar di jam yang sama.
  final bool sibuk;

  const GuruSingkat({required this.id, required this.nama, this.sibuk = false});
}
