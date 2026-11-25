# SchoolCare: panduan desain untuk implementasi Flutter

Desain final: kanvas "SchoolCare UI" (baris **Gaya Stiker**). Dokumen ini isinya semua yang perlu diterapkan ke kode.

## Aturan kerja (WAJIB)

- **Jangan menjalankan `git commit`, `git push`, atau membuat PR.** Cukup ubah file. Pemilik repo yang commit dan push sendiri.
- Jangan menambahkan "Co-Authored-By", "Generated with Claude", atau atribusi apa pun di kode, komentar, maupun pesan.
- Jangan mengubah logika data, auth, router, atau Supabase (semua `*_repository.dart`, `*_dummy.dart`, `auth_provider.dart`, `app_router.dart`). Yang diubah cuma tampilan.

## 1. Warna (hanya ini)

| Token | Hex | Dipakai untuk |
|---|---|---|
| `pink` | `#D63F75` | latar semua halaman, tombol utama, tab aktif, status Hadir/Berlangsung |
| `softPink` | `#FFD1DF` | garis input, kotak ikon, status Sakit |
| `orange` | `#FFB21F` | aksi kedua, status Terlambat/Digantikan |
| `softYellow` | `#FFE9A6` | kotak info, status Izin/Selesai, badan maskot |
| `white` | `#FFFFFF` | kartu, bottom nav, teks di atas pink |
| `ink` | `#3A1426` | teks utama, ikon |
| `inkMuted` | `#6E3A52` | teks keterangan |
| `inkFaint` | `#8A5A6E` | placeholder, tanggal yang belum lewat |

- **Semua halaman dasarnya pink `#D63F75`** polos (tanpa gradasi/pola): Pembuka, Login, dan semua halaman isi. Konten tetap di **kartu putih**. Judul halaman, sapaan, dan teks yang langsung di atas latar pink pakai warna putih; ikon tombol kembali putih di kotak `Color(0x26FFFFFF)`. `Scaffold`/`AppBar` latar pink, `foregroundColor` putih.
- **Tanpa garis hitam tebal.** Kartu cuma pakai bayangan tipis abu-abu: `BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))`.
- Input: latar putih, garis `softPink` 1.5px, radius 14.
- Radius: kartu 20–22, tombol 14–16, chip 8, kotak tab aktif 10.
- Tidak ada elemen miring (rotasi 0) dan tidak ada coretan dekoratif.

## 2. Tipografi: Poppins, 3 ketebalan

Pakai package `google_fonts` (`GoogleFonts.poppinsTextTheme`), atau bundel file Poppins Regular, Bold & ExtraBold di `assets/fonts`.

- **ExtraBold (w800)** untuk teks "hook" yang besar: judul halaman (22–28), sapaan ("Hari ini, Andi di sekolah", "Halo, Bu Sri"), "SchoolCare" di Pembuka/Login (36–44), angka statistik besar.
- **Bold (w700)**: judul bagian (15), nama mapel/judul kartu (14), tombol, chip status, label tab aktif.
- **Regular (w400)**: isi (12–13), jam, tanggal, keterangan (11), placeholder, label tab tidak aktif.
- Jangan pakai w500 atau w600.

## 3. Status

**Kehadiran siswa** (pakai emotikon di `assets/emotikon/`, render dengan `flutter_svg`):

| Status | File | Chip (latar / teks) |
|---|---|---|
| hadir | `emo_hadir.svg` | pink / putih |
| terlambat | `emo_terlambat.svg` | orange / ink |
| izin | `emo_izin.svg` | softYellow / ink |
| sakit | `emo_sakit.svg` | softPink / ink |
| alpa | `emo_alpa.svg` | putih + garis putus pink / pink |

**Status kelas**: berlangsung = pink/putih · digantikan = orange/ink · dibatalkan = putih + garis putus pink/pink · terjadwal = putih/ink · selesai = softYellow/ink.

## 4. Komponen

