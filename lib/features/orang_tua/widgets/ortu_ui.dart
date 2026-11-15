import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Komponen kecil yang dipakai di tampilan Orang Tua.
/// Sengaja disimpan di folder orang_tua supaya folder ini bisa berdiri sendiri.

// ===================================================================
// Warna (sementara). Nanti diganti dengan tema/design system bersama.
// ===================================================================
class OrtuWarna {
  OrtuWarna._();
  static const primary = Color(0xFF2563EB);
  static const surface = Colors.white;
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF0EA5E9);
  static const purple = Color(0xFF9333EA);
}

// ===================================================================
// Format tanggal Indonesia
// ===================================================================
class OrtuFmt {
  OrtuFmt._();
  static String hari(DateTime d) => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);
  static String tanggal(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
  static String waktu(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d.toLocal());
  static String bulan(DateTime d) => DateFormat('MMMM yyyy', 'id_ID').format(d);
  static String jamMenit(DateTime d) => DateFormat('HH:mm').format(d.toLocal());

  /// '07:00:00' → '07:00'
  static String jam(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

// ===================================================================
// Membuka WhatsApp / URL
// ===================================================================
class OrtuLink {
  OrtuLink._();

  /// [nomor] berformat 62xxxxxxxxxx
  static Future<bool> whatsapp(String? nomor, {String pesan = ''}) async {
    if (nomor == null || nomor.isEmpty) return false;
    final uri = Uri.https('wa.me', '/$nomor', pesan.isEmpty ? null : {'text': pesan});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> buka(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

// ===================================================================
// Badge status absensi & status kelas
// ===================================================================
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status; // nilai mentah, mis. 'hadir', 'dibatalkan'

  static const _map = <String, (String, Color)>{
    'hadir': ('Hadir', OrtuWarna.success),
    'terlambat': ('Terlambat', OrtuWarna.warning),
    'izin': ('Izin', OrtuWarna.info),
    'sakit': ('Sakit', OrtuWarna.purple),
    'alpa': ('Alpa', OrtuWarna.danger),
    'terjadwal': ('Terjadwal', OrtuWarna.textSecondary),
    'berlangsung': ('Berlangsung', OrtuWarna.success),
    'digantikan': ('Digantikan', OrtuWarna.warning),
    'dibatalkan': ('Dibatalkan', OrtuWarna.danger),
    'dijadwalkan_ulang': ('Dijadwal ulang', OrtuWarna.info),
    'kosong': ('Kosong', OrtuWarna.danger),
    'kegiatan': ('Kegiatan', OrtuWarna.purple),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _map[status] ?? (status, OrtuWarna.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// ===================================================================
// Loading / kosong / gagal
// ===================================================================
class MemuatView extends StatelessWidget {
  const MemuatView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class KosongView extends StatelessWidget {
  const KosongView({super.key, required this.pesan, this.ikon = Icons.inbox_outlined});
  final String pesan;
  final IconData ikon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(ikon, size: 56, color: OrtuWarna.textSecondary),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: OrtuWarna.textSecondary)),
          ]),
        ),
      );
}

class GagalView extends StatelessWidget {
  const GagalView({super.key, this.pesan = 'Gagal memuat data.', this.onCobaLagi});
  final String pesan;
  final VoidCallback? onCobaLagi;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off, size: 48, color: OrtuWarna.danger),
          const SizedBox(height: 8),
          Text(pesan),
          if (onCobaLagi != null) TextButton(onPressed: onCobaLagi, child: const Text('Coba lagi')),
        ]),
      );
}

/// FutureBuilder yang otomatis menampilkan loading, gagal, dan kosong.
/// Simpan Future di State (bukan dibuat di dalam build).
class TungguData<T> extends StatelessWidget {
  const TungguData({
    super.key,
    required this.future,
    required this.builder,
    this.onCobaLagi,
    this.kosong,
    this.pesanKosong = 'Belum ada data.',
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onCobaLagi;
  final bool Function(T data)? kosong;
  final String pesanKosong;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const MemuatView();
          if (snap.hasError) {
            debugPrint('TungguData: ${snap.error}');
            return GagalView(onCobaLagi: onCobaLagi);
          }
          final data = snap.data as T;
          if (kosong?.call(data) ?? false) return KosongView(pesan: pesanKosong);
          return builder(context, data);
        },
      );
}

// ===================================================================
// Menu kotak & judul bagian
// ===================================================================
class MenuKotak extends StatelessWidget {
  const MenuKotak({super.key, required this.ikon, required this.label, required this.onTap});
  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ikon, color: OrtuWarna.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}

class JudulBagian extends StatelessWidget {
  const JudulBagian(this.judul, {super.key, this.labelAksi = 'Lihat semua', this.onAksi});
  final String judul;
  final String labelAksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(
              judul,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (onAksi != null) TextButton(onPressed: onAksi, child: Text(labelAksi)),
        ]),
      );
}
