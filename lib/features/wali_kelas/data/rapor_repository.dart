import 'dart:typed_data';

import 'dummy_data.dart';
import 'models.dart';
import 'rapor_models.dart';

abstract class RaporRepository {
  Future<Kelas?> getKelasWali();
  Future<String> getSemesterAktif();
  Future<List<RaporRingkas>> getDaftarRapor(String kelasId);
  Future<RaporDetail> getRapor(String siswaId);
  Future<void> simpanDraft(RaporDetail rapor);

  /// Upload PDF ke Storage, mengembalikan path yang disimpan di kolom file.
  Future<String> uploadPdf(String siswaId, String namaFile, Uint8List isiFile);
  Future<void> terbitkan(String siswaId);
  Future<void> konfirmasiPengambilan(String siswaId);
}

class DummyRaporRepository implements RaporRepository {
  DummyRaporRepository() {
    for (var i = 0; i < dummySiswa.length; i++) {
      _data[dummySiswa[i].id] = _buat(dummySiswa[i], i);
    }
  }

  static const _semester = 'Ganjil 2026/2027';
  static const _mapel = [
    ('m1', 'Pendidikan Agama'),
    ('m2', 'Bahasa Indonesia'),
    ('m3', 'Matematika'),
    ('m4', 'IPA'),
    ('m5', 'IPS'),
    ('m6', 'Bahasa Inggris'),
    ('m7', 'PJOK'),
  ];

  /// Disimpan di memori, jadi perubahan bertahan selama aplikasi jalan.
  final Map<String, RaporDetail> _data = {};

  RaporDetail _buat(Siswa s, int idx) {
    final r = RaporDetail(
      siswa: s,
      semester: _semester,
      nilai: [
        for (var j = 0; j < _mapel.length; j++)
          NilaiMapel(
            mapelId: _mapel[j].$1,
            namaMapel: _mapel[j].$2,
            rataRataGuru: 68.0 + ((idx * 5 + j * 7) % 30),
          ),
      ],
    );
    // Variasi status awal supaya semua tampilan bisa dicoba.
    if (idx <= 1) {
      for (final n in r.nilai) {
        n.nilaiAkhir = n.rataRataGuru!.roundToDouble();
      }
      r.catatanWali = 'Pertahankan prestasi dan semangat belajarmu.';
      r.filePdf = 'wali-1/rapor_${s.nis}.pdf';
      r.isPublished = true;
      if (idx == 0) r.diambilPada = DateTime(2026, 11, 10, 9, 30);
    } else if (idx <= 3) {
      for (final n in r.nilai.take(4)) {
        n.nilaiAkhir = n.rataRataGuru!.roundToDouble();
      }
    }
    return r;
  }

  @override
  Future<Kelas?> getKelasWali() async {
    await jedaDummy(300);
    return dummyKelas;
  }

  @override
  Future<String> getSemesterAktif() async => _semester;

  @override
  Future<List<RaporRingkas>> getDaftarRapor(String kelasId) async {
    await jedaDummy(600);
    // Versi Supabase: siswa per kelas, left join ke rapor semester aktif.
    return [
      for (final s in dummySiswa)
        RaporRingkas(siswa: s, status: _data[s.id]!.status),
    ];
  }

  @override
  Future<RaporDetail> getRapor(String siswaId) async {
    await jedaDummy(500);
    // Versi Supabase: rapor + rapor_nilai(mata_pelajaran(nama)),
    // ditambah rata-rata dari tabel nilai per mapel (minta Backend buat view/RPC).
    return _data[siswaId]!
        .copy(); // salinan: perubahan baru tersimpan saat simpanDraft
  }

  @override
  Future<void> simpanDraft(RaporDetail rapor) async {
    await jedaDummy(700);
    // Versi Supabase: upsert ke rapor, lalu upsert semua baris rapor_nilai.
    _data[rapor.siswa.id] = rapor.copy();
  }

  @override
  Future<String> uploadPdf(
    String siswaId,
    String namaFile,
    Uint8List isiFile,
  ) async {
    await jedaDummy(1200);
    // Versi Supabase:
    // final path = '${db.auth.currentUser!.id}/rapor_${siswaId}_$namaFile';
    // await db.storage.from('rapor').uploadBinary(path, isiFile,
    //     fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'));
    // return path;
    return 'wali-1/rapor_${siswaId}_$namaFile';
  }

  @override
  Future<void> terbitkan(String siswaId) async {
    await jedaDummy(700);
    final r = _data[siswaId]!;
    if (!r.lengkap) {
      throw Exception('Nilai belum lengkap atau PDF belum diunggah.');
    }
    r.isPublished = true; // Supabase: update rapor set is_published = true
  }

  @override
  Future<void> konfirmasiPengambilan(String siswaId) async {
    await jedaDummy(700);
    final r = _data[siswaId]!;
    if (!r.isPublished) throw Exception('Rapor belum diterbitkan.');
    r.diambilPada =
        DateTime.now(); // Supabase: update rapor set diambil_pada = now()
  }
}
