import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/sekolah/data/sekolah_models.dart';
import 'package:schoolcare/shared/data/info_models.dart';

/// Semua query untuk halaman admin Pihak Sekolah.
/// Hak akses dijaga RLS di Supabase: hanya akun berperan 'manajemen' yang boleh menulis.
class SekolahRepository {
  // ================================================================== TAHUN AJARAN
  Future<List<TahunAjaran>> getTahunAjaran() async {
    final rows = await supabase.from('tahun_ajaran').select().order('tanggal_mulai', ascending: false);
    return rows.map(TahunAjaran.fromJson).toList();
  }

  Future<TahunAjaran?> getTahunAjaranAktif() async {
    final row = await supabase.from('tahun_ajaran').select().eq('is_active', true).maybeSingle();
    return row == null ? null : TahunAjaran.fromJson(row);
  }

  Future<void> simpanTahunAjaran({
    String? id,
    required String nama,
    required String semesterAktif,
    required DateTime mulai,
    required DateTime selesai,
  }) async {
    final data = {
      'nama': nama,
      'semester_aktif': semesterAktif,
      'tanggal_mulai': Fmt.db(mulai),
      'tanggal_selesai': Fmt.db(selesai),
    };
    if (id == null) {
      await supabase.from('tahun_ajaran').insert(data);
    } else {
      await supabase.from('tahun_ajaran').update(data).eq('id', id);
    }
  }

  /// Hanya boleh ada satu tahun ajaran aktif: matikan yang lama dulu, baru aktifkan yang baru.
  Future<void> aktifkanTahunAjaran(String id) async {
    await supabase.from('tahun_ajaran').update({'is_active': false}).eq('is_active', true);
    await supabase.from('tahun_ajaran').update({'is_active': true}).eq('id', id);
  }

  // ================================================================== AKUN
  Future<List<Profile>> getAkun({UserRole? role}) async {
    var q = supabase.from('profiles').select();
    if (role != null) q = q.eq('role', role.dbValue);
    final rows = await q.order('nama_lengkap');
    return rows.map(Profile.fromJson).toList();
  }

  /// Membuat akun baru lewat Edge Function `create-user`
  /// (membuat user di Supabase Auth butuh service role key, jadi tidak boleh dari aplikasi langsung).
  Future<void> buatAkun({
    required String email,
    required String password,
    required String nama,
    required UserRole role,
    String? noWhatsapp,
    String? nip,
  }) async {
    await supabase.functions.invoke('create-user', body: {
      'email': email.trim().toLowerCase(),
      'password': password,
      'nama_lengkap': nama.trim(),
      'role': role.dbValue,
      'no_whatsapp': _kosongJadiNull(noWhatsapp),
      'nip': _kosongJadiNull(nip),
    });
  }

  Future<void> ubahAkun(
    String id, {
    required String nama,
    required UserRole role,
    String? noWhatsapp,
    String? nip,
  }) async {
    await supabase.from('profiles').update({
      'nama_lengkap': nama.trim(),
      'role': role.dbValue,
      'no_whatsapp': _kosongJadiNull(noWhatsapp),
      'nip': _kosongJadiNull(nip),
    }).eq('id', id);
  }

  Future<void> setAkunAktif(String id, bool aktif) async {
    await supabase.from('profiles').update({'is_active': aktif}).eq('id', id);
  }

  // ================================================================== KELAS
  Future<List<Kelas>> getKelas({String? tahunAjaranId}) async {
    var q = supabase.from('kelas').select('*, wali:profiles!wali_kelas_id(nama_lengkap), tahun_ajaran(nama)');
    if (tahunAjaranId != null) q = q.eq('tahun_ajaran_id', tahunAjaranId);
    final rows = await q.order('tingkat').order('nama_kelas');
    return rows.map(Kelas.fromJson).toList();
  }

  Future<void> simpanKelas({
    String? id,
    required String tahunAjaranId,
    required String namaKelas,
    required int tingkat,
    String? ruang,
    String? waliKelasId,
  }) async {
    final data = {
      'tahun_ajaran_id': tahunAjaranId,
      'nama_kelas': namaKelas.trim(),
      'tingkat': tingkat,
      'ruang': _kosongJadiNull(ruang),
      'wali_kelas_id': waliKelasId,
    };
    if (id == null) {
      await supabase.from('kelas').insert(data);
    } else {
      await supabase.from('kelas').update(data).eq('id', id);
    }
  }

