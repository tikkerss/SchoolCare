import 'dart:typed_data';

import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'absensi_repository.dart';
import 'kontak_repository.dart';
import 'models.dart';
import 'rapor_models.dart';
import 'rapor_repository.dart';

/// Versi Supabase dari repository Wali Kelas (pengganti Dummy*Repository).
/// Hak akses dijaga RLS: wali kelas hanya bisa membaca & mengubah data kelasnya.

String get _uid => supabase.auth.currentUser!.id;

/// Kelas yang diwalikan guru yang sedang login, pada tahun ajaran aktif.
Future<Kelas?> _kelasWali() async {
  final row = await supabase
      .from('kelas')
      .select('id, nama_kelas, tahun_ajaran!inner(is_active)')
      .eq('wali_kelas_id', _uid)
      .eq('tahun_ajaran.is_active', true)
      .maybeSingle();
  if (row == null) return null;
  return Kelas(id: row['id'] as String, namaKelas: row['nama_kelas'] as String);
}

Siswa _siswaDari(Map<String, dynamic> j) =>
    Siswa(id: j['id'] as String, nis: j['nis'] as String, nama: j['nama_lengkap'] as String);

/// Siswa aktif di satu kelas, urut nama.
Future<List<Siswa>> _siswaKelas(String kelasId) async {
  final rows = await supabase
      .from('siswa')
      .select('id, nis, nama_lengkap')
      .eq('kelas_id', kelasId)
      .eq('status', 'aktif')
      .order('nama_lengkap');
  return rows.map(_siswaDari).toList();
}

/// Batas tanggal satu bulan: [awal, awalBulanBerikutnya).
(String, String) _rentangBulan(DateTime bulan) => (
  Fmt.db(DateTime(bulan.year, bulan.month, 1)),
  Fmt.db(DateTime(bulan.year, bulan.month + 1, 1)),
);

