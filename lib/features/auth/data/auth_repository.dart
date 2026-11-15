import 'package:schoolcare/core/config/supabase_config.dart';
import 'package:schoolcare/features/auth/data/profile.dart';

class AuthRepository {
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();

  bool get hasSession => supabase.auth.currentSession != null;

  Future<Profile?> getMyProfile() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await supabase.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  /// id kelas yang diwalikan guru ini pada tahun ajaran aktif (null = bukan wali kelas)
  Future<String?> getKelasWaliId() async {
    final uid = supabase.auth.currentUser!.id;
    final row = await supabase
        .from('kelas')
        .select('id, tahun_ajaran!inner(is_active)')
        .eq('wali_kelas_id', uid)
        .eq('tahun_ajaran.is_active', true)
        .maybeSingle();
    return row?['id'] as String?;
  }
}
