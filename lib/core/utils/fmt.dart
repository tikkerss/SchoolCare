import 'package:intl/intl.dart';

/// Format tanggal & jam gaya Indonesia.
class Fmt {
  Fmt._();

  /// Jumat, 13 November 2026
  static String hari(DateTime d) => DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);

  /// 13 Nov 2026
  static String tanggal(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);

  /// 13 Nov 2026, 07:05
  static String waktu(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d.toLocal());

  /// November 2026
  static String bulan(DateTime d) => DateFormat('MMMM yyyy', 'id_ID').format(d);

  /// '07:00:00' → '07:00'
  static String jam(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  /// Format tanggal untuk filter query Supabase: 2026-11-13
  static String db(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
}