- **Bottom nav**: latar putih, bayangan tipis ke atas, tinggi ±80. Tiap item berupa ikon di dalam kotak 40×40 dengan label 10px di bawahnya. Item aktif: kotak `pink` radius 10, ikon putih, label Bold. Item tidak aktif: tanpa kotak, ikon ink, label Regular. Tanpa tombol bulat di tengah.
  - Orang Tua: Beranda · Kehadiran · Akademik · Profil
  - Guru: Jadwal · Tugas · Profil (3 tab, sesuai `guru_shell.dart` terbaru)
- **Tombol utama**: pink, teks putih Bold, tinggi 52, radius 16. **Tombol kedua**: orange, teks ink.
- **Kartu tiket** (jadwal/pelajaran): kolom jam di kiri (lebar ±60) dipisah garis putus-putus `softPink`, isi di kanan. Kartu yang sedang berlangsung diberi bayangan pink tipis.
- **Widget `EmotikonKehadiran(status, size)`**: menampilkan SVG yang sesuai status.
- **Maskot Tasi** (`assets/maskot/tasi.svg`): tas sekolah soft yellow, dipakai di Pembuka dan Login.

## 5. Layar

1. **Pembuka** (`splash_page.dart`): latar pink. Balon chat putih: "Halo! Aku **Tasi**. Aku yang kabarin kalau si kecil udah sampai sekolah." Di bawahnya maskot (±220px), "SchoolCare" putih Bold 44, tagline "Hadir, belajar, dan nilai anak. Semua kabar sekolah di satu tempat.", lalu indikator loading putih kecil (tombol "Mulai" di kanvas tidak dipakai karena router pindah otomatis).
2. **Login**: latar pink. Di atas: "Selamat datang di" + "SchoolCare" (putih), maskot 150px di kanan, duduk menumpuk di atas kartu. Kartu putih berisi form Email & Kata sandi dan tombol Masuk. Paling bawah ada kotak info softYellow: "Belum punya akun atau lupa sandi? Hubungi Manajemen Sekolah."
3. **Beranda Orang Tua** (`beranda_tab.dart`): judul "Hari ini, **Andi** di sekolah" (nama anak berwarna pink), di bawahnya tanggal + pemilih anak. Kartu kehadiran softYellow dengan emotikon besar. Kartu tiket "Sekarang". Grid 4 menu (Izin/Sakit pink, Aktivitas orange, Tugas softPink, Chat Guru softYellow). Pengumuman berupa kartu softYellow.
4. **Kehadiran** (`kehadiran_tab.dart`): kartu rekap bulan berisi 5 emotikon + jumlahnya. Kalender Sen–Jum dengan emotikon per hari; hari yang belum lewat tampil sebagai lingkaran angka bergaris softPink; tanggal terpilih diberi cincin pink. Kartu detail hari terpilih berisi riwayat perubahan status.
5. **Aktivitas Harian** (`aktivitas_harian_page.dart`): strip 5 hari (aktif = pink), lalu daftar kartu tiket per jam pelajaran yang bisa dibuka untuk melihat foto + berita acara.
6. **Akademik** (`akademik_tab.dart`): 3 kotak statistik (Rata-rata pink, Tugas aktif orange, Ujian dekat softYellow), tab segmented Tugas/Ujian/Nilai/Rapor (aktif = pink), lalu daftar kartu dengan badge mapel.
7. **Guru · Jadwal** (`jadwal_page.dart`): "Halo, **Bu Sri**" + chip "Wali 7A", 3 kotak statistik, kartu absensi siswa pagi, lalu daftar kartu tiket. Kartu kelas yang sedang berjalan punya tombol "Absen Mengajar".
8. **Guru · Absen Mengajar** (`absensi_mengajar_page.dart` / `absensi_hadir_page.dart`): segmented Hadir/Tidak Hadir. Hadir = foto bukti + label geotag + berita acara. Tidak hadir = keterangan, unggah surat, pilihan Ada pengganti/Dibatalkan, dan dropdown guru pengganti. Tombol "Kirim Absensi".

## 6. Kondisi repo saat ini (per merge PR #2, 19 Nov 2026)

