import 'dart:io';

class BuktiFoto {
  final File file;
  final double latitude;
  final double longitude;
  final DateTime waktu;

  const BuktiFoto({
    required this.file,
    required this.latitude,
    required this.longitude,
    required this.waktu,
  });
}