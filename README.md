# SchoolCare

Aplikasi Flutter untuk memantau kehadiran, aktivitas, dan perkembangan akademik siswa.
Ada 4 tampilan: **Orang Tua**, **Guru**, **Wali Kelas**, dan **Pihak Sekolah**. Backend: **Supabase**.

## Cara menjalankan

1. `git pull`
2. Buat file `.env` di root project (sejajar `pubspec.yaml`):
   ```
   SUPABASE_URL=https://<id-project>.supabase.co
   SUPABASE_ANON_KEY=<anon / publishable key>
   ```
   Ambil di Supabase → Project Settings → API Keys. JANGAN pakai secret / service_role key.
3. `flutter pub get`
4. `flutter run`

Login memakai akun Supabase. Akun dibuat oleh Pihak Sekolah dari menu **Akun**.

## Status data per tampilan

| Tampilan | Data |
| --- | --- |
| Login, profil, routing per peran | Supabase |
| Pihak Sekolah (semua menu admin) | Supabase |
| Pengumuman, kalender, jadwal kelas (`/info/...`) | Supabase |
| Orang Tua | masih dummy (`ortu_dummy.dart`), nanti ganti isi `ortu_repository.dart` |
| Guru | masih dummy (`guru_dummy.dart`) |

## Struktur folder

```
lib/
├── main.dart, app.dart
├── core/       config (Supabase), theme, router, utils
├── shared/     widgets, services, data, pages   (komponen & halaman bersama)
└── features/
    ├── auth/        login, profil, AuthProvider
    ├── orang_tua/   FE Orang Tua
    ├── guru/        FE Guru
    ├── wali_kelas/  FE Wali Kelas
    └── sekolah/     Pihak Sekolah (admin)
supabase/functions/create-user/   Edge Function untuk membuat akun
```

## Aturan tim

- Import Material: `package:material_ui/material_ui.dart` (bukan `package:flutter/material.dart`).
- Query Supabase hanya di file `data/*_repository.dart`, bukan di halaman.
- Alamat halaman: `/ortu`, `/guru`, `/wali`, `/sekolah`, `/info/...` (bersama).
- File bersama (`core/`, `shared/`, `main.dart`, `app.dart`, `pubspec.yaml`) diubah lewat Pull Request.

## Yang sudah siap dipakai

| Komponen | File | Pemakaian |
| --- | --- | --- |
| Pengguna yang login | `features/auth/providers/auth_provider.dart` | `context.watch<AuthProvider>().profile`, `.isWaliKelas`, `.kelasWaliId`, `signOut()` |
| Halaman profil + tombol keluar | `features/auth/pages/profil_page.dart` | `ProfilPage(showAppBar: false)` sebagai tab |
| Client Supabase | `core/config/supabase_config.dart` | `supabase.from('tabel')...` (di repository) |
| `AsyncView`, `LoadingView`, `EmptyState`, `ErrorView` | `shared/widgets/state_views.dart` | Loading / error / kosong seragam |
| `StatusBadge('sakit')` | `shared/widgets/status_badge.dart` | Status absensi & status kelas |
| `Fmt.hari/tanggal/waktu/jam/db` | `core/utils/fmt.dart` | Format tanggal Indonesia, `Fmt.db` untuk query |
| `LinkService.whatsapp/buka` | `shared/services/link_service.dart` | Chat WhatsApp, buka URL |
| Halaman info | `shared/pages/` | `context.push('/info/pengumuman')`, `'/info/kalender?kelas=ID'`, `'/info/jadwal/ID'` |
