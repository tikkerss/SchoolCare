import 'package:material_ui/material_ui.dart';
import '../data/guru_repository.dart';
import '../models/jadwal.dart';
import '../widgets/status_kelas_chip.dart';
import 'absensi_mengajar_page.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _repo = GuruRepository();
  List<Jadwal> _jadwal = [];
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
      final data = await _repo.getJadwalHariIni();
      if (mounted) setState(() => _jadwal = data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal memuat jadwal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bukaAbsensi(int i) async {
    if (_jadwal[i].status != StatusKelas.belumAbsen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam pelajaran ini sudah diabsen.')),
      );
      return;
    }

    final status = await Navigator.push<StatusKelas>(
      context,
      MaterialPageRoute(builder: (_) => AbsensiMengajarPage(jadwal: _jadwal[i])),
    );
    if (status != null) {
      setState(() => _jadwal[i] = _jadwal[i].copyWith(status: status));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Mengajar')),
      body: _isi(),
    );
  }

  Widget _isi() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }
    if (_jadwal.isEmpty) {
      return const Center(child: Text('Tidak ada jadwal mengajar hari ini.'));
    }
    return RefreshIndicator(
      onRefresh: _muat,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jadwal.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _JadwalCard(
          jadwal: _jadwal[i],
          onTap: () => _bukaAbsensi(i),
        ),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  final VoidCallback onTap;
  const _JadwalCard({required this.jadwal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text(jadwal.jamMulai, style: theme.textTheme.titleMedium),
                  Text(jadwal.jamSelesai, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwal.mapel, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${jadwal.kelas} • ${jadwal.ruang}'),
                  ],
                ),
              ),
              StatusKelasChip(status: jadwal.status),
            ],
          ),
        ),
      ),
    );
  }
}