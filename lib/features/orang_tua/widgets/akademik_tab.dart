import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';

/// Tab Akademik: Tugas · Ujian · Nilai · Rapor.
class AkademikTab extends StatelessWidget {
  const AkademikTab({super.key, required this.anak});

  final Anak anak;

  @override
  Widget build(BuildContext context) {
    final kelasId = anak.kelasId;
    if (kelasId == null) {
      return const KosongView(pesan: 'Anak belum terdaftar di kelas mana pun.');
    }
    final repo = OrtuRepository();

    return DefaultTabController(
      length: 4,
      child: Column(children: [
        const TabBar(tabs: [Tab(text: 'Tugas'), Tab(text: 'Ujian'), Tab(text: 'Nilai'), Tab(text: 'Rapor')]),
        Expanded(
          child: TabBarView(children: [
            _SubTab<Tugas>(muat: () => repo.getTugas(kelasId), pesanKosong: 'Belum ada tugas.', builder: _daftarTugas),
            _SubTab<Ujian>(
              muat: () => repo.getUjian(kelasId),
              pesanKosong: 'Belum ada jadwal ujian.',
              builder: _daftarUjian,
            ),
            _SubTab<Nilai>(muat: () => repo.getNilai(anak.siswaId), pesanKosong: 'Belum ada nilai.', builder: _daftarNilai),
            _SubTab<Rapor>(
              muat: () => repo.getRapor(anak.siswaId),
              pesanKosong: 'Rapor belum tersedia.\n\nRapor digital bisa dibuka setelah rapor diambil '
                  'di sekolah dan dikonfirmasi oleh wali kelas.',
              builder: _daftarRapor,
            ),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------------ Tugas
  static Widget _daftarTugas(BuildContext context, List<Tugas> list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(t.judul),
                  subtitle: Text('${t.mapel}\nTenggat ${OrtuFmt.waktu(t.tenggat)}'),
                  isThreeLine: true,
                  trailing: t.lewat
                      ? const Text('Lewat', style: TextStyle(color: OrtuWarna.danger, fontSize: 12))
                      : null,
                  onTap: () => _detailTugas(context, t),
                ),
              ),
            ),
        ],
      );

  static void _detailTugas(BuildContext context, Tugas t) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(t.judul, style: Theme.of(context).textTheme.titleLarge),
            Text(t.mapel, style: const TextStyle(color: OrtuWarna.textSecondary)),
            const SizedBox(height: 12),
            Text('Tenggat: ${OrtuFmt.waktu(t.tenggat)}'),
            if (t.deskripsi != null) ...[const SizedBox(height: 12), Text(t.deskripsi!)],
            if (t.lampiranUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Buka lampiran'),
                onPressed: () => OrtuLink.buka(t.lampiranUrl!),
              ),
            ],
          ],
        ),
      );

  // ------------------------------------------------------------------ Ujian
  static Widget _daftarUjian(BuildContext context, List<Ujian> list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final u in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.edit_document),
                  title: Text('${u.mapel} – ${u.judul}'),
                  subtitle: Text([
                    [OrtuFmt.hari(u.tanggal), if (u.jamMulai != null) OrtuFmt.jam(u.jamMulai!)].join(', '),
                    if (u.ruang != null) u.ruang!,
                    if (u.materi != null) 'Materi: ${u.materi}',
                  ].join('\n')),
                ),
              ),
            ),
        ],
      );

  // ------------------------------------------------------------------ Nilai
  static Widget _daftarNilai(BuildContext context, List<Nilai> list) {
    final perMapel = <String, List<Nilai>>{};
    for (final n in list) {
      perMapel.putIfAbsent(n.mapel, () => []).add(n);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final e in perMapel.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                title: Text(e.key),
                subtitle: Text(
                  'Rata-rata ${(e.value.map((n) => n.nilai).reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1)}',
                ),
                children: [
                  for (final n in e.value)
                    ListTile(
                      dense: true,
                      title: Text(n.judul),
                      subtitle: Text(n.jenis.replaceAll('_', ' ')),
                      trailing: Text(
                        n.nilai.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ Rapor
  static Widget _daftarRapor(BuildContext context, List<Rapor> list) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  shape: const Border(),
                  leading: const Icon(Icons.description_outlined),
                  title: Text('Semester ${r.semester[0].toUpperCase()}${r.semester.substring(1)}'),
                  subtitle: Text('Tahun ajaran ${r.tahunAjaran}'),
                  children: [
                    for (final n in r.nilai)
                      ListTile(
                        dense: true,
                        title: Text(n.mapel),
                        subtitle: n.deskripsi == null ? null : Text(n.deskripsi!),
                        trailing: Text(
                          '${n.nilaiAkhir?.toStringAsFixed(0) ?? '-'} ${n.predikat ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (r.catatan != null) ListTile(title: const Text('Catatan wali kelas'), subtitle: Text(r.catatan!)),
                    if (r.fileUrl != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Buka rapor (PDF)'),
                          onPressed: () => OrtuLink.buka(r.fileUrl!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
}

/// Satu sub-tab berisi daftar data. Data tetap tersimpan saat pindah sub-tab,
/// dan bisa ditarik ke bawah untuk memuat ulang.
class _SubTab<T> extends StatefulWidget {
  const _SubTab({required this.muat, required this.builder, required this.pesanKosong});

  final Future<List<T>> Function() muat;
  final Widget Function(BuildContext context, List<T> data) builder;
  final String pesanKosong;

  @override
  State<_SubTab<T>> createState() => _SubTabState<T>();
}

class _SubTabState<T> extends State<_SubTab<T>> with AutomaticKeepAliveClientMixin {
  late Future<List<T>> _future = widget.muat();

  @override
  bool get wantKeepAlive => true;

  void _muatUlang() => setState(() => _future = widget.muat());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        _muatUlang();
        await _future;
      },
      child: TungguData<List<T>>(
        future: _future,
        onCobaLagi: _muatUlang,
        kosong: (d) => d.isEmpty,
        pesanKosong: widget.pesanKosong,
        builder: widget.builder,
      ),
    );
  }
}
