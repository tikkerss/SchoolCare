import 'models.dart';

/// Semua akses data absensi lewat sini. Halaman tidak tahu datanya
/// dari dummy atau Supabase, jadi nanti cukup ganti implementasinya.
abstract class AbsensiRepository {
  // --- Absensi pagi ---
  Future<Kelas?> getKelasWali();
  Future<List<BarisAbsensi>> getAbsensiHarian(String kelasId, DateTime tanggal);
  Future<void> simpanAbsensi(DateTime tanggal, List<BarisAbsensi> baris);

  // --- Rekap & riwayat ---
  Future<List<RekapSiswa>> getRekapBulanan(String kelasId, DateTime bulan);
  Future<List<AbsensiHarian>> getAbsensiSiswa(String siswaId, DateTime bulan);
  Future<List<RiwayatPerubahan>> getRiwayatPerubahan(
    String siswaId,
    DateTime bulan,
  );
}

class DummyAbsensiRepository implements AbsensiRepository {
  static const _kelas = Kelas(id: 'kelas-1', namaKelas: 'VII A');

  static const _siswa = [
    Siswa(id: 's1', nis: '2024001', nama: 'Ahmad Fauzi'),
    Siswa(id: 's2', nis: '2024002', nama: 'Bunga Lestari'),
    Siswa(id: 's3', nis: '2024003', nama: 'Citra Ayu'),
    Siswa(id: 's4', nis: '2024004', nama: 'Dimas Pratama'),
    Siswa(id: 's5', nis: '2024005', nama: 'Eka Saputra'),
    Siswa(id: 's6', nis: '2024006', nama: 'Fitri Handayani'),
    Siswa(id: 's7', nis: '2024007', nama: 'Gilang Ramadhan'),
    Siswa(id: 's8', nis: '2024008', nama: 'Hana Salsabila'),
  ];

  Future<void> _jeda([int ms = 500]) =>
      Future.delayed(Duration(milliseconds: ms));

  // ================= Absensi pagi =================

  @override
  Future<Kelas?> getKelasWali() async {
    await _jeda(400);
    return _kelas;
  }

  @override
  Future<List<BarisAbsensi>> getAbsensiHarian(
    String kelasId,
    DateTime tanggal,
  ) async {
    await _jeda(600);
    return _siswa.map((s) {
      // Contoh: Citra sudah diizinkan sakit oleh orang tua lewat aplikasi.
      if (s.id == 's3') {
        return BarisAbsensi(
          siswa: s,
          status: StatusAbsen.sakit,
          dariPengajuanIzin: true,
          keterangan: 'Demam, surat dokter terlampir',
        );
      }
      return BarisAbsensi(siswa: s);
    }).toList();
  }

  @override
  Future<void> simpanAbsensi(DateTime tanggal, List<BarisAbsensi> baris) async {
    await _jeda(800);
    // Versi Supabase:
    // await db.from('absensi_siswa').upsert(
    //   baris.where((b) => !b.dariPengajuanIzin).map((b) => {
    //     'siswa_id': b.siswa.id,
    //     'tanggal': tanggal.toIso8601String().substring(0, 10),
    //     'status': b.status.dbValue,
    //   }).toList(),
    //   onConflict: 'siswa_id,tanggal',
    // );
  }

  // ================= Rekap & riwayat =================

  /// Hari sekolah (Senin–Sabtu) dalam bulan itu, tidak lewat dari hari ini.
  List<DateTime> _hariSekolah(DateTime bulan) {
    final hariIni = DateTime.now();
    final jumlahHari = DateTime(bulan.year, bulan.month + 1, 0).day;
    return [
          for (var d = 1; d <= jumlahHari; d++)
            DateTime(bulan.year, bulan.month, d),
        ]
        .where((t) => t.weekday != DateTime.sunday)
        .where((t) => !t.isAfter(hariIni))
        .toList();
  }

