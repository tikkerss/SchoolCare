import 'package:material_ui/material_ui.dart';
import '../data/guru_dummy.dart';
import '../models/jadwal.dart';
import '../widgets/status_kelas_chip.dart';
import 'absensi_mengajar_page.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  final _jadwal = List<Jadwal>.of(jadwalHariIni);

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
      body: ListView.separated(
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