String _hurufBesarAwal(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// =====================================================================
// ABSENSI
// =====================================================================
class SupabaseAbsensiRepository implements AbsensiRepository {
  /// Kolom absensi_siswa.kelas_id wajib diisi, jadi kelas terakhir yang dibuka disimpan di sini.
  String? _kelasId;

  @override
  Future<Kelas?> getKelasWali() async {
    final kelas = await _kelasWali();
    _kelasId = kelas?.id;
    return kelas;
  }

  @override
  Future<List<BarisAbsensi>> getAbsensiHarian(String kelasId, DateTime tanggal) async {
    _kelasId = kelasId;
    final siswa = await _siswaKelas(kelasId);
    final rows = await supabase
        .from('absensi_siswa')
        .select('siswa_id, status, keterangan, pengajuan_izin_id')
        .eq('kelas_id', kelasId)
        .eq('tanggal', Fmt.db(tanggal));
    final perSiswa = {for (final r in rows) r['siswa_id'] as String: r};

    return [
      for (final s in siswa)
        if (perSiswa[s.id] case final r?)
          BarisAbsensi(
            siswa: s,
            status: StatusAbsen.fromDb(r['status'] as String),
            dariPengajuanIzin: r['pengajuan_izin_id'] != null,
            keterangan: r['keterangan'] as String?,
          )
        else
          BarisAbsensi(siswa: s), // belum diabsen hari itu → default hadir
    ];
  }

  @override
  Future<void> simpanAbsensi(DateTime tanggal, List<BarisAbsensi> baris) async {
    final kelasId = _kelasId ?? (await getKelasWali())?.id;
    if (kelasId == null) throw Exception('Kelas yang diwalikan tidak ditemukan.');

    // Baris dari pengajuan izin orang tua tidak boleh ditimpa wali kelas.
    final data = [
      for (final b in baris.where((b) => !b.dariPengajuanIzin))
        {
          'siswa_id': b.siswa.id,
          'kelas_id': kelasId,
          'tanggal': Fmt.db(tanggal),
          'status': b.status.dbValue,
          'dicatat_oleh': _uid,
          'diubah_oleh': _uid,
        },
    ];
    if (data.isEmpty) return;
    await supabase.from('absensi_siswa').upsert(data, onConflict: 'siswa_id,tanggal');
  }

  @override
  Future<List<RekapSiswa>> getRekapBulanan(String kelasId, DateTime bulan) async {
    final (awal, akhir) = _rentangBulan(bulan);
    final siswa = await _siswaKelas(kelasId);
    final rows = await supabase
        .from('absensi_siswa')
        .select('siswa_id, status')
        .eq('kelas_id', kelasId)
        .gte('tanggal', awal)
        .lt('tanggal', akhir);

    final hitung = <String, Map<StatusAbsen, int>>{};
    for (final r in rows) {
      final perStatus = hitung.putIfAbsent(r['siswa_id'] as String, () => {});
      final status = StatusAbsen.fromDb(r['status'] as String);
      perStatus[status] = (perStatus[status] ?? 0) + 1;
    }
    return [for (final s in siswa) RekapSiswa(siswa: s, jumlah: hitung[s.id] ?? const {})];
  }

  @override
  Future<List<AbsensiHarian>> getAbsensiSiswa(String siswaId, DateTime bulan) async {
    final (awal, akhir) = _rentangBulan(bulan);
    final rows = await supabase
        .from('absensi_siswa')
        .select('tanggal, status, keterangan')
        .eq('siswa_id', siswaId)
        .gte('tanggal', awal)
        .lt('tanggal', akhir)
        .order('tanggal', ascending: false);
    return [
      for (final r in rows)
        AbsensiHarian(
          tanggal: DateTime.parse(r['tanggal'] as String),
          status: StatusAbsen.fromDb(r['status'] as String),
          keterangan: r['keterangan'] as String?,
        ),
    ];
  }

  @override
  Future<List<RiwayatPerubahan>> getRiwayatPerubahan(String siswaId, DateTime bulan) async {
    final (awal, akhir) = _rentangBulan(bulan);
    final rows = await supabase
        .from('riwayat_absensi_siswa')
        .select(
          'status_lama, status_baru, diubah_pada, '
          'absensi_siswa!inner(tanggal, siswa_id), '
          'pengubah:profiles!diubah_oleh(nama_lengkap)',
        )
        .eq('absensi_siswa.siswa_id', siswaId)
        .gte('absensi_siswa.tanggal', awal)
        .lt('absensi_siswa.tanggal', akhir)
        .order('diubah_pada', ascending: false);
    return [
      for (final r in rows)
        RiwayatPerubahan(
          tanggal: DateTime.parse(r['absensi_siswa']['tanggal'] as String),
          statusLama: r['status_lama'] == null ? null : StatusAbsen.fromDb(r['status_lama'] as String),
          statusBaru: StatusAbsen.fromDb(r['status_baru'] as String),
          diubahOleh: (r['pengubah']?['nama_lengkap'] as String?) ?? 'Sistem',
          waktu: DateTime.parse(r['diubah_pada'] as String).toLocal(),
        ),
    ];
  }
}

// =====================================================================
// KONTAK ORANG TUA
// =====================================================================
class SupabaseKontakRepository implements KontakRepository {
  @override
  Future<Kelas?> getKelasWali() => _kelasWali();

  @override
  Future<List<KontakSiswa>> getKontakOrangTua(String kelasId) async {
    final rows = await supabase
        .from('siswa')
        .select(
          'id, nis, nama_lengkap, '
          'orang_tua_siswa(hubungan, ortu:profiles!orang_tua_id(nama_lengkap, no_whatsapp))',
        )
        .eq('kelas_id', kelasId)
        .eq('status', 'aktif')
        .order('nama_lengkap');
    return [
      for (final r in rows)
        KontakSiswa(
          siswa: _siswaDari(r),
          orangTua: [
            for (final o in r['orang_tua_siswa'] as List)
              if (o['ortu'] != null)
                KontakOrangTua(
                  nama: o['ortu']['nama_lengkap'] as String,
                  hubungan: _hurufBesarAwal(o['hubungan'] as String), // ayah → Ayah
                  noWhatsapp: (o['ortu']['no_whatsapp'] as String?) ?? '-',
                ),
          ],
        ),
    ];
  }
}

// =====================================================================
// RAPOR
// =====================================================================
typedef _TahunAjaran = ({String id, String nama, String semester});

class SupabaseRaporRepository implements RaporRepository {
  Future<_TahunAjaran> _tahunAjaranAktif() async {
    final row = await supabase
        .from('tahun_ajaran')
        .select('id, nama, semester_aktif')
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) throw Exception('Belum ada tahun ajaran aktif. Hubungi pihak sekolah.');
    return (id: row['id'] as String, nama: row['nama'] as String, semester: row['semester_aktif'] as String);
  }

  /// Filter rapor milik satu siswa pada semester aktif.
  PostgrestFilterBuilder<T> _raporSiswa<T>(PostgrestFilterBuilder<T> q, String siswaId, _TahunAjaran ta) =>
      q.eq('siswa_id', siswaId).eq('tahun_ajaran_id', ta.id).eq('semester', ta.semester);

  static StatusRapor _status({
    required DateTime? diambilPada,
    required bool isPublished,
    required bool adaIsi,
  }) {
    if (diambilPada != null) return StatusRapor.diambil;
    if (isPublished) return StatusRapor.terbit;
    return adaIsi ? StatusRapor.draft : StatusRapor.belumDisusun;
  }

  @override
  Future<Kelas?> getKelasWali() => _kelasWali();

  @override
  Future<String> getSemesterAktif() async {
    final ta = await _tahunAjaranAktif();
    return '${_hurufBesarAwal(ta.semester)} ${ta.nama}';
  }

  @override
  Future<List<RaporRingkas>> getDaftarRapor(String kelasId) async {
    final ta = await _tahunAjaranAktif();
    final siswa = await _siswaKelas(kelasId);
    final rows = await supabase
        .from('rapor')
        .select('siswa_id, catatan_wali_kelas, file_url, is_published, diambil_pada, rapor_nilai(nilai_akhir)')
        .eq('kelas_id', kelasId)
        .eq('tahun_ajaran_id', ta.id)
        .eq('semester', ta.semester);
    final perSiswa = {for (final r in rows) r['siswa_id'] as String: r};

    return [
      for (final s in siswa)
        RaporRingkas(
          siswa: s,
          status: switch (perSiswa[s.id]) {
            null => StatusRapor.belumDisusun,
            final r => _status(
              diambilPada: r['diambil_pada'] == null ? null : DateTime.parse(r['diambil_pada'] as String),
              isPublished: r['is_published'] as bool,
              adaIsi: (r['rapor_nilai'] as List).any((n) => n['nilai_akhir'] != null) ||
                  ((r['catatan_wali_kelas'] as String?) ?? '').isNotEmpty ||
                  r['file_url'] != null,
            ),
          },
        ),
    ];
  }

  @override
  Future<RaporDetail> getRapor(String siswaId) async {
    final ta = await _tahunAjaranAktif();
    final siswaRow =
        await supabase.from('siswa').select('id, nis, nama_lengkap, kelas_id').eq('id', siswaId).single();

    // Mapel rapor = mapel yang ada di jadwal kelas ini pada semester aktif.
    final jadwal = await supabase
        .from('jadwal_pelajaran')
        .select('mapel_id, mata_pelajaran(nama)')
        .eq('kelas_id', siswaRow['kelas_id'] as String)
        .eq('semester', ta.semester);
    final namaMapel = <String, String>{
      for (final j in jadwal) j['mapel_id'] as String: j['mata_pelajaran']['nama'] as String,
    };

    // Rata-rata nilai tugas & ujian dari guru mapel, sebagai acuan wali kelas.
    final nilai = await supabase
        .from('nilai')
        .select('mapel_id, nilai')
        .eq('siswa_id', siswaId)
        .eq('tahun_ajaran_id', ta.id)
        .eq('semester', ta.semester);
    final kumpulan = <String, List<double>>{};
    for (final n in nilai) {
      kumpulan.putIfAbsent(n['mapel_id'] as String, () => []).add((n['nilai'] as num).toDouble());
    }
    double? rataRata(String mapelId) {
      final list = kumpulan[mapelId];
      if (list == null || list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final rapor = await _raporSiswa(
      supabase
          .from('rapor')
          .select('catatan_wali_kelas, file_url, is_published, diambil_pada, '
              'rapor_nilai(mapel_id, nilai_akhir, mata_pelajaran(nama))'),
      siswaId,
      ta,
    ).maybeSingle();

    final nilaiAkhir = <String, double?>{};
    for (final rn in (rapor?['rapor_nilai'] as List?) ?? const []) {
      final mapelId = rn['mapel_id'] as String;
      nilaiAkhir[mapelId] = (rn['nilai_akhir'] as num?)?.toDouble();
      namaMapel.putIfAbsent(mapelId, () => rn['mata_pelajaran']['nama'] as String);
    }

    final daftarMapel = namaMapel.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return RaporDetail(
      siswa: _siswaDari(siswaRow),
      semester: '${_hurufBesarAwal(ta.semester)} ${ta.nama}',
      nilai: [
        for (final m in daftarMapel)
          NilaiMapel(
            mapelId: m.key,
            namaMapel: m.value,
            nilaiAkhir: nilaiAkhir[m.key],
            rataRataGuru: rataRata(m.key),
          ),
      ],
      catatanWali: (rapor?['catatan_wali_kelas'] as String?) ?? '',
      filePdf: rapor?['file_url'] as String?,
      isPublished: (rapor?['is_published'] as bool?) ?? false,
      diambilPada: rapor?['diambil_pada'] == null ? null : DateTime.parse(rapor!['diambil_pada'] as String).toLocal(),
    );
  }

  @override
  Future<void> simpanDraft(RaporDetail rapor) async {
    final ta = await _tahunAjaranAktif();
    final siswaRow = await supabase.from('siswa').select('kelas_id').eq('id', rapor.siswa.id).single();

    final row = await supabase
        .from('rapor')
        .upsert({
          'siswa_id': rapor.siswa.id,
          'kelas_id': siswaRow['kelas_id'],
          'tahun_ajaran_id': ta.id,
          'semester': ta.semester,
          'catatan_wali_kelas': rapor.catatanWali.trim().isEmpty ? null : rapor.catatanWali.trim(),
          'file_url': rapor.filePdf,
        }, onConflict: 'siswa_id,tahun_ajaran_id,semester')
        .select('id')
        .single();
    final raporId = row['id'] as String;

    // Nilai disimpan ulang seluruhnya supaya nilai yang dikosongkan ikut terhapus.
    await supabase.from('rapor_nilai').delete().eq('rapor_id', raporId);
    final baris = [
      for (final n in rapor.nilai.where((n) => n.nilaiAkhir != null))
        {
          'rapor_id': raporId,
          'mapel_id': n.mapelId,
          'nilai_akhir': n.nilaiAkhir,
          'predikat': n.predikat,
        },
    ];
    if (baris.isNotEmpty) await supabase.from('rapor_nilai').insert(baris);
  }

  @override
  Future<String> uploadPdf(String siswaId, String namaFile, Uint8List isiFile) async {
    final path = '$_uid/rapor_${siswaId}_$namaFile';
    await supabase.storage.from('rapor').uploadBinary(
          path,
          isiFile,
          fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
        );
    return path;
  }

  @override
  Future<void> terbitkan(String siswaId) async {
    final rapor = await getRapor(siswaId);
    if (!rapor.lengkap) throw Exception('Nilai belum lengkap atau PDF belum diunggah.');
    final ta = await _tahunAjaranAktif();
    await _raporSiswa(
      supabase.from('rapor').update({
        'is_published': true,
        'diterbitkan_pada': DateTime.now().toUtc().toIso8601String(),
        'diterbitkan_oleh': _uid,
      }),
      siswaId,
      ta,
    );
  }

  @override
  Future<void> konfirmasiPengambilan(String siswaId) async {
    final ta = await _tahunAjaranAktif();
    final hasil = await _raporSiswa(
      supabase.from('rapor').update({
        'diambil_pada': DateTime.now().toUtc().toIso8601String(),
        'dikonfirmasi_oleh': _uid,
      }),
      siswaId,
      ta,
    ).eq('is_published', true).select('id');
    if (hasil.isEmpty) throw Exception('Rapor belum diterbitkan.');
  }
}
