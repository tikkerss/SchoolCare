# SchoolCare: panduan desain untuk implementasi Flutter

Desain final: kanvas "SchoolCare UI", baris **Gaya Stiker** (gaya dasar) dan baris **Final + elemen gemes** (komponen gemes + nav lekukan). Dokumen ini isinya semua yang perlu diterapkan ke kode.

## Aturan kerja (WAJIB)

- **Jangan menjalankan `git commit`, `git push`, atau membuat PR.** Cukup ubah file. Pemilik repo yang commit dan push sendiri.
- Jangan menambahkan "Co-Authored-By", "Generated with Claude", atau atribusi apa pun di kode, komentar, maupun pesan.
- Jangan mengubah logika data, auth, router, atau Supabase (semua `*_repository.dart`, `*_dummy.dart`, `auth_provider.dart`, `app_router.dart`). Yang diubah cuma tampilan.

## 1. Warna (FINAL, hanya ini)

| Token | Hex | Dipakai untuk |
|---|---|---|
| `pink` | `#D63F75` | **latar semua halaman**, tombol utama, tab aktif, status Hadir/Berlangsung |
| `softPink` | `#FFD1DF` | kotak aksen, garis input, status Sakit |
| `orange` | `#E07400` | kotak statistik, menu Izin/Sakit, chip Wali, status Terlambat/Digantikan |
| `softYellow` | `#FFE9A6` | kartu kehadiran, kotak info, hari terpilih, status Izin/Selesai |
| `white` | `#FFFFFF` | **semua frame**: kartu, nav bawah, form, input, tab |
| `ink` | `#3A1426` | teks utama di frame putih |
| `inkMuted` | `#6E3A52` | teks keterangan di frame putih |
| `black` | `#000000` | teks di kotak softPink & softYellow |

Aturan:
- **Semua halaman latarnya pink `#D63F75`** polos. Isi selalu di **frame putih** (radius 16–22, bayangan `BoxShadow(color: Color(0x383A1426), blurRadius: 16, offset: Offset(0, 6))`). Tanpa garis hitam tebal, tanpa gradasi.
- Teks langsung di atas latar pink (judul halaman, sapaan, subjudul) = **putih**. Nama di sapaan ("Andi", "Bu Sri") = softYellow.
- **Warna teks per latar:** pink tua & orange → teks/ikon **putih**. softPink & softYellow → teks **hitam bold** (label w700, angka w800). Frame putih → ink.
- Kotak statistik (Akademik, Jadwal Guru): urutan **orange · softPink · orange**, isi **rata tengah** (label di atas, angka besar di bawah).
- Hiasan latar: 2 lingkaran transparan lembut di pojok (`softPink` 16% dan `softYellow` 14%). Tidak ada rotasi.
- Maskot Tasi kecil (±104px) di samping judul Beranda.

## 2. Tipografi: Poppins, 3 ketebalan

Pakai `google_fonts` (`GoogleFonts.poppinsTextTheme`). Hanya w400, w700, w800.

- **ExtraBold (w800)**: judul halaman, sapaan, "SchoolCare", angka statistik besar.
- **Bold (w700)**: judul bagian, judul kartu/mapel, tombol, chip, label di kotak berwarna, label tab aktif.
- **Regular (w400)**: isi, jam, tanggal, keterangan, placeholder, label tab tidak aktif.

## 3. Status

**Kehadiran siswa** (emotikon di `assets/emotikon/`, render dengan `flutter_svg`):

| Status | File | Chip (latar / teks) |
|---|---|---|
| hadir | `emo_hadir.svg` | pink / putih |
| terlambat | `emo_terlambat.svg` | orange / putih |
| izin | `emo_izin.svg` | softYellow / hitam |
| sakit | `emo_sakit.svg` | softPink / hitam |
| alpa | `emo_alpa.svg` | putih + garis putus pink / pink |

