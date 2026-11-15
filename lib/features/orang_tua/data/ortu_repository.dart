import 'package:flutter/foundation.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_dummy.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';

/// Semua data untuk tampilan Orang Tua.
///
/// SEKARANG: mengambil dari OrtuDummy (tanpa Supabase).
/// NANTI (Supabase siap): ganti isi tiap method dengan query Supabase.
/// Nama method & tipe kembaliannya JANGAN diubah, supaya halaman tidak perlu ikut diubah.
class OrtuRepository {
  /// Jeda kecil supaya loading terlihat seperti mengambil data dari internet.
  static Future<void> _jeda() => Future.delayed(const Duration(milliseconds: 300));

  Future<List<Anak>> getAnak() async {
    await _jeda();
    return OrtuDummy.anak().map(Anak.fromJson).toList();
  }

  // ------------------------------------------------------------------ Kehadiran
  Future<AbsensiHarian?> getAbsensiHariIni(String siswaId) async {
    await _jeda();
    final row = OrtuDummy.absensiHariIni(siswaId);
    return row == null ? null : AbsensiHarian.fromJson(row);
  }

  Future<List<AbsensiHarian>> getAbsensiBulan(String siswaId, DateTime bulan) async {
    await _jeda();
    return OrtuDummy.absensiBulan(siswaId, bulan).map(AbsensiHarian.fromJson).toList();
  }

  Future<List<RiwayatStatus>> getRiwayatStatus(String absensiId) async {
    await _jeda();
    return OrtuDummy.riwayat(absensiId).map(RiwayatStatus.fromJson).toList();
  }

  /// "Realtime": [onBerubah] dipanggil setiap kali absensi berubah (mis. setelah pengajuan izin).
  /// Mengembalikan fungsi untuk BERHENTI memantau → panggil di dispose().
  VoidCallback pantauAbsensi(String siswaId, VoidCallback onBerubah) {
    OrtuDummy.perubahan.addListener(onBerubah);
    return () => OrtuDummy.perubahan.removeListener(onBerubah);
  }

  // ------------------------------------------------------------------ Izin / sakit
  Future<void> ajukanIzin({
    required String siswaId,
    required String jenis, // 'izin' | 'sakit'
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    String? namaLampiran,
  }) async {
    await _jeda();
    OrtuDummy.ajukanIzin(siswaId: siswaId, jenis: jenis, mulai: mulai, selesai: selesai, alasan: alasan);
  }

  // ------------------------------------------------------------------ Aktivitas harian
  Future<List<AktivitasKelas>> getAktivitasHarian(String kelasId, DateTime tanggal) async {
    await _jeda();
    return OrtuDummy.aktivitas(kelasId, tanggal).map(AktivitasKelas.fromJson).toList();
  }

  // ------------------------------------------------------------------ Akademik
  Future<List<Tugas>> getTugas(String kelasId) async {
    await _jeda();
    return OrtuDummy.tugas(kelasId).map(Tugas.fromJson).toList();
  }

  Future<List<Ujian>> getUjian(String kelasId) async {
    await _jeda();
    return OrtuDummy.ujian(kelasId).map(Ujian.fromJson).toList();
  }

  Future<List<Nilai>> getNilai(String siswaId) async {
    await _jeda();
    return OrtuDummy.nilai(siswaId).map(Nilai.fromJson).toList();
  }

  Future<List<Rapor>> getRapor(String siswaId) async {
    await _jeda();
    return OrtuDummy.rapor(siswaId).map(Rapor.fromJson).toList();
  }

  // ------------------------------------------------------------------ Kontak & info
  Future<List<KontakGuru>> getKontakGuru(String kelasId) async {
    await _jeda();
    return OrtuDummy.kontak(kelasId).map(KontakGuru.fromJson).toList();
  }

  Future<List<PengumumanSingkat>> getPengumumanTerbaru({int limit = 3}) async {
    await _jeda();
    return OrtuDummy.pengumuman().take(limit).map(PengumumanSingkat.fromJson).toList();
  }
}
