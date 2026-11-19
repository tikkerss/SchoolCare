/// Satu baris tabel `pengumuman`.
class Pengumuman {
  final String id, judul, isi, kategori;
  final String? lampiranUrl;
  final DateTime tanggal;
  final bool isPublished;

  Pengumuman.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        judul = j['judul'],
        isi = j['isi'],
        kategori = j['kategori'],
        lampiranUrl = j['lampiran_url'],
        tanggal = DateTime.parse(j['dipublikasikan_pada']).toLocal(),
        isPublished = j['is_published'] ?? true;
}

/// Satu baris tabel `agenda_sekolah` (+ daftar kelas dari `agenda_kelas`).
class Agenda {
  final String id, judul, kategori;
  final String? deskripsi, lokasi, jamMulai, jamSelesai, pakaian, perlengkapan, ketentuanLain;
  final DateTime mulai, selesai;
  final bool untukSemuaKelas;
  final bool menggantikanPelajaran;
  final List<String> kelasIds;

  Agenda.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        judul = j['judul'],
        kategori = j['kategori'],
        deskripsi = j['deskripsi'],
        lokasi = j['lokasi'],
        jamMulai = j['jam_mulai'],
        jamSelesai = j['jam_selesai'],
        pakaian = j['ketentuan_pakaian'],
        perlengkapan = j['perlengkapan'],
        ketentuanLain = j['ketentuan_lain'],
        mulai = DateTime.parse(j['tanggal_mulai']),
        selesai = DateTime.parse(j['tanggal_selesai']),
        untukSemuaKelas = j['untuk_semua_kelas'] ?? true,
        menggantikanPelajaran = j['menggantikan_pelajaran'] ?? false,
        kelasIds = [
          for (final k in (j['agenda_kelas'] as List? ?? const [])) k['kelas_id'] as String,
        ];

  bool berlangsungPada(DateTime d) {
    final t = DateTime(d.year, d.month, d.day);
    return !t.isBefore(mulai) && !t.isAfter(selesai);
  }

  bool beririsan(DateTime awal, DateTime akhir) => !mulai.isAfter(akhir) && !selesai.isBefore(awal);
}

/// Satu baris tabel `jadwal_pelajaran` (+ nama mapel dan guru).
class JadwalItem {
  final String id, hari, jamMulai, jamSelesai, mapel, guru;
  final int jamKe;
  final String? ruang;

  JadwalItem.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        hari = j['hari'],
        jamKe = j['jam_ke'],
        jamMulai = j['jam_mulai'],
        jamSelesai = j['jam_selesai'],
        ruang = j['ruang'],
        mapel = j['mata_pelajaran']['nama'],
        guru = j['guru']['nama_lengkap'];
}