Beberapa file sudah dibuat anggota lain, jadi **ubah file yang ada, jangan bikin duplikat**:

- `lib/core/theme/app_colors.dart` sudah ada dan dipakai banyak fitur (`primary`, `background`, `surface`, `textPrimary`, `textSecondary`, `border`, `success`, `warning`, `danger`, `info`, `purple`). **Jangan hapus nama-nama ini** biar kode anggota lain tetap jalan. Ganti nilainya ke palet di atas, lalu tambahkan token baru (`pink`, `softPink`, `orange`, `softYellow`, `ink`, `inkMuted`, `inkFaint`). Pemetaannya:
  - `primary` = pink, `background` = pink, `surface` = white
  - `textPrimary` = ink, `textSecondary` = inkMuted, `border` = softPink
  - `success` = pink, `warning` = orange, `info` = orange, `danger` = pink, `purple` = softPink
  - Kalau ada pemakaian `color.withValues(alpha: 0.12)` buat latar chip, ganti ke warna status dari tabel di bagian 3.
- `lib/core/theme/app_theme.dart` sudah ada: ubah jadi Poppins (`google_fonts`), latar putih, kartu tanpa garis + bayangan tipis, input bergaris softPink, `FilledButton` pink radius 16, `NavigationBarTheme` sesuai bagian 4.
- `lib/features/auth/pages/splash_page.dart` dan `login_page.dart` sudah ada dan tersambung ke `AuthProvider` + router (`/splash` tampil saat auth loading, lalu otomatis ke `/login` atau beranda). **Logika auth jangan diubah**, cukup tampilannya. Pembuka = `splash_page.dart` dengan desain bagian 5 no. 1, tapi **tanpa tombol "Mulai"** karena router sudah pindah otomatis (ganti dengan indikator loading kecil warna putih).
- `lib/shared/widgets/status_badge.dart` (`StatusBadge`) sudah dipakai lintas fitur: restyle di file itu sesuai bagian 3, jangan bikin chip baru. Samakan juga `wali_kelas/widgets/status_badge.dart`, `wali_kelas/widgets/status_rapor_badge.dart`, `laporan_sekolah/widgets/status_guru_badge.dart`, dan `guru/widgets/status_kelas_chip.dart` supaya memakai `AppColors`.
- `ortu_ui.dart` punya `OrtuWarna` sendiri: arahkan semua nilainya ke `AppColors`.
- Bottom nav ada di `guru_shell.dart` dan `ortu_shell_page.dart` (pakai `NavigationBar`). Ganti dengan `AppBottomNav` baru di `lib/shared/widgets/`.
- **Fitur Guru dirombak teman (PR #6 & #7, 19 Nov 22.52)**: sekarang memakai Supabase, ada `jadwal_detail_page.dart`, `absensi_tidak_hadir_page.dart` (form Tidak Hadir resmi, jangan bikin versi sendiri), `tugas_page.dart`, `tugas_form_page.dart`, `tugas_detail_page.dart`, `bukti_foto_picker.dart`, `catatan_siswa_sheet.dart`. `status_kelas_chip.dart` **sudah dihapus**: status kelas pakai `StatusBadge` bersama. Semua halaman Guru ini cukup di-restyle, logikanya jangan diubah.
- Fitur lain (`wali_kelas`, `sekolah`, `laporan_sekolah`, `shared/pages`) cukup ikut tema baru. Cek tidak ada warna hardcode di luar palet (`grep -rn "Color(0x" lib`).

## 7. File baru

```
lib/shared/widgets/emotikon_kehadiran.dart
lib/shared/widgets/app_bottom_nav.dart
lib/shared/widgets/ticket_card.dart
assets/emotikon/*.svg, assets/maskot/tasi.svg   (sudah ada)
```

Tambahkan `flutter_svg` dan `google_fonts` di `pubspec.yaml`, daftarkan `assets/emotikon/` dan `assets/maskot/` di bagian `flutter: assets:` (jangan hapus `.env`), lalu jalankan `flutter pub get` dan `flutter analyze`.
