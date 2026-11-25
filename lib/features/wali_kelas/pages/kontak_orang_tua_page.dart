import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';

import '../data/kontak_repository.dart';
import '../data/models.dart';
import '../utils/whatsapp.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';

class KontakOrangTuaPage extends StatefulWidget {
  const KontakOrangTuaPage({super.key, required this.repository});

  final KontakRepository repository;

  @override
  State<KontakOrangTuaPage> createState() => _KontakOrangTuaPageState();
}

class _KontakOrangTuaPageState extends State<KontakOrangTuaPage> {
  Kelas? _kelas;
  List<KontakSiswa> _data = [];
  String _cari = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final kelas = await widget.repository.getKelasWali();
      if (kelas == null) {
        setState(() {
          _error = 'Akun ini tidak tercatat sebagai wali kelas.';
          _loading = false;
        });
        return;
      }
      final data = await widget.repository.getKontakOrangTua(kelas.id);
      setState(() {
        _kelas = kelas;
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat kontak: $e';
        _loading = false;
      });
    }
  }

  List<KontakSiswa> get _tersaring {
    final q = _cari.trim().toLowerCase();
    if (q.isEmpty) return _data;
    return _data.where((k) {
      return k.siswa.nama.toLowerCase().contains(q) ||
          k.orangTua.any((o) => o.nama.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _chat(KontakSiswa k, KontakOrangTua o) async {
    final pesan =
        'Selamat ${salamWaktu()}, ${o.sapaan} ${o.nama}. '
        'Saya wali kelas ${_kelas!.namaKelas}. '
        'Saya ingin menyampaikan informasi terkait ananda ${k.siswa.nama}.';
    final ok = await bukaWhatsApp(o.noWhatsapp, pesan: pesan);
    if (!ok && mounted) _pesanGagal('WhatsApp tidak bisa dibuka.');
  }

  Future<void> _telepon(KontakOrangTua o) async {
    final ok = await bukaTelepon(o.noWhatsapp);
    if (!ok && mounted) _pesanGagal('Aplikasi telepon tidak bisa dibuka.');
  }

  void _pesanGagal(String teks) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kontak Orang Tua')),
      body: LembarPutih(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    final list = _tersaring;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Cari nama siswa atau orang tua',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _cari = v),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Tidak ada yang cocok.'))
              : RefreshIndicator(
                  onRefresh: _muat,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _kartuSiswa(list[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _kartuSiswa(KontakSiswa k) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              k.siswa.nama,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('NIS ${k.siswa.nis}'),
          ),
          if (k.orangTua.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Belum ada akun orang tua yang terhubung. Hubungi Pihak Sekolah.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            )
          else
            for (final o in k.orangTua)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline),
                title: Text('${o.nama} (${o.hubungan})'),
                subtitle: Text(o.noWhatsapp),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Telepon',
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () => _telepon(o),
                    ),
                    IconButton(
                      tooltip: 'Chat WhatsApp',
                      icon: const Icon(Icons.chat, color: AppColors.pink),
                      onPressed: () => _chat(k, o),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
