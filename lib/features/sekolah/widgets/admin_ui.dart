import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembantu kecil untuk semua halaman admin Pihak Sekolah.
class AdminUi {
  AdminUi._();

  /// Mengubah error Supabase menjadi pesan yang bisa dibaca.
  static String pesanError(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505') return 'Data sudah ada (duplikat). Periksa kembali isian yang harus unik.';
      if (e.code == '23503') return 'Data masih dipakai di tempat lain, jadi tidak bisa dihapus/diubah.';
      if (e.code == '42501') return 'Akun ini tidak punya izin untuk melakukan aksi ini.';
      return e.message;
    }
    if (e is FunctionException) {
      final d = e.details;
      if (d is Map && d['error'] != null) return d['error'].toString();
      return 'Gagal memanggil fungsi server (${e.status}). Pastikan Edge Function sudah di-deploy.';
    }
    if (e is AuthException) return e.message;
    return e.toString();
  }

  static void snack(BuildContext context, String pesan, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan),
      backgroundColor: error ? AppColors.danger : null,
    ));
  }

  static Future<bool> konfirmasi(BuildContext context, String judul, String isi, {String ya = 'Hapus'}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: Text(ya),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Menjalankan aksi simpan/hapus: menampilkan pesan sukses atau error.
  /// Mengembalikan true kalau berhasil.
  static Future<bool> jalankan(BuildContext context, Future<void> Function() aksi, {String? sukses}) async {
    try {
      await aksi();
      if (context.mounted && sukses != null) snack(context, sukses);
      return true;
    } catch (e) {
      debugPrint('Admin error: $e');
      if (context.mounted) snack(context, pesanError(e), error: true);
      return false;
    }
  }
}

/// Field pemilih tanggal.
class TanggalField extends StatelessWidget {
  const TanggalField({super.key, required this.label, required this.nilai, required this.onChanged, this.wajib = true});

  final String label;
  final DateTime? nilai;
  final ValueChanged<DateTime> onChanged;
  final bool wajib;

  @override
  Widget build(BuildContext context) => FormField<DateTime>(
        initialValue: nilai,
        validator: (_) => (wajib && nilai == null) ? 'Pilih tanggal' : null,
        builder: (state) => InkWell(
          onTap: () async {
            final now = DateTime.now();
            final t = await showDatePicker(
              context: context,
              initialDate: nilai ?? now,
              firstDate: DateTime(now.year - 20),
              lastDate: DateTime(now.year + 5),
            );
            if (t != null) {
              onChanged(t);
              state.didChange(t);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today),
              errorText: state.errorText,
            ),
            child: Text(nilai == null ? 'Pilih tanggal' : Fmt.tanggal(nilai!)),
          ),
        ),
      );
}

/// Field pemilih jam. Nilai disimpan sebagai teks 'HH:mm'.
class JamField extends StatelessWidget {
  const JamField({super.key, required this.label, required this.nilai, required this.onChanged});

  final String label;
  final String? nilai; // 'HH:mm' atau 'HH:mm:ss'
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => FormField<String>(
        initialValue: nilai,
        validator: (_) => nilai == null ? 'Pilih jam' : null,
        builder: (state) => InkWell(
          onTap: () async {
            final awal = nilai == null
                ? const TimeOfDay(hour: 7, minute: 0)
                : TimeOfDay(hour: int.parse(nilai!.substring(0, 2)), minute: int.parse(nilai!.substring(3, 5)));
            final t = await showTimePicker(
              context: context,
              initialTime: awal,
              builder: (c, child) =>
                  MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
            );
            if (t != null) {
              final teks = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              onChanged(teks);
              state.didChange(teks);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.schedule),
              errorText: state.errorText,
            ),
            child: Text(nilai == null ? 'Pilih jam' : Fmt.jam(nilai!)),
          ),
        ),
      );
}

/// Tombol simpan di bagian bawah form, dengan indikator loading.
class TombolSimpan extends StatelessWidget {
  const TombolSimpan({super.key, required this.menyimpan, required this.onPressed, this.label = 'Simpan'});

  final bool menyimpan;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: menyimpan ? null : onPressed,
        child: menyimpan
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      );
}
