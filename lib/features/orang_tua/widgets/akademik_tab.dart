import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_models.dart';
import 'package:schoolcare/features/orang_tua/data/ortu_repository.dart';
import 'package:schoolcare/features/orang_tua/widgets/ortu_ui.dart';
import 'package:schoolcare/shared/widgets/ticket_card.dart';

/// Tab Akademik: ringkasan + Tugas · Ujian · Nilai · Rapor.
class AkademikTab extends StatefulWidget {
  const AkademikTab({super.key, required this.anak});

  final Anak anak;

  @override
  State<AkademikTab> createState() => _AkademikTabState();
}

class _AkademikTabState extends State<AkademikTab> {
  final _repo = OrtuRepository();

  // Data awal dipakai bersama oleh kotak statistik dan sub-tab (tidak dimuat dua kali).
  late final String? _kelasId = widget.anak.kelasId;
  late final Future<List<Tugas>>? _tugas = _kelasId == null ? null : _repo.getTugas(widget.anak.kelasId!);
  late final Future<List<Ujian>>? _ujian = _kelasId == null ? null : _repo.getUjian(widget.anak.kelasId!);
  late final Future<List<Nilai>> _nilai = _repo.getNilai(widget.anak.siswaId);
  late final Future<(List<Nilai>, List<Tugas>, List<Ujian>)> _ringkasan = (_nilai, _tugas!, _ujian!).wait;

