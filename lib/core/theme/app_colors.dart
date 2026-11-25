import 'package:material_ui/material_ui.dart';

/// Token warna SchoolCare (desain "Gaya Stiker").
/// Hanya 8 warna di bawah ini yang boleh dipakai. Nama token lama tetap ada
/// supaya kode fitur lain tetap jalan, tapi nilainya sudah diarahkan ke palet baru.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- palet
  static const pink = Color(0xFFD63F75);
  static const softPink = Color(0xFFFFD1DF);
  static const orange = Color(0xFFFFB21F);
  static const softYellow = Color(0xFFFFE9A6);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3A1426);
  static const inkMuted = Color(0xFF6E3A52);
  static const inkFaint = Color(0xFF8A5A6E);

  // ------------------------------------------------- token lama (alias)
  static const primary = pink;
  static const background = pink;
  static const surface = white;
  static const textPrimary = ink;
  static const textSecondary = inkMuted;
  static const border = softPink;

  // Warna status
  static const success = pink;
  static const warning = orange;
  static const danger = pink;
  static const info = orange;
  static const purple = softPink;

  // ------------------------------------------------------------- efek
  /// Bayangan tipis abu-abu untuk semua kartu.
  static const cardShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))];

  /// Bayangan pink tipis untuk kartu yang sedang berlangsung.
  static const activeShadow = [BoxShadow(color: Color(0x40D63F75), blurRadius: 14, offset: Offset(0, 3))];

  /// Bayangan bottom nav (ke atas).
  static const navShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2))];
}
