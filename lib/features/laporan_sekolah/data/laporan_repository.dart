import '../../wali_kelas/data/models.dart';
import '../../wali_kelas/data/rapor_models.dart';
import 'laporan_models.dart';

abstract class LaporanRepository {
  Future<List<AbsensiGuruItem>> getAbsensiGuruHarian(DateTime tanggal);
  Future<List<RekapGuru>> getRekapGuruBulanan(DateTime bulan);
  Future<List<RekapKelas>> getRekapKehadiranKelas(DateTime bulan);
  Future<List<RaporKelas>> getStatusRapor();
}

class DummyLaporanRepository implements LaporanRepository {
  static const _kelas = [
    (Kelas(id: 'k1', namaKelas: 'VII A'), 'Bu Rina'),
    (Kelas(id: 'k2', namaKelas: 'VII B'), 'Pak Joko'),
    (Kelas(id: 'k3', namaKelas: 'VIII A'), 'Bu Sari'),
    (Kelas(id: 'k4', namaKelas: 'VIII B'), 'Pak Dedi'),
    (Kelas(id: 'k5', namaKelas: 'IX A'), 'Bu Lina'),
  ];

  static const _guru = [
    ('Pak Budi', 'Matematika'),
    ('Bu Siti', 'Bahasa Indonesia'),
    ('Pak Andi', 'IPA'),
    ('Bu Maya', 'Bahasa Inggris'),
    ('Pak Hasan', 'IPS'),
    ('Bu Dewi', 'Pendidikan Agama'),
    ('Pak Rudi', 'PJOK'),
  ];

  static const _nama = [
    'Ahmad Fauzi',
    'Bunga Lestari',
    'Citra Ayu',
    'Dimas Pratama',
    'Eka Saputra',
    'Fitri Handayani',
    'Gilang Ramadhan',
    'Hana Salsabila',
    'Indra Kurniawan',
    'Jihan Aulia',
    'Kevin Wijaya',
    'Laras Sekar',
    'Mira Anggraini',
    'Nanda Putra',
    'Oki Setiawan',
    'Putri Maharani',
    'Raka Aditya',
    'Salma Nurul',
    'Tegar Maulana',
    'Umi Kalsum',
    'Vino Bastian',
    'Wulan Sari',
    'Yoga Prasetyo',
    'Zahra Amelia',
    'Arif Hidayat',
    'Bella Safitri',
    'Candra Wibowo',
    'Dina Marlina',
    'Erlangga Putra',
    'Farah Diba',
    'Galih Santoso',
    'Hesti Purwani',
    'Irfan Hakim',
    'Joko Susanto',
    'Kirana Dewi',
    'Lutfi Hasan',
    'Mega Utami',
    'Naufal Rizky',
    'Olivia Tan',
    'Pandu Wirawan',
  ];

  static const _jamKe = [1, 3, 5, 7];
  static const _siswaPerKelas = 8;
  static const _semester = 'Ganjil 2026/2027';

  /// Status rapor per kelas: A = diambil, T = terbit, D = draft, B = belum disusun.
  static const _polaRapor = [
    'AAAAATTT',
    'TTTTDDDB',
    'DDDDDBBB',
    'ATTTTTTT',
    'BBBBBBBB',
  ];

  Future<void> _jeda([int ms = 500]) =>
      Future.delayed(Duration(milliseconds: ms));

  DateTime _tgl(DateTime t) => DateTime(t.year, t.month, t.day);

  List<DateTime> _hariSekolah(DateTime bulan) {
    final hariIni = _tgl(DateTime.now());
    final jumlahHari = DateTime(bulan.year, bulan.month + 1, 0).day;
    return [
          for (var d = 1; d <= jumlahHari; d++)
            DateTime(bulan.year, bulan.month, d),
        ]
        .where((t) => t.weekday != DateTime.sunday && !t.isAfter(hariIni))
        .toList();
  }

