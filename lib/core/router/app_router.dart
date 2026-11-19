import 'package:go_router/go_router.dart';
import 'package:schoolcare/features/auth/data/profile.dart';
import 'package:schoolcare/features/auth/pages/login_page.dart';
import 'package:schoolcare/features/auth/pages/profil_page.dart';
import 'package:schoolcare/features/auth/pages/splash_page.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:schoolcare/features/guru/guru_shell.dart';
import 'package:schoolcare/features/orang_tua/pages/ortu_shell_page.dart';
import 'package:schoolcare/features/sekolah/pages/sekolah_home_page.dart';
import 'package:schoolcare/features/wali_kelas/pages/wali_home_page.dart';
import 'package:schoolcare/shared/pages/jadwal_kelas_page.dart';
import 'package:schoolcare/shared/pages/kalender_page.dart';
import 'package:schoolcare/shared/pages/pengumuman_page.dart';

/// Pembagian awalan alamat supaya tidak bentrok antar anggota:
///   /ortu/...     → FE Orang Tua
///   /guru/...     → FE Guru
///   /wali/...     → FE Wali Kelas
///   /sekolah/...  → Backend + FE Wali Kelas (laporan)
///   /info/...     → halaman bersama (semua peran)
/// Tambah route baru lewat Pull Request supaya file ini tidak bentrok.
String homeOf(AuthProvider auth) => switch (auth.profile!.role) {
      UserRole.orangTua => '/ortu',
      UserRole.guru => '/guru',
      UserRole.manajemen => '/sekolah',
    };

GoRouter createRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        switch (auth.status) {
          case AuthStatus.loading:
            return loc == '/splash' ? null : '/splash';
          case AuthStatus.unauthenticated:
            return loc == '/login' ? null : '/login';
          case AuthStatus.authenticated:
            final role = auth.profile!.role;
            final home = homeOf(auth);
            if (loc == '/splash' || loc == '/login') return home;
            // cegah membuka halaman milik peran lain
            if (loc.startsWith('/ortu') && role != UserRole.orangTua) return home;
            if (loc.startsWith('/guru') && role != UserRole.guru) return home;
            if (loc.startsWith('/wali') && !auth.isWaliKelas) return home;
            if (loc.startsWith('/sekolah') && role != UserRole.manajemen) return home;
            return null;
        }
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/profil', builder: (context, state) => const ProfilPage()),

        // ---------- per peran ----------
        GoRoute(path: '/ortu', builder: (context, state) => const OrtuShellPage()),
        GoRoute(path: '/guru', builder: (context, state) => const GuruShell()),
        GoRoute(path: '/wali', builder: (context, state) => const WaliHomePage()),
        GoRoute(path: '/sekolah', builder: (context, state) => const SekolahHomePage()),

        // ---------- halaman bersama ----------
        GoRoute(path: '/info/pengumuman', builder: (context, state) => const PengumumanPage()),
        GoRoute(
          path: '/info/kalender',
          builder: (context, state) => KalenderPage(kelasId: state.uri.queryParameters['kelas']),
        ),
        GoRoute(
          path: '/info/jadwal/:kelasId',
          builder: (context, state) => JadwalKelasPage(kelasId: state.pathParameters['kelasId']!),
        ),
      ],
    );
