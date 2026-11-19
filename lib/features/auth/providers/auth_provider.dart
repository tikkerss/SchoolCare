import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:schoolcare/features/auth/data/auth_repository.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

/// Menyimpan status login + profil pengguna (Supabase). Router mendengarkan provider ini
/// untuk memindahkan halaman secara otomatis.
///
/// Cara pakai di halaman mana pun:
///   context.watch<AuthProvider>().profile      → data pengguna yang login
///   context.watch<AuthProvider>().isWaliKelas  → true kalau guru ini wali kelas
///   context.read<AuthProvider>().signOut()     → keluar
class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  StreamSubscription<AuthState>? _sub;

  AuthStatus status = AuthStatus.loading;
  Profile? profile;
  String? kelasWaliId;
  String? errorMessage;

  bool get isWaliKelas => kelasWaliId != null;

  void init() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      const events = {
        AuthChangeEvent.initialSession,
        AuthChangeEvent.signedIn,
        AuthChangeEvent.signedOut,
        AuthChangeEvent.userUpdated,
      };
      if (events.contains(data.event)) _loadSession();
    });
  }

  Future<void> _loadSession() async {
    if (!_repo.hasSession) {
      profile = null;
      kelasWaliId = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final p = await _repo.getMyProfile();
      if (p == null || !p.isActive) {
        errorMessage = p == null
            ? 'Profil akun tidak ditemukan. Hubungi pihak sekolah.'
            : 'Akun tidak aktif. Silakan hubungi pihak sekolah.';
        await _repo.signOut(); // memicu event signedOut → kembali ke login
        return;
      }
      profile = p;
      kelasWaliId = p.role == UserRole.guru ? await _repo.getKelasWaliId() : null;
      status = AuthStatus.authenticated;
    } catch (e) {
      debugPrint('AuthProvider._loadSession: $e');
      errorMessage = 'Gagal memuat profil. Periksa koneksi internet.';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.signIn(email.trim(), password);
      // _loadSession dipanggil otomatis oleh event signedIn
    } on AuthException catch (e) {
      errorMessage = e.message.contains('Invalid login') ? 'Email atau password salah.' : e.message;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider.signIn: $e');
      errorMessage = 'Tidak bisa terhubung ke server.';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    errorMessage = null;
    await _repo.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