  /// Status dummy yang selalu sama untuk siswa + tanggal yang sama.
  StatusAbsen _statusDummy(int idxSiswa, DateTime t) {
    final n = (idxSiswa * 7 + t.day * 13 + t.month * 3) % 23;
    return switch (n) {
      0 => StatusAbsen.alpa,
      1 || 2 => StatusAbsen.sakit,
      3 => StatusAbsen.izin,
      4 || 5 => StatusAbsen.terlambat,
      _ => StatusAbsen.hadir,
    };
  }

  List<AbsensiHarian> _generate(int idxSiswa, DateTime bulan) {
    return _hariSekolah(bulan).map((t) {
      final s = _statusDummy(idxSiswa, t);
      return AbsensiHarian(
        tanggal: t,
        status: s,
        keterangan: switch (s) {
          StatusAbsen.sakit => 'Sakit, ada surat dari orang tua',
          StatusAbsen.izin => 'Acara keluarga',
          StatusAbsen.terlambat => 'Datang 07:20',
          _ => null,
        },
      );
    }).toList();
  }

  @override
  Future<List<RekapSiswa>> getRekapBulanan(
    String kelasId,
    DateTime bulan,
  ) async {
    await _jeda(600);
    // Versi Supabase: sebaiknya minta Backend membuat view/RPC rekap,
    // misalnya rpc('rekap_absensi_kelas', params: {'p_kelas_id': ..., 'p_bulan': ...}),
    // supaya hitungannya dilakukan di database, bukan di HP.
    return [
      for (var i = 0; i < _siswa.length; i++)
        RekapSiswa(
          siswa: _siswa[i],
          jumlah: {
            for (final s in StatusAbsen.values)
              s: _generate(i, bulan).where((a) => a.status == s).length,
          },
        ),
    ];
  }

  @override
  Future<List<AbsensiHarian>> getAbsensiSiswa(
    String siswaId,
    DateTime bulan,
  ) async {
    await _jeda(400);
    // Versi Supabase:
    // db.from('absensi_siswa').select('tanggal, status, keterangan')
    //   .eq('siswa_id', siswaId)
    //   .gte('tanggal', awalBulan).lt('tanggal', awalBulanBerikutnya)
    //   .order('tanggal', ascending: false);
    final idx = _siswa.indexWhere((s) => s.id == siswaId);
    return _generate(idx, bulan).reversed.toList(); // terbaru di atas
  }

  @override
  Future<List<RiwayatPerubahan>> getRiwayatPerubahan(
    String siswaId,
    DateTime bulan,
  ) async {
    await _jeda(400);
    // Versi Supabase: tabel riwayat_absensi_siswa, join ke profiles untuk nama pengubah.
    final idx = _siswa.indexWhere((s) => s.id == siswaId);
    final hasil = <RiwayatPerubahan>[];
    for (final a in _generate(idx, bulan).reversed) {
      final t = a.tanggal;
      switch (a.status) {
        case StatusAbsen.izin:
          hasil.add(
            RiwayatPerubahan(
              tanggal: t,
              statusLama: null,
              statusBaru: StatusAbsen.izin,
              diubahOleh: 'Orang tua (pengajuan izin)',
              waktu: DateTime(t.year, t.month, t.day - 1, 19, 30),
            ),
          );
        case StatusAbsen.sakit:
          // Contoh: pagi hadir, lalu dipulangkan guru saat jam pelajaran.
          hasil.add(
            RiwayatPerubahan(
              tanggal: t,
              statusLama: StatusAbsen.hadir,
              statusBaru: StatusAbsen.sakit,
              diubahOleh: 'Pak Budi (guru Matematika)',
              waktu: DateTime(t.year, t.month, t.day, 10, 20),
            ),
          );
        case StatusAbsen.terlambat || StatusAbsen.alpa:
          hasil.add(
            RiwayatPerubahan(
              tanggal: t,
              statusLama: StatusAbsen.hadir,
              statusBaru: a.status,
              diubahOleh: 'Bu Rina (wali kelas)',
              waktu: DateTime(t.year, t.month, t.day, 7, 25),
            ),
          );
        case StatusAbsen.hadir:
          break;
      }
    }
    return hasil;
  }
}