  Future<void> hapusKelas(String id) async {
    await supabase.from('kelas').delete().eq('id', id);
  }

  // ================================================================== SISWA
  Future<List<Siswa>> getSiswa({String? kelasId, String? cari}) async {
    var q = supabase.from('siswa').select('*, kelas(nama_kelas)');
    if (kelasId != null) q = q.eq('kelas_id', kelasId);
    final kata = (cari ?? '').replaceAll(RegExp(r'[,()%]'), '').trim();
    if (kata.isNotEmpty) q = q.or('nama_lengkap.ilike.%$kata%,nis.ilike.%$kata%');
    final rows = await q.order('nama_lengkap');
    return rows.map(Siswa.fromJson).toList();
  }

  Future<void> simpanSiswa({
    String? id,
    required String nis,
    String? nisn,
    required String nama,
    required String jenisKelamin,
    DateTime? tanggalLahir,
    String? alamat,
    String? kelasId,
    required String status,
  }) async {
    final data = {
      'nis': nis.trim(),
      'nisn': _kosongJadiNull(nisn),
      'nama_lengkap': nama.trim(),
      'jenis_kelamin': jenisKelamin,
      'tanggal_lahir': tanggalLahir == null ? null : Fmt.db(tanggalLahir),
      'alamat': _kosongJadiNull(alamat),
      'kelas_id': kelasId,
      'status': status,
    };
    if (id == null) {
      await supabase.from('siswa').insert(data);
    } else {
      await supabase.from('siswa').update(data).eq('id', id);
    }
  }

  Future<void> hapusSiswa(String id) async {
    await supabase.from('siswa').delete().eq('id', id);
  }

  Future<List<OrtuTerhubung>> getOrtuSiswa(String siswaId) async {
    final rows = await supabase
        .from('orang_tua_siswa')
        .select('hubungan, ortu:profiles!orang_tua_id(id, nama_lengkap, email)')
        .eq('siswa_id', siswaId);
    return rows.map(OrtuTerhubung.fromJson).toList();
  }

  Future<void> hubungkanOrtu({required String siswaId, required String ortuId, required String hubungan}) async {
    await supabase.from('orang_tua_siswa').insert({
      'siswa_id': siswaId,
      'orang_tua_id': ortuId,
      'hubungan': hubungan,
    });
  }

  Future<void> lepasOrtu({required String siswaId, required String ortuId}) async {
    await supabase.from('orang_tua_siswa').delete().eq('siswa_id', siswaId).eq('orang_tua_id', ortuId);
  }

  // ================================================================== MATA PELAJARAN
  Future<List<MataPelajaran>> getMapel() async {
    final rows = await supabase.from('mata_pelajaran').select().order('nama');
    return rows.map(MataPelajaran.fromJson).toList();
  }

  Future<void> simpanMapel({String? id, required String kode, required String nama}) async {
    final data = {'kode': kode.trim().toUpperCase(), 'nama': nama.trim()};
    if (id == null) {
      await supabase.from('mata_pelajaran').insert(data);
    } else {
      await supabase.from('mata_pelajaran').update(data).eq('id', id);
    }
  }

  Future<void> hapusMapel(String id) async {
    await supabase.from('mata_pelajaran').delete().eq('id', id);
  }

  // ================================================================== JADWAL PELAJARAN
  Future<List<JadwalAdmin>> getJadwal({required String kelasId, required String semester}) async {
    final rows = await supabase
        .from('jadwal_pelajaran')
        .select('*, mata_pelajaran(nama), guru:profiles!guru_id(nama_lengkap)')
        .eq('kelas_id', kelasId)
        .eq('semester', semester)
        .order('hari')
        .order('jam_ke');
    return rows.map(JadwalAdmin.fromJson).toList();
  }

