import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schoolcare/features/guru/models/bukti_foto.dart';

class BuktiFotoException implements Exception {
  final String pesan;
  const BuktiFotoException(this.pesan);

  @override
  String toString() => pesan;
}

/// Mengambil foto bukti dari kamera + koordinat GPS + waktu.
class BuktiFotoService {
  static final _picker = ImagePicker();

  static Future<BuktiFoto> ambil() async {
    await _pastikanIzinLokasi();

    XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );

    // Khusus mode debug: kamera emulator sering tidak mengembalikan foto,
    // jadi sebagai cadangan buka galeri. Di APK rilis hanya kamera.
    if (foto == null && kDebugMode) {
      foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1280,
      );
    }

    if (foto == null) {
      throw const BuktiFotoException('Pengambilan foto dibatalkan.');
    }

    final posisi = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return BuktiFoto(
      file: File(foto.path),
      latitude: posisi.latitude,
      longitude: posisi.longitude,
      akurasiMeter: posisi.accuracy,
      waktu: DateTime.now(),
    );
  }

  static Future<void> _pastikanIzinLokasi() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const BuktiFotoException('GPS mati. Nyalakan lokasi terlebih dahulu.');
    }

    var izin = await Geolocator.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await Geolocator.requestPermission();
    }
    if (izin == LocationPermission.denied) {
      throw const BuktiFotoException('Izin lokasi ditolak.');
    }
    if (izin == LocationPermission.deniedForever) {
      throw const BuktiFotoException(
          'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.');
    }
  }
}
