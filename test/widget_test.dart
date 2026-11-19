import 'package:flutter_test/flutter_test.dart';
import 'package:schoolcare/core/utils/fmt.dart';
import 'package:schoolcare/features/auth/data/profile.dart';

void main() {
  test('Fmt.jam memotong detik', () {
    expect(Fmt.jam('07:40:00'), '07:40');
  });

  test('Fmt.db memakai format tanggal Supabase', () {
    expect(Fmt.db(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('Peran dari database dibaca dengan benar', () {
    expect(roleFromDb('manajemen'), UserRole.manajemen);
    expect(roleFromDb('guru'), UserRole.guru);
    expect(roleFromDb('orang_tua'), UserRole.orangTua);
  });
}