  Siswa _siswa(int k, int i) => Siswa(
    id: 'k$k-s$i',
    nis: '2024${k + 1}${i.toString().padLeft(2, '0')}',
    nama: _nama[(k * _siswaPerKelas + i) % _nama.length],
  );

  // ---------------- Absensi guru ----------------

  List<AbsensiGuruItem> _generateHari(DateTime tanggal) {
    final t = _tgl(tanggal);
    if (t.weekday == DateTime.sunday) return [];

    final now = DateTime.now();
    final hariIni = _tgl(now);
    final hasil = <AbsensiGuruItem>[];

    for (var k = 0; k < _kelas.length; k++) {
      for (var s = 0; s < _jamKe.length; s++) {
        final jamKe = _jamKe[s];
        final mulai = DateTime(
          t.year,
          t.month,
          t.day,
          7,
        ).add(Duration(minutes: 40 * (jamKe - 1)));
        final (guru, mapel) = _guru[(k * 2 + s + t.weekday) % _guru.length];
        final id = '${t.year}${t.month}${t.day}-$k-$s';
        final kelas = _kelas[k].$1.namaKelas;
        final n = (k * 3 + s * 5 + t.day * 7 + t.month) % 17;

        final belumWaktunya =
            t.isAfter(hariIni) || (t == hariIni && mulai.isAfter(now));

        if (belumWaktunya || (t == hariIni && n == 2)) {
          hasil.add(
            AbsensiGuruItem(
              id: id,
              tanggal: t,
              jamKe: jamKe,
              jamMulai: mulai,
              mapel: mapel,
              kelas: kelas,
              guru: guru,
              status: StatusKehadiranGuru.belumAbsen,
            ),
          );
        } else if (n == 0 || n == 1) {
          final pengganti = n == 1
              ? _guru[(k + s + 3) % _guru.length].$1
              : null;
          hasil.add(
            AbsensiGuruItem(
              id: id,
              tanggal: t,
              jamKe: jamKe,
              jamMulai: mulai,
              mapel: mapel,
              kelas: kelas,
              guru: guru,
              status: StatusKehadiranGuru.tidakHadir,
              statusKelas: pengganti == null
                  ? StatusKelas.dibatalkan
                  : StatusKelas.digantikan,
              keterangan: n == 0
                  ? 'Sakit, surat dokter terlampir'
                  : 'Dinas luar (pelatihan guru)',
              suratPath: n == 0
                  ? 'guru/surat_$id.pdf'
                  : 'guru/surat_tugas_$id.pdf',
              guruPengganti: pengganti,
            ),
          );
        } else {
          final luarArea = n == 16;
          final geser = ((n % 5) - 2) * 0.0002; // ±40 m
          hasil.add(
            AbsensiGuruItem(
              id: id,
              tanggal: t,
              jamKe: jamKe,
              jamMulai: mulai,
              mapel: mapel,
              kelas: kelas,
              guru: guru,
              status: StatusKehadiranGuru.hadir,
              statusKelas: StatusKelas.berlangsung,
              fotoPath: 'guru/foto_$id.jpg',
              lat: lokasiSekolah.lat + (luarArea ? 0.012 : geser),
              lng: lokasiSekolah.lng + (luarArea ? 0.009 : -geser),
              waktuFoto: mulai.add(Duration(minutes: 2 + n % 6)),
              beritaAcara:
                  'Membahas $mapel bab ${1 + n % 6}, dilanjutkan latihan soal dan diskusi kelompok.',
            ),
          );
        }
      }
    }
    return hasil;
  }