  Future<void> simpanJadwal({
    String? id,
    required String kelasId,
    required String mapelId,
    required String guruId,
    required String semester,
    required String hari,
    required int jamKe,
    required String jamMulai, // 'HH:mm'
    required String jamSelesai,
    String? ruang,
  }) async {
    final data = {
      'kelas_id': kelasId,
      'mapel_id': mapelId,
      'guru_id': guruId,
      'semester': semester,
      'hari': hari,
      'jam_ke': jamKe,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'ruang': _kosongJadiNull(ruang),
    };
    if (id == null) {
      await supabase.from('jadwal_pelajaran').insert(data);
    } else {
      await supabase.from('jadwal_pelajaran').update(data).eq('id', id);
    }
  }

  Future<void> hapusJadwal(String id) async {
    await supabase.from('jadwal_pelajaran').delete().eq('id', id);
  }

  // ================================================================== AGENDA / KALENDER
  Future<List<Agenda>> getAgendaAdmin() async {
    final rows = await supabase
        .from('agenda_sekolah')
        .select('*, agenda_kelas(kelas_id)')
        .order('tanggal_mulai', ascending: false);
    return rows.map(Agenda.fromJson).toList();
  }

  Future<void> simpanAgenda({
    String? id,
    required Map<String, dynamic> data,
    required List<String> kelasIds, // dipakai kalau untuk_semua_kelas = false
  }) async {
    final String agendaId;
    if (id == null) {
      final row = await supabase.from('agenda_sekolah').insert(data).select('id').single();
      agendaId = row['id'] as String;
    } else {
      await supabase.from('agenda_sekolah').update(data).eq('id', id);
      agendaId = id;
    }
    // atur ulang daftar kelas khusus
    await supabase.from('agenda_kelas').delete().eq('agenda_id', agendaId);
    if (data['untuk_semua_kelas'] == false && kelasIds.isNotEmpty) {
      await supabase
          .from('agenda_kelas')
          .insert([for (final k in kelasIds) {'agenda_id': agendaId, 'kelas_id': k}]);
    }
  }

  Future<void> hapusAgenda(String id) async {
    await supabase.from('agenda_sekolah').delete().eq('id', id);
  }

  // ================================================================== PENGUMUMAN
  Future<List<Pengumuman>> getPengumumanAdmin() async {
    final rows = await supabase
        .from('pengumuman')
        .select('id, judul, isi, kategori, lampiran_url, dipublikasikan_pada, is_published')
        .order('dipublikasikan_pada', ascending: false);
    return rows.map(Pengumuman.fromJson).toList();
  }

  Future<void> simpanPengumuman({
    String? id,
    required String judul,
    required String isi,
    required String kategori,
    required bool terbitkan,
    String? lampiranUrl,
  }) async {
    final data = {
      'judul': judul.trim(),
      'isi': isi.trim(),
      'kategori': kategori,
      'is_published': terbitkan,
      'lampiran_url': _kosongJadiNull(lampiranUrl),
    };
    if (id == null) {
      await supabase.from('pengumuman').insert(data);
    } else {
      await supabase.from('pengumuman').update(data).eq('id', id);
    }
  }

  Future<void> hapusPengumuman(String id) async {
    await supabase.from('pengumuman').delete().eq('id', id);
  }

  // ================================================================== LAPORAN
  Future<List<LaporanGuru>> getLaporanGuru(DateTime tanggal) async {
    final rows = await supabase
        .from('v_laporan_absensi_guru')
        .select()
        .eq('tanggal', Fmt.db(tanggal))
        .order('jam_mulai');
    return rows.map(LaporanGuru.fromJson).toList();
  }

  /// URL sementara (1 jam) untuk menampilkan foto bukti dari bucket privat.
  Future<String> urlFotoBukti(String path) =>
      supabase.storage.from('bukti-absensi-guru').createSignedUrl(path, 3600);

  Future<List<RekapSiswa>> getRekap({required String kelasId, required DateTime bulan}) async {
    final rows = await supabase
        .from('v_rekap_kehadiran_siswa')
        .select()
        .eq('kelas_id', kelasId)
        .eq('bulan', Fmt.db(DateTime(bulan.year, bulan.month, 1)))
        .order('nama_lengkap');
    return rows.map(RekapSiswa.fromJson).toList();
  }

  // ------------------------------------------------------------------
  static String? _kosongJadiNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
