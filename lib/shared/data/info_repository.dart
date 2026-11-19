import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/shared/data/info_models.dart';

/// Query BACA untuk halaman info bersama (semua peran): pengumuman, agenda, jadwal kelas.
/// Data ini diisi Pihak Sekolah lewat halaman admin.
class InfoRepository {
  Future<List<Pengumuman>> getPengumuman({int limit = 50}) async {
    final rows = await supabase
        .from('pengumuman')
        .select('id, judul, isi, kategori, lampiran_url, dipublikasikan_pada, is_published')
        .eq('is_published', true)
        .order('dipublikasikan_pada', ascending: false)
        .limit(limit);
    return rows.map(Pengumuman.fromJson).toList();
  }

  /// Agenda yang beririsan dengan rentang [awal, akhir].
  /// [kelasId] diisi supaya agenda khusus kelas tersebut ikut tampil.
  Future<List<Agenda>> getAgenda(DateTime awal, DateTime akhir, {String? kelasId}) async {
    final rows = await supabase
        .from('agenda_sekolah')
        .select('*, agenda_kelas(kelas_id)')
        .lte('tanggal_mulai', Fmt.db(akhir))
        .gte('tanggal_selesai', Fmt.db(awal))
        .order('tanggal_mulai');
    final list = rows.map(Agenda.fromJson).toList();
    if (kelasId == null) return list;
    return list.where((a) => a.untukSemuaKelas || a.kelasIds.contains(kelasId)).toList();
  }

  /// Jadwal pelajaran satu kelas pada semester aktif.
  Future<List<JadwalItem>> getJadwalKelas(String kelasId) async {
    final ta = await supabase.from('tahun_ajaran').select('semester_aktif').eq('is_active', true).maybeSingle();
    if (ta == null) return [];
    final rows = await supabase
        .from('jadwal_pelajaran')
        .select('id, hari, jam_ke, jam_mulai, jam_selesai, ruang, '
            'mata_pelajaran(nama), guru:profiles!guru_id(nama_lengkap)')
        .eq('kelas_id', kelasId)
        .eq('semester', ta['semester_aktif'])
        .order('jam_ke');
    return rows.map(JadwalItem.fromJson).toList();
  }
}
