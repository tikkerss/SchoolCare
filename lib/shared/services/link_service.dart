import 'package:url_launcher/url_launcher.dart';

/// Membuka WhatsApp, browser, atau file (PDF) di aplikasi luar.
class LinkService {
  LinkService._();

  /// [nomor] berformat 62xxxxxxxxxx (begitulah format di database).
  /// Mengembalikan false kalau nomor kosong atau WhatsApp tidak bisa dibuka.
  static Future<bool> whatsapp(String? nomor, {String pesan = ''}) async {
    if (nomor == null || nomor.isEmpty) return false;
    final uri = Uri.https('wa.me', '/$nomor', pesan.isEmpty ? null : {'text': pesan});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> buka(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