Kalender kehadiran: hari yang belum lewat = lingkaran transparan bergaris putus-putus pink; tanggal terpilih = cincin pink 2.5px. Jaga sel minimal 54px tingginya supaya tidak overflow.

**Status kelas**: berlangsung = pink/putih · digantikan = orange/putih · dibatalkan = softYellow + garis putus pink/pink · terjadwal = softYellow/hitam · selesai = softYellow/hitam.

## 4. Komponen

- **Bottom nav (model lekukan / notch)**: bar putih melayang (margin 14 kiri-kanan, 16 dari bawah, tinggi 64, radius 20, bayangan lembut). Ikon tidak aktif: garis ink, tanpa label. Item aktif: **lingkaran putih 54px dengan ikon pink `#D63F75`** (garis 2.4) yang naik setengah di atas bar, bayangan lembut. Navigasi **serba putih**, tanpa warna lain, dan bar punya **lekukan melengkung** di bawah lingkaran itu (bentuk bar pakai `CustomPainter`/`ClipPath`, lekukan pindah sesuai tab aktif, animasi geser ±250ms). Label item aktif (w800, 10px) di bawah lingkaran. Pakai `aria-label`/`Semantics` untuk tiap ikon.
  - Orang Tua: Beranda · Kehadiran · Akademik · Profil
  - Guru: Jadwal · Tugas · Profil (3 tab, sesuai `guru_shell.dart` terbaru)
- **Tombol utama** (di dalam frame putih): pink, teks putih Bold, tinggi 52, radius 16. Tombol yang langsung di atas latar pink (mis. "Kirim Absensi"): softYellow, teks ink Bold. **Tombol kedua**: orange, teks putih.
- **Kartu tiket** (jadwal/pelajaran): frame putih, kolom jam di kiri (lebar ±60) dipisah garis putus-putus `softPink`, lekukan setengah lingkaran berwarna latar pink di atas & bawah garis.
- **Widget `EmotikonKehadiran(status, size)`**: menampilkan SVG yang sesuai status.
- **Maskot Tasi** (`assets/maskot/tasi.svg`): tas sekolah soft yellow, dipakai di Pembuka, Login, dan Beranda.

### Komponen gemes (pakai 2–3 per layar, jangan semua sekaligus)

- **Kartu balon chat + label nama**: frame putih dengan "ekor" kecil di kiri atas, dan **pill label** (oranye/pink, teks putih Bold 10–11px, bayangan dalam bawah) yang menempel di pinggir atas kartu. Untuk kartu kehadiran Beranda dan riwayat perubahan status ("Bu Sri · 07.05", "Pak Budi · 10.15").
- **Pojok tergigit**: dua lingkaran kecil berwarna latar pink di pojok kanan atas kartu.
- **Tasi ngintip**: maskot ±112px di pojok kanan bawah kartu kehadiran, terpotong oleh kartu (`ClipRRect`), hanya kepala yang kelihatan.
- **Tombol glossy**: tombol/menu dengan kilau putih 38% tipis di atas (strip 6–7px) dan bayangan dalam gelap 4–5px di bawah (`inset 0 -5px 0 rgba(0,0,0,0.16)`).
- **Progress bar bergaris**: tinggi 16, radius penuh, track softPink, isi pink dengan garis miring putih 28% (`repeating-linear-gradient` 135°). Untuk "Kehadiran bulan ini 11/14 hari".
- **Kertas tempel**: softYellow dengan selotip pink transparan di atas dan pojok kanan bawah terlipat. Untuk Pengumuman.

**Catatan:** kalau ada yang bertentangan, bagian 1–4 yang berlaku.

## 5. Layar

