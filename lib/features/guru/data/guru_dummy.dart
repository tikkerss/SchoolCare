import '../models/jadwal.dart';

const jadwalHariIni = [
  Jadwal(
    id: 'j1',
    mapel: 'Matematika',
    kelas: 'VII A',
    ruang: 'R. 201',
    jamMulai: '07.00',
    jamSelesai: '08.30',
    status: StatusKelas.berlangsung,
  ),
  Jadwal(
    id: 'j2',
    mapel: 'Matematika',
    kelas: 'VII B',
    ruang: 'R. 202',
    jamMulai: '08.30',
    jamSelesai: '10.00',
  ),
  Jadwal(
    id: 'j3',
    mapel: 'Matematika',
    kelas: 'VIII A',
    ruang: 'R. 301',
    jamMulai: '10.15',
    jamSelesai: '11.45',
    status: StatusKelas.digantikan,
  ),
  Jadwal(
    id: 'j4',
    mapel: 'Matematika',
    kelas: 'VIII C',
    ruang: 'R. 303',
    jamMulai: '12.30',
    jamSelesai: '14.00',
    status: StatusKelas.dibatalkan,
  ),
];