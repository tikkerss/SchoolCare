import 'dart:io';

/// Foto bukti absensi mengajar + lokasi GPS + waktu pengambilan.
class BuktiFoto {
  final File file;
  final double latitude;
  final double longitude;
  final double akurasiMeter;
  final DateTime waktu;

  const BuktiFoto({
    required this.file,
    required this.latitude,
    required this.longitude,
    required this.akurasiMeter,
    required this.waktu,
  });
}
