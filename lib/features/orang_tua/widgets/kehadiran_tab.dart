import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/pages/form_izin_page.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

/// Tab Kehadiran: rekap & daftar kehadiran per bulan, ter-update otomatis.
/// Ketuk satu hari untuk melihat riwayat perubahan statusnya.
class KehadiranTab extends StatefulWidget {
  const KehadiranTab({super.key, required this.anak});

  final Anak anak;

  @override
  State<KehadiranTab> createState() => _KehadiranTabState();
}

class _KehadiranTabState extends State<KehadiranTab> {
  static const _urutanStatus = ['hadir', 'terlambat', 'izin', 'sakit', 'alpa'];

  final _repo = OrtuRepository();
  DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<AbsensiHarian>> _future = _muat();
  late final VoidCallback _berhentiPantau;

  @override
  void initState() {
    super.initState();
    _berhentiPantau = _repo.pantauAbsensi(widget.anak.siswaId, () {
      if (mounted) _muatUlang();
    });
  }

  @override
  void dispose() {
    _berhentiPantau();
    super.dispose();
  }

  Future<List<AbsensiHarian>> _muat() => _repo.getAbsensiBulan(widget.anak.siswaId, _bulan);

  void _muatUlang() => setState(() => _future = _muat());

  void _gantiBulan(int geser) {
    _bulan = DateTime(_bulan.year, _bulan.month + geser);
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final bulanIni = DateTime(DateTime.now().year, DateTime.now().month);

    return Column(children: [
      // ---- pilih bulan
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _gantiBulan(-1)),
          Expanded(
            child: Text(
              OrtuFmt.bulan(_bulan),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _bulan == bulanIni ? null : () => _gantiBulan(1),
          ),
        ]),
      ),

      // ---- rekap + daftar
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async {
            _muatUlang();
            await _future;
          },
          child: TungguData<List<AbsensiHarian>>(
            future: _future,
            onCobaLagi: _muatUlang,
            builder: (context, list) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _rekap(list),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: KosongView(pesan: 'Belum ada data kehadiran di bulan ini.'),
                  ),
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(OrtuFmt.hari(a.tanggal)),
                        subtitle: a.keterangan == null ? null : Text(a.keterangan!),
                        trailing: StatusChip(a.status),
                        onTap: () => _riwayat(a),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      // ---- tombol izin
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.edit_note),
            label: const Text('Ajukan izin / sakit'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => FormIzinPage(anak: widget.anak)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _rekap(List<AbsensiHarian> list) {
    final hitung = {for (final s in _urutanStatus) s: list.where((a) => a.status == s).length};
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final e in hitung.entries)
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${e.value}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                StatusChip(e.key),
              ]),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet riwayat perubahan status (siapa mengubah & jam berapa).
  void _riwayat(AbsensiHarian a) {
    final future = _repo.getRiwayatStatus(a.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => FutureBuilder<List<RiwayatStatus>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(height: 160, child: MemuatView());
          }
          if (snap.hasError) return const SizedBox(height: 160, child: GagalView());
          final list = snap.data!;
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text('Riwayat status', style: Theme.of(context).textTheme.titleLarge),
              Text(OrtuFmt.hari(a.tanggal), style: const TextStyle(color: OrtuWarna.textSecondary)),
              const SizedBox(height: 12),
              if (list.isEmpty) const Text('Belum ada riwayat.'),
              for (final r in list)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(OrtuFmt.jamMenit(r.waktu), style: const TextStyle(fontWeight: FontWeight.w600)),
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      if (r.statusLama != null) ...[
                        StatusChip(r.statusLama!),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                      StatusChip(r.statusBaru),
                    ],
                  ),
                  subtitle: Text([
                    if (r.keterangan != null) r.keterangan!,
                    if (r.oleh != null) 'oleh ${r.oleh}',
                  ].join(' · ')),
                ),
            ],
          );
        },
      ),
    );
  }
}
