import 'package:url_launcher/url_launcher.dart';

/// 0812-3456-789 / +62 812 3456 789 / 812... -> 628123456789
String normalisasiNomor(String nomor) {
  var d = nomor.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) {
    d = '62${d.substring(1)}';
  } else if (d.startsWith('8')) {
    d = '62$d';
  }
  return d;
}

/// Salam sesuai jam sekarang.
String salamWaktu([DateTime? waktu]) {
  final jam = (waktu ?? DateTime.now()).hour;
  if (jam < 11) return 'pagi';
  if (jam < 15) return 'siang';
  if (jam < 18) return 'sore';
  return 'malam';
}

/// Buka chat WhatsApp dengan pesan yang sudah terisi.
/// Mengembalikan false kalau WhatsApp/browser tidak bisa dibuka.
Future<bool> bukaWhatsApp(String nomor, {String pesan = ''}) async {
  final uri = Uri.parse(
    'https://wa.me/${normalisasiNomor(nomor)}?text=${Uri.encodeComponent(pesan)}',
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Buka aplikasi telepon dengan nomor terisi (tidak langsung menelepon).
Future<bool> bukaTelepon(String nomor) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: nomor.replaceAll(' ', '')));
  } catch (_) {
    return false;
  }
}