1. **Pembuka** (`splash_page.dart`): latar pink. Balon chat putih: "Halo! Aku **Tasi**. Aku yang kabarin kalau si kecil udah sampai sekolah." Di bawahnya maskot (±220px), "SchoolCare" putih Bold 44, tagline "Hadir, belajar, dan nilai anak. Semua kabar sekolah di satu tempat.", lalu indikator loading putih kecil (tombol "Mulai" di kanvas tidak dipakai karena router pindah otomatis).
2. **Login**: latar pink. Di atas: "Selamat datang di" + "SchoolCare" (putih), maskot 150px di kanan, duduk menumpuk di atas kartu. Kartu putih berisi form Email & Kata sandi dan tombol Masuk. Paling bawah ada kotak info softYellow: "Belum punya akun atau lupa sandi? Hubungi Manajemen Sekolah."
3. **Beranda Orang Tua** (`beranda_tab.dart`): judul "Hari ini, **Andi** di sekolah" (nama anak berwarna softYellow), di bawahnya tanggal + pemilih anak. Kartu kehadiran **balon chat putih** + label "Bu Sri · 07.05", pojok tergigit, emotikon besar, Tasi ngintip. Progress bar bergaris "Kehadiran November". Kartu tiket "Sekarang". Grid 4 menu glossy (Izin/Sakit orange, Aktivitas softYellow, Tugas softPink, Chat Guru putih). Pengumuman berupa **kertas tempel** softYellow.
4. **Kehadiran** (`kehadiran_tab.dart`): kartu rekap bulan berisi 5 emotikon + jumlahnya. Kalender Sen–Jum dengan emotikon per hari; hari yang belum lewat = lingkaran transparan bergaris putus-putus pink; tanggal terpilih = cincin pink. Riwayat perubahan status hari terpilih ditampilkan sebagai **balon chat** dengan label nama guru.
5. **Aktivitas Harian** (`aktivitas_harian_page.dart`): strip 5 hari (frame putih, hari terpilih softYellow), lalu daftar kartu tiket per jam pelajaran yang bisa dibuka untuk melihat foto + berita acara.
6. **Akademik** (`akademik_tab.dart`): 3 kotak statistik rata tengah (Rata-rata orange · Tugas aktif softPink · Ujian dekat orange), tab segmented putih Tugas/Ujian/Nilai/Rapor (aktif = pink), lalu daftar kartu dengan badge mapel.
7. **Guru · Jadwal** (`jadwal_page.dart`): "Halo, **Bu Sri**" (nama softYellow) + chip "Wali 7A", 3 kotak statistik orange · softPink · orange rata tengah, kartu absensi siswa pagi, lalu daftar kartu tiket. Kartu kelas yang sedang berjalan punya tombol "Absen Mengajar".
8. **Guru · Absen Mengajar** (`absensi_mengajar_page.dart` / `absensi_hadir_page.dart`): segmented Hadir/Tidak Hadir. Hadir = foto bukti + label geotag + berita acara. Tidak hadir = keterangan, unggah surat, pilihan Ada pengganti/Dibatalkan, dan dropdown guru pengganti. Tombol "Kirim Absensi".

## 6. Kondisi repo saat ini (per merge PR #2, 19 Nov 2026)

Beberapa file sudah dibuat anggota lain, jadi **ubah file yang ada, jangan bikin duplikat**:

- `lib/core/theme/app_colors.dart` sudah ada dan dipakai banyak fitur (`primary`, `background`, `surface`, `textPrimary`, `textSecondary`, `border`, `success`, `warning`, `danger`, `info`, `purple`). **Jangan hapus nama-nama ini** biar kode anggota lain tetap jalan. Ganti nilainya ke palet di atas, lalu tambahkan token baru (`pink`, `softPink`, `orange`, `softYellow`, `ink`, `inkMuted`, `inkFaint`). Pemetaannya:
  - `primary` = pink, `background` = pink, `surface` = white
  - `textPrimary` = ink, `textSecondary` = inkMuted, `border` = softPink
  - `success` = pink, `warning` = orange, `info` = softYellow, `danger` = pink, `purple` = softPink
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
