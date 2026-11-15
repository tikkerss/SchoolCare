import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Data dummy KHUSUS tampilan Orang Tua (tanpa Supabase).
///
/// Bentuk datanya sengaja SAMA dengan hasil query Supabase nanti, sehingga
/// `Model.fromJson` di ortu_models.dart sudah teruji. Saat Supabase siap,
/// cukup ganti isi method di ortu_repository.dart — file ini boleh dihapus.
class OrtuDummy {
  OrtuDummy._();

  static const pdfContoh = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  /// Bertambah setiap kali data berubah (pengganti realtime Supabase).
  static final perubahan = ValueNotifier<int>(0);

  static String _db(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  static DateTime get _hariIni {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ===================================================================
  // ANAK
  // ===================================================================
  static List<Map<String, dynamic>> anak() => [
        {
          'hubungan': 'ibu',
          'siswa': {
            'id': 's-andi',
            'nama_lengkap': 'Andi Pratama',
            'nis': '2026001',
            'foto_url': null,
            'kelas_id': 'k-7a',
            'kelas': {'nama_kelas': '7A'},
          },
        },
        {
          'hubungan': 'ibu',
          'siswa': {
            'id': 's-nisa',
            'nama_lengkap': 'Nisa Aulia Pratama',
            'nis': '2024045',
            'foto_url': null,
            'kelas_id': 'k-9b',
            'kelas': {'nama_kelas': '9B'},
          },
        },
      ];

  // ===================================================================
  // GURU, MAPEL, KELAS, JAM PELAJARAN
  // ===================================================================
  static const _guru = <String, (String, String)>{
    // id: (nama, nomor WhatsApp)
    'g-mtk': ('Budi Santoso, S.Pd.', '6281200000011'),
    'g-bin': ('Dewi Lestari, S.Pd.', '6281200000012'),
    'g-ipa': ('Rina Wulandari, S.Si.', '6281200000013'),
    'g-big': ('Ahmad Fauzi, S.Pd.', '6281200000014'),
    'g-ips': ('Sri Handayani, S.Pd.', '6281200000015'),
    'g-pjok': ('Joko Prasetyo, S.Pd.', '6281200000016'),
    'g-sbd': ('Maya Sari, S.Sn.', '6281200000017'),
    'g-ppkn': ('Hendra Gunawan, S.Pd.', '6281200000018'),
  };

  static const _mapel = <(String, String)>[
    ('Matematika', 'g-mtk'),
    ('Bahasa Indonesia', 'g-bin'),
    ('IPA', 'g-ipa'),
    ('Bahasa Inggris', 'g-big'),
    ('IPS', 'g-ips'),
    ('PJOK', 'g-pjok'),
    ('Seni Budaya', 'g-sbd'),
    ('PPKn', 'g-ppkn'),
  ];

  static const _kelas = <String, (String, String, int)>{
    // id: (nama kelas, id guru wali, geser jadwal)
    'k-7a': ('7A', 'g-bin', 0),
    'k-9b': ('9B', 'g-big', 3),
  };

  static const _jam = <(String, String)>[
    ('07:00:00', '07:40:00'),
    ('07:40:00', '08:20:00'),
    ('08:20:00', '09:00:00'),
    ('09:15:00', '09:55:00'),
    ('09:55:00', '10:35:00'),
    ('10:35:00', '11:15:00'),
  ];

  /// (nama mapel, id guru) untuk hari ke-[h] (0 = Senin) jam ke-[j] (0 = jam pertama)
  static (String, String) _slot(String kelasId, int h, int j) {
    final geser = _kelas[kelasId]?.$3 ?? 0;
    return _mapel[(h * 2 + j + geser) % _mapel.length];
  }

  // ===================================================================
  // AKTIVITAS HARIAN (bentuk = hasil RPC get_aktivitas_harian)
  // ===================================================================
  static List<Map<String, dynamic>> aktivitas(String kelasId, DateTime tanggal) {
    if (tanggal.weekday == DateTime.sunday) return [];
    final h = tanggal.weekday - 1;
    final hari = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final jamSekarang = DateFormat('HH:mm:ss').format(DateTime.now());
    final hasil = <Map<String, dynamic>>[];

    for (var j = 0; j < _jam.length; j++) {
      final (mapel, guruId) = _slot(kelasId, h, j);
      final guru = _guru[guruId]!.$1;
      final mulai = _jam[j].$1;
      final sudahMulai =
          hari.isBefore(_hariIni) || (hari == _hariIni && jamSekarang.compareTo(mulai) >= 0);

      var status = sudahMulai ? 'berlangsung' : 'terjadwal';
      var guruMengajar = guru;
      String? berita;
      String? foto;
      String? info;

      if (sudahMulai && j == 2) {
        status = 'digantikan';
        final pengganti = _guru['g-ppkn']!.$1;
        guruMengajar = pengganti == guru ? _guru['g-sbd']!.$1 : pengganti;
      }
      if (sudahMulai && j == 4 && h == 2) status = 'dibatalkan';
      if (tanggal.weekday == DateTime.friday && j < 2) {
        status = 'kegiatan';
        info = 'Sedang ada kegiatan: Jumat Sehat';
      }
      if (status == 'berlangsung' || status == 'digantikan') {
        berita = 'Membahas $mapel bab ${(j % 4) + 1}, dilanjutkan latihan soal di kelas.';
        foto = 'https://picsum.photos/seed/$kelasId-$h-$j/800/500';
      }

      hasil.add({
        'jam_ke': j + 1,
        'jam_mulai': mulai,
        'jam_selesai': _jam[j].$2,
        'ruang': 'Ruang ${_kelas[kelasId]?.$1 ?? ''}',
        'mata_pelajaran': mapel,
        'guru_terjadwal': guru,
        'guru_mengajar': guruMengajar,
        'status_kelas': status,
        'berita_acara': berita,
        'foto_url': foto,
        'info_kegiatan': info,
      });
    }
    return hasil;
  }

  // ===================================================================
  // KONTAK GURU (bentuk = view v_kontak_guru_kelas)
  // ===================================================================
  static List<Map<String, dynamic>> kontak(String kelasId) {
    final wali = _kelas[kelasId]?.$2;
    final mapelPerGuru = <String, Set<String>>{};
    for (var h = 0; h < 6; h++) {
      for (var j = 0; j < _jam.length; j++) {
        final (mapel, guruId) = _slot(kelasId, h, j);
        (mapelPerGuru[guruId] ??= <String>{}).add(mapel);
      }
    }
    if (wali != null) mapelPerGuru.putIfAbsent(wali, () => <String>{});

    final list = [
      for (final e in mapelPerGuru.entries)
        <String, dynamic>{
          'kelas_id': kelasId,
          'guru_id': e.key,
          'nama_lengkap': _guru[e.key]!.$1,
          'no_whatsapp': _guru[e.key]!.$2,
          'mata_pelajaran': e.value.isEmpty ? null : e.value.join(', '),
          'is_wali_kelas': e.key == wali,
        },
    ];
    list.sort((a, b) {
      final w = ((b['is_wali_kelas'] as bool) ? 1 : 0) - ((a['is_wali_kelas'] as bool) ? 1 : 0);
      return w != 0 ? w : (a['nama_lengkap'] as String).compareTo(b['nama_lengkap'] as String);
    });
    return list;
  }

  // ===================================================================
  // ABSENSI SISWA + RIWAYAT PERUBAHAN STATUS
  // ===================================================================
  static final _absensi = <String, Map<String, dynamic>>{}; // key: siswaId|yyyy-MM-dd
  static final _riwayat = <String, List<Map<String, dynamic>>>{}; // key: id absensi
  static bool _siap = false;

  static void _catat(String siswaId, DateTime d, String status, String? ket, String oleh, DateTime waktu) {
    final key = '$siswaId|${_db(d)}';
    final lama = _absensi[key];
    final id = (lama?['id'] as String?) ?? 'a-$key';
    _absensi[key] = {
      'id': id,
      'tanggal': _db(d),
      'status': status,
      'keterangan': ket,
      'updated_at': _iso(waktu),
    };
    (_riwayat[id] ??= []).add({
      'status_lama': lama?['status'],
      'status_baru': status,
      'keterangan': ket,
      'diubah_pada': _iso(waktu),
      'pengubah': {'nama_lengkap': oleh},
    });
  }

  static void _siapkan() {
    if (_siap) return;
    _siap = true;
    const wali = 'Dewi Lestari, S.Pd.';

    for (final siswaId in ['s-andi', 's-nisa']) {
      for (var i = 60; i >= 1; i--) {
        final d = _hariIni.subtract(Duration(days: i));
        if (d.weekday == DateTime.sunday) continue;
        final n = d.day + (siswaId == 's-nisa' ? 3 : 0);
        final status = n % 11 == 0
            ? 'sakit'
            : n % 13 == 0
                ? 'izin'
                : n % 7 == 0
                    ? 'terlambat'
                    : 'hadir';
        final ket = switch (status) {
          'sakit' => 'Demam, dikabari orang tua',
          'izin' => 'Acara keluarga',
          'terlambat' => 'Datang pukul 07.15',
          _ => null,
        };
        _catat(siswaId, d, status, ket, wali, DateTime(d.year, d.month, d.day, 7, 5));
      }
    }

    // Hari ini: absensi pagi + contoh perubahan status di tengah hari (Andi)
    final t = _hariIni;
    if (t.weekday != DateTime.sunday && DateTime.now().hour >= 7) {
      _catat('s-andi', t, 'hadir', null, wali, DateTime(t.year, t.month, t.day, 7, 5));
      _catat('s-nisa', t, 'hadir', null, 'Ahmad Fauzi, S.Pd.', DateTime(t.year, t.month, t.day, 7, 8));
      final ubah = DateTime(t.year, t.month, t.day, 10, 20);
      if (DateTime.now().isAfter(ubah)) {
        _catat('s-andi', t, 'sakit', 'Pusing saat jam ke-5, dijemput orang tua', 'Budi Santoso, S.Pd.', ubah);
      }
    }
  }

  static Map<String, dynamic>? absensiHariIni(String siswaId) {
    _siapkan();
    return _absensi['$siswaId|${_db(_hariIni)}'];
  }

  static List<Map<String, dynamic>> absensiBulan(String siswaId, DateTime bulan) {
    _siapkan();
    final awalan = '$siswaId|${DateFormat('yyyy-MM').format(bulan)}';
    return _absensi.entries.where((e) => e.key.startsWith(awalan)).map((e) => e.value).toList()
      ..sort((a, b) => (b['tanggal'] as String).compareTo(a['tanggal'] as String));
  }

  static List<Map<String, dynamic>> riwayat(String absensiId) {
    _siapkan();
    return List.of(_riwayat[absensiId] ?? const []);
  }

  /// Meniru trigger database: pengajuan izin langsung mengubah absensi anak.
  static void ajukanIzin({
    required String siswaId,
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
  }) {
    _siapkan();
    final akhir = DateTime(selesai.year, selesai.month, selesai.day);
    for (var d = DateTime(mulai.year, mulai.month, mulai.day);
        !d.isAfter(akhir);
        d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday == DateTime.sunday) continue;
      _catat(siswaId, d, jenis, 'Diajukan orang tua: $alasan', 'Orang tua', DateTime.now());
    }
    perubahan.value++;
  }

  // ===================================================================
  // AKADEMIK
  // ===================================================================
  static List<Map<String, dynamic>> tugas(String kelasId) {
    final t = _hariIni;
    return [
      {
        'id': 't1',
        'judul': 'Latihan Soal Persamaan Linear',
        'deskripsi': 'Kerjakan buku paket halaman 45 nomor 1–10 di buku tulis.',
        'tenggat': _iso(DateTime(t.year, t.month, t.day + 2, 23, 59)),
        'lampiran_url': null,
        'mata_pelajaran': {'nama': 'Matematika'},
      },
      {
        'id': 't2',
        'judul': 'Menulis Teks Deskripsi',
        'deskripsi': 'Tulis teks deskripsi tentang tempat wisata di kotamu, minimal 3 paragraf.',
        'tenggat': _iso(DateTime(t.year, t.month, t.day + 5, 23, 59)),
        'lampiran_url': pdfContoh,
        'mata_pelajaran': {'nama': 'Bahasa Indonesia'},
      },
      {
        'id': 't3',
        'judul': 'Laporan Pengamatan Tumbuhan',
        'deskripsi': 'Amati satu tanaman di rumah selama 3 hari dan catat perubahannya.',
        'tenggat': _iso(DateTime(t.year, t.month, t.day - 3, 23, 59)),
        'lampiran_url': null,
        'mata_pelajaran': {'nama': 'IPA'},
      },
    ];
  }

  static List<Map<String, dynamic>> ujian(String kelasId) {
    final t = _hariIni;
    return [
      {
        'id': 'u1',
        'judul': 'Ulangan Harian Bab 3',
        'jenis': 'ulangan_harian',
        'materi': 'Persamaan dan pertidaksamaan linear',
        'tanggal': _db(t.add(const Duration(days: 4))),
        'jam_mulai': '07:00:00',
        'ruang': 'Ruang kelas',
        'mata_pelajaran': {'nama': 'Matematika'},
      },
      {
        'id': 'u2',
        'judul': 'Ujian Tengah Semester',
        'jenis': 'uts',
        'materi': 'Bab 1–4',
        'tanggal': _db(t.add(const Duration(days: 14))),
        'jam_mulai': '07:30:00',
        'ruang': 'Aula',
        'mata_pelajaran': {'nama': 'IPA'},
      },
      {
        'id': 'u3',
        'judul': 'Praktik Lari 100 m',
        'jenis': 'praktik',
        'materi': null,
        'tanggal': _db(t.subtract(const Duration(days: 6))),
        'jam_mulai': '07:00:00',
        'ruang': 'Lapangan',
        'mata_pelajaran': {'nama': 'PJOK'},
      },
    ];
  }

  static List<Map<String, dynamic>> nilai(String siswaId) {
    const data = <(String, String, String, int)>[
      ('Matematika', 'UH Bab 1', 'ulangan_harian', 85),
      ('Matematika', 'Tugas Persamaan Linear', 'tugas', 90),
      ('Matematika', 'UH Bab 2', 'ulangan_harian', 78),
      ('Bahasa Indonesia', 'Teks Narasi', 'tugas', 88),
      ('Bahasa Indonesia', 'UH Bab 1', 'ulangan_harian', 82),
      ('IPA', 'Praktikum Sel', 'praktik', 92),
      ('IPA', 'UH Bab 1', 'ulangan_harian', 74),
      ('Bahasa Inggris', 'Speaking Test', 'praktik', 86),
    ];
    final geser = siswaId == 's-nisa' ? -4 : 0;
    return [
      for (var i = 0; i < data.length; i++)
        {
          'id': 'n$i',
          'judul': data[i].$2,
          'jenis': data[i].$3,
          'nilai': data[i].$4 + geser,
          'semester': 'ganjil',
          'mata_pelajaran': {'nama': data[i].$1},
        },
    ];
  }

  /// Andi punya rapor yang sudah diambil; Nisa belum (untuk tes tampilan kosong).
  static List<Map<String, dynamic>> rapor(String siswaId) {
    if (siswaId != 's-andi') return [];
    return [
      {
        'id': 'r1',
        'semester': 'genap',
        'file_url': pdfContoh,
        'catatan_wali_kelas': 'Andi aktif di kelas dan menunjukkan peningkatan di Matematika. Pertahankan!',
        'tahun_ajaran': {'nama': '2025/2026'},
        'rapor_nilai': [
          {
            'nilai_akhir': 86,
            'predikat': 'A',
            'deskripsi': 'Sangat baik dalam pemecahan masalah.',
            'mata_pelajaran': {'nama': 'Matematika'},
          },
          {
            'nilai_akhir': 84,
            'predikat': 'B',
            'deskripsi': 'Baik dalam menulis berbagai jenis teks.',
            'mata_pelajaran': {'nama': 'Bahasa Indonesia'},
          },
          {
            'nilai_akhir': 88,
            'predikat': 'A',
            'deskripsi': 'Sangat baik dalam kegiatan praktikum.',
            'mata_pelajaran': {'nama': 'IPA'},
          },
          {
            'nilai_akhir': 81,
            'predikat': 'B',
            'deskripsi': null,
            'mata_pelajaran': {'nama': 'Bahasa Inggris'},
          },
        ],
      },
    ];
  }

  // ===================================================================
  // PENGUMUMAN (ringkas, untuk beranda)
  // ===================================================================
  static List<Map<String, dynamic>> pengumuman() {
    final n = DateTime.now();
    return [
      {
        'id': 'p1',
        'judul': 'Pembagian Rapor Semester Ganjil',
        'isi': 'Pembagian rapor dilaksanakan hari Sabtu pukul 08.00–11.00 di kelas masing-masing.',
        'dipublikasikan_pada': _iso(n.subtract(const Duration(hours: 5))),
      },
      {
        'id': 'p2',
        'judul': 'Perubahan Jadwal PJOK Kelas 7',
        'isi': 'Mulai minggu depan, PJOK kelas 7 dipindah ke hari Rabu jam pertama.',
        'dipublikasikan_pada': _iso(n.subtract(const Duration(days: 2))),
      },
      {
        'id': 'p3',
        'judul': 'Tata Tertib Seragam',
        'isi': 'Siswa wajib memakai seragam batik setiap hari Kamis.',
        'dipublikasikan_pada': _iso(n.subtract(const Duration(days: 6))),
      },
    ];
  }
}
