import 'package:intl/intl.dart';

/// Anak milik orang tua yang login (orang_tua_siswa + siswa + kelas).
class Anak {
  final String siswaId, nama, nis, hubungan, namaKelas;
  final String? kelasId, fotoUrl;

  Anak.fromJson(Map<String, dynamic> j)
    : hubungan = j['hubungan'],
      siswaId = j['siswa']['id'],
      nama = j['siswa']['nama_lengkap'],
      nis = j['siswa']['nis'],
      fotoUrl = j['siswa']['foto_url'],
      kelasId = j['siswa']['kelas_id'],
      namaKelas = j['siswa']['kelas']?['nama_kelas'] ?? '-';
}

/// Satu baris tabel `absensi_siswa`.
class AbsensiHarian {
  final String id, status;
  final String? keterangan;
  final DateTime tanggal, diperbarui;

  AbsensiHarian.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      status = j['status'],
      keterangan = j['keterangan'],
      tanggal = DateTime.parse(j['tanggal']),
      diperbarui = DateTime.parse(j['updated_at']).toLocal();
}

/// Satu baris tabel `riwayat_absensi_siswa`.
class RiwayatStatus {
  final String? statusLama, keterangan, oleh;
  final String statusBaru;
  final DateTime waktu;

  RiwayatStatus.fromJson(Map<String, dynamic> j)
    : statusLama = j['status_lama'],
      statusBaru = j['status_baru'],
      keterangan = j['keterangan'],
      oleh = j['pengubah']?['nama_lengkap'],
      waktu = DateTime.parse(j['diubah_pada']).toLocal();
}

/// Satu baris hasil RPC `get_aktivitas_harian`.
class AktivitasKelas {
  final int jamKe;
  final String jamMulai, jamSelesai, mapel, guruTerjadwal, guruMengajar, statusKelas;
  final String? ruang, beritaAcara, fotoUrl, infoKegiatan;

  AktivitasKelas.fromJson(Map<String, dynamic> j)
    : jamKe = j['jam_ke'],
      jamMulai = j['jam_mulai'],
      jamSelesai = j['jam_selesai'],
      ruang = j['ruang'],
      mapel = j['mata_pelajaran'],
      guruTerjadwal = j['guru_terjadwal'],
      guruMengajar = j['guru_mengajar'],
      statusKelas = j['status_kelas'],
      beritaAcara = j['berita_acara'],
      fotoUrl = j['foto_url'],
      infoKegiatan = j['info_kegiatan'];

  bool get digantikan => guruMengajar != guruTerjadwal;

  /// true kalau jam sekarang ada di antara jam mulai dan jam selesai (abaikan tanggal).
  bool get sedangBerlangsung {
    final now = DateFormat('HH:mm:ss').format(DateTime.now());
    return now.compareTo(jamMulai) >= 0 && now.compareTo(jamSelesai) < 0;
  }
}

class Tugas {
  final String id, judul, mapel;
  final String? deskripsi, lampiranUrl;
  final DateTime tenggat;

  Tugas.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      judul = j['judul'],
      mapel = j['mata_pelajaran']['nama'],
      deskripsi = j['deskripsi'],
      lampiranUrl = j['lampiran_url'],
      tenggat = DateTime.parse(j['tenggat']).toLocal();

  bool get lewat => tenggat.isBefore(DateTime.now());
}

class Ujian {
  final String id, judul, jenis, mapel;
  final String? materi, jamMulai, ruang;
  final DateTime tanggal;

  Ujian.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      judul = j['judul'],
      jenis = j['jenis'],
      mapel = j['mata_pelajaran']['nama'],
      materi = j['materi'],
      jamMulai = j['jam_mulai'],
      ruang = j['ruang'],
      tanggal = DateTime.parse(j['tanggal']);
}

class Nilai {
  final String id, judul, jenis, mapel, semester;
  final double nilai;

  Nilai.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      judul = j['judul'],
      jenis = j['jenis'],
      mapel = j['mata_pelajaran']['nama'],
      semester = j['semester'],
      nilai = (j['nilai'] as num).toDouble();
}

class RaporNilai {
  final String mapel;
  final double? nilaiAkhir;
  final String? predikat, deskripsi;

  RaporNilai.fromJson(Map<String, dynamic> j)
    : mapel = j['mata_pelajaran']['nama'],
      nilaiAkhir = (j['nilai_akhir'] as num?)?.toDouble(),
      predikat = j['predikat'],
      deskripsi = j['deskripsi'];
}

class Rapor {
  final String id, semester, tahunAjaran;
  final String? fileUrl, catatan;
  final List<RaporNilai> nilai;

  Rapor.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      semester = j['semester'],
      tahunAjaran = j['tahun_ajaran']['nama'],
      fileUrl = j['file_url'],
      catatan = j['catatan_wali_kelas'],
      nilai = [
        for (final n in (j['rapor_nilai'] as List? ?? const []))
          RaporNilai.fromJson(n as Map<String, dynamic>),
      ];
}

/// Satu baris view `v_kontak_guru_kelas`.
class KontakGuru {
  final String guruId, nama;
  final String? noWhatsapp, mapel;
  final bool isWali;

  KontakGuru.fromJson(Map<String, dynamic> j)
    : guruId = j['guru_id'],
      nama = j['nama_lengkap'],
      noWhatsapp = j['no_whatsapp'],
      mapel = j['mata_pelajaran'],
      isWali = j['is_wali_kelas'] ?? false;
}
