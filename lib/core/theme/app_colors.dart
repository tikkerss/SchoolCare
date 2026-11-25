import 'package:material_ui/material_ui.dart';

/// Token warna SchoolCare (desain "Gaya Stiker", FINAL).
/// Hanya warna di bawah ini yang boleh dipakai. Nama token lama tetap ada
/// supaya kode fitur lain tetap jalan, tapi nilainya sudah diarahkan ke palet baru.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------- palet
  static const pink = Color(0xFFD63F75);
  static const softPink = Color(0xFFFFD1DF);
  static const orange = Color(0xFFE07400);
  static const softYellow = Color(0xFFFFE9A6);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3A1426);
  static const inkMuted = Color(0xFF6E3A52);
  static const inkFaint = Color(0xFF8A5A6E);

  /// Teks di atas kotak softPink & softYellow.
  static const black = Color(0xFF000000);

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
  static const info = softYellow;
  static const purple = softPink;

  // ------------------------------------------------- warna teks per latar
  /// true untuk latar muda (softPink / softYellow): teksnya hitam bold.
  static bool latarMuda(Color latar) => latar == softPink || latar == softYellow;

  /// Warna teks/ikon yang sesuai di atas [latar]:
  /// pink & orange → putih, softPink & softYellow → hitam, lainnya (frame putih) → ink.
  static Color teksDi(Color latar) {
    if (latar == pink || latar == orange) return white;
    if (latarMuda(latar)) return black;
    return ink;
  }

  // ------------------------------------------------------------- efek
  /// Bayangan lembut untuk semua frame putih.
  static const cardShadow = [BoxShadow(color: Color(0x383A1426), blurRadius: 16, offset: Offset(0, 6))];

  /// Bayangan pink tipis untuk kartu yang sedang berlangsung.
  static const activeShadow = [BoxShadow(color: Color(0x40D63F75), blurRadius: 16, offset: Offset(0, 6))];

  /// Bayangan bottom nav (ke atas).
  static const navShadow = [BoxShadow(color: Color(0x383A1426), blurRadius: 16, offset: Offset(0, -6))];
}
