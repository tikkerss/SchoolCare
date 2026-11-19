import 'dummy_data.dart';
import 'models.dart';

class KontakOrangTua {
  const KontakOrangTua({
    required this.nama,
    required this.hubungan,
    required this.noWhatsapp,
  });

  final String nama;
  final String hubungan; // Ayah / Ibu / Wali
  final String noWhatsapp; // dari profiles.no_whatsapp

  /// Sapaan untuk pesan WhatsApp.
  String get sapaan => switch (hubungan) {
    'Ayah' => 'Bapak',
    'Ibu' => 'Ibu',
    _ => 'Bapak/Ibu',
  };
}

class KontakSiswa {
  const KontakSiswa({required this.siswa, required this.orangTua});
  final Siswa siswa;
  final List<KontakOrangTua> orangTua;
}

abstract class KontakRepository {
  Future<Kelas?> getKelasWali();
  Future<List<KontakSiswa>> getKontakOrangTua(String kelasId);
}

class DummyKontakRepository implements KontakRepository {
  static const _ortu = <String, List<KontakOrangTua>>{
    's1': [
      KontakOrangTua(
        nama: 'Fauzan Hidayat',
        hubungan: 'Ayah',
        noWhatsapp: '081234567801',
      ),
      KontakOrangTua(
        nama: 'Siti Aminah',
        hubungan: 'Ibu',
        noWhatsapp: '081234567802',
      ),
    ],
    's2': [
      KontakOrangTua(
        nama: 'Rina Marlina',
        hubungan: 'Ibu',
        noWhatsapp: '085712345603',
      ),
    ],
    's3': [
      KontakOrangTua(
        nama: 'Hendra Wijaya',
        hubungan: 'Ayah',
        noWhatsapp: '+62 812-3456-7804',
      ),
    ],
    's4': [
      KontakOrangTua(
        nama: 'Agus Pratama',
        hubungan: 'Ayah',
        noWhatsapp: '081398765405',
      ),
      KontakOrangTua(
        nama: 'Dewi Sartika',
        hubungan: 'Ibu',
        noWhatsapp: '081398765406',
      ),
    ],
    's5': [
      KontakOrangTua(
        nama: 'Sri Wahyuni',
        hubungan: 'Ibu',
        noWhatsapp: '087812345607',
      ),
    ],
    's6': [
      KontakOrangTua(
        nama: 'Bambang Susilo',
        hubungan: 'Wali',
        noWhatsapp: '081287654308',
      ),
    ],
    's7': [
      KontakOrangTua(
        nama: 'Ramlan Effendi',
        hubungan: 'Ayah',
        noWhatsapp: '082112345609',
      ),
    ],
    // s8 sengaja dikosongkan: contoh siswa yang belum dihubungkan ke akun orang tua.
  };

  @override
  Future<Kelas?> getKelasWali() async {
    await jedaDummy(300);
    return dummyKelas;
  }

  @override
  Future<List<KontakSiswa>> getKontakOrangTua(String kelasId) async {
    await jedaDummy(600);
    // Versi Supabase (kira-kira):
    // db.from('siswa')
    //   .select('id, nis, nama_lengkap, orang_tua_siswa(profiles(nama_lengkap, no_whatsapp))')
    //   .eq('kelas_id', kelasId)
    //   .order('nama_lengkap');
    // Kolom "hubungan" (ayah/ibu/wali) tanyakan ke Backend apakah ada di orang_tua_siswa.
    return [
      for (final s in dummySiswa)
        KontakSiswa(siswa: s, orangTua: _ortu[s.id] ?? const []),
    ];
  }
}
