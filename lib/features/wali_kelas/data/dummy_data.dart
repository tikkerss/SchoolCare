import 'models.dart';

/// Data dummy bersama untuk repository Kontak & Rapor.
/// (Absensi masih punya salinannya sendiri; boleh dipindah ke sini nanti.)
const dummyKelas = Kelas(id: 'kelas-1', namaKelas: 'VI A');

const dummySiswa = [
  Siswa(id: 's1', nis: '2024001', nama: 'Ahmad Fauzi'),
  Siswa(id: 's2', nis: '2024002', nama: 'Bunga Lestari'),
  Siswa(id: 's3', nis: '2024003', nama: 'Citra Ayu'),
  Siswa(id: 's4', nis: '2024004', nama: 'Dimas Pratama'),
  Siswa(id: 's5', nis: '2024005', nama: 'Eka Saputra'),
  Siswa(id: 's6', nis: '2024006', nama: 'Fitri Handayani'),
  Siswa(id: 's7', nis: '2024007', nama: 'Gilang Ramadhan'),
  Siswa(id: 's8', nis: '2024008', nama: 'Hana Salsabila'),
];

Future<void> jedaDummy([int ms = 500]) =>
    Future.delayed(Duration(milliseconds: ms));
