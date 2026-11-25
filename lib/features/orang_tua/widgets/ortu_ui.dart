import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/permukaan.dart';
import 'package:schoolcare/shared/widgets/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';

/// Komponen kecil yang dipakai di tampilan Orang Tua.
/// Sengaja disimpan di folder orang_tua supaya folder ini bisa berdiri sendiri.

// ===================================================================
// Warna: semua diarahkan ke AppColors (design system bersama).
// ===================================================================
class OrtuWarna {
  OrtuWarna._();
  static const primary = AppColors.primary;
  static const surface = AppColors.surface;
  static const textSecondary = AppColors.textSecondary;
  static const border = AppColors.border;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const danger = AppColors.danger;
  static const info = AppColors.info;
  static const purple = AppColors.purple;
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

  @override
  Widget build(BuildContext context) => StatusBadge(status);
}

// ===================================================================
// Loading / kosong / gagal
// ===================================================================
class MemuatView extends StatelessWidget {
  const MemuatView({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(color: Permukaan.diPutih(context) ? AppColors.pink : AppColors.white),
      );
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
            Icon(ikon, size: 56, color: Permukaan.diPutih(context) ? AppColors.softPink : AppColors.white),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center, style: TextStyle(color: Permukaan.teksRedup(context))),
          ]),
        ),
      );
}

class GagalView extends StatelessWidget {
  const GagalView({super.key, this.pesan = 'Gagal memuat data.', this.onCobaLagi});
  final String pesan;
  final VoidCallback? onCobaLagi;

  @override
  Widget build(BuildContext context) {
    final warna = Permukaan.diPutih(context) ? null : AppColors.white;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off, size: 48, color: warna ?? OrtuWarna.danger),
        const SizedBox(height: 8),
        Text(pesan, textAlign: TextAlign.center, style: TextStyle(color: warna ?? AppColors.ink)),
        if (onCobaLagi != null)
          TextButton(
            onPressed: onCobaLagi,
            style: warna == null ? null : TextButton.styleFrom(foregroundColor: warna),
            child: const Text('Coba lagi'),
          ),
      ]),
    );
  }
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
  const MenuKotak({
    super.key,
    required this.ikon,
    required this.label,
    required this.onTap,
    this.warna = AppColors.softPink,
  });
  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  /// Warna kotak ikon: pink · orange · softPink · softYellow.
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(16)),
            child: Icon(ikon, color: AppColors.teksDi(warna), size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, color: Permukaan.teks(context), height: 1.25),
          ),
        ]),
      ),
    );
  }
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
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Permukaan.teks(context)),
            ),
          ),
          if (onAksi != null)
            TextButton(
              onPressed: onAksi,
              style: Permukaan.diPutih(context) ? null : TextButton.styleFrom(foregroundColor: AppColors.white),
              child: Text(labelAksi),
            ),
        ]),
      );
}