  @override
  Future<List<AbsensiGuruItem>> getAbsensiGuruHarian(DateTime tanggal) async {
    await _jeda(600);
    // Versi Supabase (manajemen boleh membaca absensi_guru lewat RLS):
    // db.from('absensi_guru')
    //   .select('*, jadwal_pelajaran(jam_ke, kelas(nama_kelas), mata_pelajaran(nama), '
    //           'profiles!guru_id(nama_lengkap)), pengganti:profiles!guru_pengganti_id(nama_lengkap)')
    //   .eq('tanggal', '2026-11-13');
    // Jadwal yang belum punya baris absensi = "belum absen" (ambil dari jadwal_pelajaran hari itu).
    return _generateHari(tanggal);
  }

  @override
  Future<List<RekapGuru>> getRekapGuruBulanan(DateTime bulan) async {
    await _jeda(600);
    // Versi Supabase: minta Backend membuat view/RPC rekap_absensi_guru(p_bulan).
    final hadir = <String, int>{};
    final tidak = <String, int>{};
    final luar = <String, int>{};
    for (final hari in _hariSekolah(bulan)) {
      for (final a in _generateHari(hari)) {
        if (a.status == StatusKehadiranGuru.hadir) {
          hadir[a.guru] = (hadir[a.guru] ?? 0) + 1;
          if (a.diLuarArea) luar[a.guru] = (luar[a.guru] ?? 0) + 1;
        } else if (a.status == StatusKehadiranGuru.tidakHadir) {
          tidak[a.guru] = (tidak[a.guru] ?? 0) + 1;
        }
      }
    }
    return [
      for (final (guru, mapel) in _guru)
        RekapGuru(
          guru: guru,
          mapel: mapel,
          hadir: hadir[guru] ?? 0,
          tidakHadir: tidak[guru] ?? 0,
          diLuarArea: luar[guru] ?? 0,
        ),
    ];
  }

  // ---------------- Kehadiran siswa ----------------

  StatusAbsen _statusSiswa(int k, int i, DateTime t) {
    final n = (k * 11 + i * 7 + t.day * 13 + t.month * 3) % 23;
    return switch (n) {
      0 => StatusAbsen.alpa,
      1 || 2 => StatusAbsen.sakit,
      3 => StatusAbsen.izin,
      4 || 5 => StatusAbsen.terlambat,
      _ => StatusAbsen.hadir,
    };
  }

  @override
  Future<List<RekapKelas>> getRekapKehadiranKelas(DateTime bulan) async {
    await _jeda(700);
    // Versi Supabase: RPC yang sama dengan rekap wali kelas, tanpa filter kelas,
    // misalnya rpc('rekap_absensi_sekolah', params: {'p_bulan': '2026-11-01'}).
    final hari = _hariSekolah(bulan);
    return [
      for (var k = 0; k < _kelas.length; k++)
        RekapKelas(
          kelas: _kelas[k].$1,
          waliKelas: _kelas[k].$2,
          siswa: [
            for (var i = 0; i < _siswaPerKelas; i++)
              RekapSiswa(
                siswa: _siswa(k, i),
                jumlah: {
                  for (final s in StatusAbsen.values)
                    s: hari.where((t) => _statusSiswa(k, i, t) == s).length,
                },
              ),
          ],
        ),
    ];
  }

  // ---------------- Rapor ----------------

  @override
  Future<List<RaporKelas>> getStatusRapor() async {
    await _jeda(600);
    // Versi Supabase: siswa per kelas left join rapor semester aktif,
    // status dihitung dari is_published dan diambil_pada.
    StatusRapor dariKode(String c) => switch (c) {
      'A' => StatusRapor.diambil,
      'T' => StatusRapor.terbit,
      'D' => StatusRapor.draft,
      _ => StatusRapor.belumDisusun,
    };
    return [
      for (var k = 0; k < _kelas.length; k++)
        RaporKelas(
          kelas: _kelas[k].$1,
          waliKelas: _kelas[k].$2,
          semester: _semester,
          siswa: [
            for (var i = 0; i < _siswaPerKelas; i++)
              RaporRingkas(
                siswa: _siswa(k, i),
                status: dariKode(_polaRapor[k][i]),
              ),
          ],
        ),
    ];
  }
}