  @override
  Widget build(BuildContext context) {
    final kelasId = _kelasId;
    if (kelasId == null) {
      return const KosongView(pesan: 'Anak belum terdaftar di kelas mana pun.');
    }
    final anak = widget.anak;

    return DefaultTabController(
      length: 4,
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12), child: _statistik()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.softPink, width: 1.5),
            ),
            // TabBar di dalam kartu putih: aktif = kotak pink, teks putih (tema default
            // disiapkan untuk TabBar di AppBar pink).
            child: TabBar(
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.ink,
              indicatorSize: TabBarIndicatorSize.tab,
              overlayColor: WidgetStatePropertyAll(AppColors.pink.withValues(alpha: 0.08)),
              indicator: BoxDecoration(color: AppColors.pink, borderRadius: BorderRadius.circular(10)),
              tabs: const [
                Tab(text: 'Tugas', height: 36),
                Tab(text: 'Ujian', height: 36),
                Tab(text: 'Nilai', height: 36),
                Tab(text: 'Rapor', height: 36),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _SubTab<Tugas>(
              awal: _tugas,
              muat: () => _repo.getTugas(kelasId),
              pesanKosong: 'Belum ada tugas.',
              builder: _daftarTugas,
            ),
            _SubTab<Ujian>(
              awal: _ujian,
              muat: () => _repo.getUjian(kelasId),
              pesanKosong: 'Belum ada jadwal ujian.',
              builder: _daftarUjian,
            ),
            _SubTab<Nilai>(
              awal: _nilai,
              muat: () => _repo.getNilai(anak.siswaId),
              pesanKosong: 'Belum ada nilai.',
              builder: _daftarNilai,
            ),
            _SubTab<Rapor>(
              muat: () => _repo.getRapor(anak.siswaId),
              pesanKosong: 'Rapor belum tersedia.\n\nRapor digital bisa dibuka setelah rapor diambil '
                  'di sekolah dan dikonfirmasi oleh wali kelas.',
              builder: _daftarRapor,
            ),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------ statistik
  Widget _statistik() => FutureBuilder<(List<Nilai>, List<Tugas>, List<Ujian>)>(
        future: _ringkasan,
        builder: (context, snap) {
          String rata = '–', tugas = '–', ujian = '–';
          final d = snap.data;
          if (d != null) {
            final (n, t, u) = d;
            if (n.isNotEmpty) rata = (n.map((x) => x.nilai).reduce((a, b) => a + b) / n.length).toStringAsFixed(1);
            tugas = '${t.where((x) => !x.lewat).length}';
            final hariIni = DateUtils.dateOnly(DateTime.now());
            ujian = '${u.where((x) => !x.tanggal.isBefore(hariIni)).length}';
          }
          // Di kartu putih supaya kotak pink tetap terlihat di atas latar pink.
          return SoftCard(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: _KotakStat(nilai: rata, label: 'Rata-rata', warna: AppColors.pink)),
              const SizedBox(width: 8),
              Expanded(child: _KotakStat(nilai: tugas, label: 'Tugas aktif', warna: AppColors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _KotakStat(nilai: ujian, label: 'Ujian dekat', warna: AppColors.softYellow)),
            ]),
          );
        },
      );

  // ------------------------------------------------------------------ Tugas
  static Widget _daftarTugas(BuildContext context, List<Tugas> list) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = list[i];
          return SoftCard(
            onTap: () => _detailTugas(context, t),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _BadgeMapel(t.mapel),
                const Spacer(),
                if (t.lewat)
                  const Text(
                    'Lewat tenggat',
                    style: TextStyle(color: AppColors.pink, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(t.judul, style: _judul),
              const SizedBox(height: 2),
              Text('Tenggat ${OrtuFmt.waktu(t.tenggat)}', style: _ket),
            ]),
          );
        },
      );

  static void _detailTugas(BuildContext context, Tugas t) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Align(alignment: Alignment.centerLeft, child: _BadgeMapel(t.mapel)),
            const SizedBox(height: 8),
            Text(t.judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Tenggat: ${OrtuFmt.waktu(t.tenggat)}', style: _ket),
            if (t.deskripsi != null) ...[
              const SizedBox(height: 12),
              Text(t.deskripsi!, style: const TextStyle(fontSize: 13)),
            ],
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
  static Widget _daftarUjian(BuildContext context, List<Ujian> list) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final u = list[i];
          return SoftCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _BadgeMapel(u.mapel),
              const SizedBox(height: 8),
              Text(u.judul, style: _judul),
              const SizedBox(height: 2),
              Text(
                [
                  [OrtuFmt.hari(u.tanggal), if (u.jamMulai != null) OrtuFmt.jam(u.jamMulai!)].join(', '),
                  if (u.ruang != null) u.ruang!,
                ].join(' · '),
                style: _ket,
              ),
              if (u.materi != null) ...[
                const SizedBox(height: 6),
                Text('Materi: ${u.materi}', style: const TextStyle(fontSize: 12)),
              ],
            ]),
          );
        },
      );

  // ------------------------------------------------------------------ Nilai
  static Widget _daftarNilai(BuildContext context, List<Nilai> list) {
    final perMapel = <String, List<Nilai>>{};
    for (final n in list) {
      perMapel.putIfAbsent(n.mapel, () => []).add(n);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        for (final e in perMapel.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KartuLipat(
              judul: _BadgeMapel(e.key),
              keterangan:
                  'Rata-rata ${(e.value.map((n) => n.nilai).reduce((a, b) => a + b) / e.value.length).toStringAsFixed(1)}',
              children: [
                for (final n in e.value)
                  ListTile(
                    dense: true,
                    title: Text(n.judul, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(n.jenis.replaceAll('_', ' '), style: _ket),
                    trailing: Text(
                      n.nilai.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.pink),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ Rapor
  static Widget _daftarRapor(BuildContext context, List<Rapor> list) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        children: [
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _KartuLipat(
                judul: Text('Semester ${r.semester[0].toUpperCase()}${r.semester.substring(1)}', style: _judul),
                keterangan: 'Tahun ajaran ${r.tahunAjaran}',
                children: [
                  for (final n in r.nilai)
                    ListTile(
                      dense: true,
                      title: Text(n.mapel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: n.deskripsi == null ? null : Text(n.deskripsi!, style: _ket),
                      trailing: Text(
                        '${n.nilaiAkhir?.toStringAsFixed(0) ?? '-'} ${n.predikat ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.pink),
                      ),
                    ),
                  if (r.catatan != null)
                    ListTile(
                      title: const Text('Catatan wali kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(r.catatan!, style: _ket),
                    ),
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
        ],
      );

  static const _judul = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
  static const _ket = TextStyle(fontSize: 12, color: AppColors.inkMuted);
}

class _KotakStat extends StatelessWidget {
  const _KotakStat({required this.nilai, required this.label, required this.warna});

  final String nilai, label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final teks = warna == AppColors.pink ? AppColors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(nilai, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: teks)),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: teks),
        ),
      ]),
    );
  }
}

/// Badge nama mapel (softPink, radius 8).
class _BadgeMapel extends StatelessWidget {
  const _BadgeMapel(this.mapel);
  final String mapel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.softPink, borderRadius: BorderRadius.circular(8)),
        child: Text(mapel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink)),
      );
}

/// Kartu yang bisa dibuka-tutup (pengganti Card + ExpansionTile).
class _KartuLipat extends StatelessWidget {
  const _KartuLipat({required this.judul, required this.keterangan, required this.children});

  final Widget judul;
  final String keterangan;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            iconColor: AppColors.pink,
            collapsedIconColor: AppColors.ink,
            title: Align(alignment: Alignment.centerLeft, child: judul),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(keterangan, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            ),
            children: children,
          ),
        ),
      );
}

/// Satu sub-tab berisi daftar data. Data tetap tersimpan saat pindah sub-tab,
/// dan bisa ditarik ke bawah untuk memuat ulang.
class _SubTab<T> extends StatefulWidget {
  const _SubTab({required this.muat, required this.builder, required this.pesanKosong, this.awal});

  /// Data awal yang sudah dimuat induk (opsional). Muat ulang selalu memanggil [muat].
  final Future<List<T>>? awal;
  final Future<List<T>> Function() muat;
  final Widget Function(BuildContext context, List<T> data) builder;
  final String pesanKosong;

  @override
  State<_SubTab<T>> createState() => _SubTabState<T>();
}

class _SubTabState<T> extends State<_SubTab<T>> with AutomaticKeepAliveClientMixin {
  late Future<List<T>> _future = widget.awal ?? widget.muat();

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
