import 'package:material_ui/material_ui.dart';
import '../data/guru_dummy.dart';
import '../models/jadwal.dart';
import '../widgets/status_kelas_chip.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Mengajar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: jadwalHariIni.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _JadwalCard(jadwal: jadwalHariIni[i]),
      ),
    );
  }
}

class _JadwalCard extends StatelessWidget {
  final Jadwal jadwal;
  const _JadwalCard({required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Absensi ${jadwal.kelas} (segera dibuat)')),
          );
        },
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
                    Text('${jadwal.kelas} • ${jadwal.ruang}',
                        style: theme.textTheme.bodyMedium),
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