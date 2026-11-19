-- =====================================================================
-- SchoolCare · Skema awal basis data (Supabase / PostgreSQL)
--
-- Diekspor dari database Supabase yang dipakai aplikasi (19 November 2026).
-- Untuk membuat ulang database dari nol pada project Supabase baru:
--   1. Jalankan file ini di SQL Editor (atau `supabase db push`).
--   2. Deploy Edge Function supabase/functions/create-user.
--   3. (Opsional) Jalankan supabase/seed.sql untuk data dummy SD.
--
-- Isi, berurutan:
--   1. Enum            5. Foreign key       9.  Row Level Security + policy
--   2. Fungsi          6. Index             10. Bucket Storage + policy
--   3. Tabel           7. View              11. Realtime
--   4. Constraint      8. Trigger
-- =====================================================================

-- Fungsi SQL boleh merujuk tabel yang baru dibuat di bawahnya.
set check_function_bodies = false;


-- =====================================================================
-- 1. ENUM
-- =====================================================================
create type public.hari_type as enum ('senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu');
create type public.hubungan_keluarga as enum ('ayah', 'ibu', 'wali');
create type public.jenis_kelamin as enum ('L', 'P');
create type public.jenis_pengajuan as enum ('izin', 'sakit');
create type public.jenis_penilaian as enum ('tugas', 'ulangan_harian', 'uts', 'uas', 'praktik', 'lainnya');
create type public.jenis_ujian as enum ('ulangan_harian', 'uts', 'uas', 'praktik', 'lainnya');
create type public.kategori_agenda as enum ('kegiatan', 'ujian', 'libur', 'pembagian_rapor', 'lainnya');
create type public.kategori_pengumuman as enum ('umum', 'kegiatan', 'kebijakan', 'perubahan_jadwal');
create type public.semester_type as enum ('ganjil', 'genap');
create type public.status_kehadiran_guru as enum ('hadir', 'tidak_hadir');
create type public.status_kehadiran_siswa as enum ('hadir', 'terlambat', 'izin', 'sakit', 'alpa');
create type public.status_kelas as enum ('berlangsung', 'digantikan', 'dibatalkan', 'dijadwalkan_ulang', 'kosong');
create type public.status_siswa as enum ('aktif', 'lulus', 'pindah', 'keluar');
create type public.user_role as enum ('manajemen', 'guru', 'orang_tua');


-- =====================================================================
-- 2. FUNGSI
-- =====================================================================

-- ---------- dasar (dipakai sebagai default kolom / parameter) ----------

-- Tanggal hari ini menurut waktu Indonesia Barat.
CREATE OR REPLACE FUNCTION public.tanggal_hari_ini()
 RETURNS date
 LANGUAGE sql
 STABLE
AS $function$
  select (now() at time zone 'Asia/Jakarta')::date
$function$;

-- Nama hari (senin..sabtu) dari sebuah tanggal.
CREATE OR REPLACE FUNCTION public.nama_hari(p_tanggal date)
 RETURNS hari_type
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select ((array['senin','selasa','rabu','kamis','jumat','sabtu'])
          [extract(isodow from p_tanggal)::int])::public.hari_type
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end $function$;

-- ---------- peran pengguna (dipakai di RLS) ----------

-- Peran akun yang sedang login; null bila akun nonaktif.
CREATE OR REPLACE FUNCTION public.peran_saya()
 RETURNS user_role
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select role from public.profiles where id = auth.uid() and is_active
$function$;

CREATE OR REPLACE FUNCTION public.is_guru()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$ select coalesce(public.peran_saya() = 'guru', false) $function$;

CREATE OR REPLACE FUNCTION public.is_manajemen()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$ select coalesce(public.peran_saya() = 'manajemen', false) $function$;

CREATE OR REPLACE FUNCTION public.is_orang_tua()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$ select coalesce(public.peran_saya() = 'orang_tua', false) $function$;

CREATE OR REPLACE FUNCTION public.is_pengguna_aktif()
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$ select public.peran_saya() is not null $function$;

CREATE OR REPLACE FUNCTION public.is_wali_kelas(p_kelas_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_guru() and exists (
    select 1 from public.kelas where id = p_kelas_id and wali_kelas_id = auth.uid())
$function$;

-- Guru yang menjadi wali kelas atau mengajar di kelas tersebut.
CREATE OR REPLACE FUNCTION public.guru_di_kelas(p_kelas_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_guru() and (
       exists (select 1 from public.kelas where id = p_kelas_id and wali_kelas_id = auth.uid())
    or exists (select 1 from public.jadwal_pelajaran where kelas_id = p_kelas_id and guru_id = auth.uid()))
$function$;

CREATE OR REPLACE FUNCTION public.mengajar_mapel(p_kelas_id uuid, p_mapel_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_guru() and exists (
    select 1 from public.jadwal_pelajaran
    where kelas_id = p_kelas_id and mapel_id = p_mapel_id and guru_id = auth.uid())
$function$;

CREATE OR REPLACE FUNCTION public.kelas_siswa(p_siswa_id uuid)
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select kelas_id from public.siswa where id = p_siswa_id
$function$;

CREATE OR REPLACE FUNCTION public.ortu_dari_siswa(p_siswa_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_orang_tua() and exists (
    select 1 from public.orang_tua_siswa where siswa_id = p_siswa_id and orang_tua_id = auth.uid())
$function$;

CREATE OR REPLACE FUNCTION public.ortu_di_kelas(p_kelas_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_orang_tua() and exists (
    select 1 from public.orang_tua_siswa ots
    join public.siswa s on s.id = ots.siswa_id
    where ots.orang_tua_id = auth.uid() and s.kelas_id = p_kelas_id)
$function$;

CREATE OR REPLACE FUNCTION public.guru_terhubung_ortu(p_ortu_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_guru() and exists (
    select 1 from public.orang_tua_siswa ots
    join public.siswa s on s.id = ots.siswa_id
    where ots.orang_tua_id = p_ortu_id and public.guru_di_kelas(s.kelas_id))
$function$;

CREATE OR REPLACE FUNCTION public.bisa_lihat_kelas(p_kelas_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
AS $function$
  select public.is_manajemen() or public.guru_di_kelas(p_kelas_id) or public.ortu_di_kelas(p_kelas_id)
$function$;

-- ---------- akses file di Storage ----------

CREATE OR REPLACE FUNCTION public.bisa_lihat_foto_absensi(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_manajemen()
      or split_part(p_path, '/', 1) = auth.uid()::text
      or exists (select 1 from public.absensi_guru ag
                 join public.jadwal_pelajaran j on j.id = ag.jadwal_id
                 where ag.foto_url = p_path and public.bisa_lihat_kelas(j.kelas_id))
$function$;

CREATE OR REPLACE FUNCTION public.bisa_lihat_surat(p_path text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.is_manajemen()
      or split_part(p_path, '/', 1) = auth.uid()::text
      or exists (select 1 from public.pengajuan_izin pi
                 join public.siswa s on s.id = pi.siswa_id
                 where pi.lampiran_url = p_path and public.guru_di_kelas(s.kelas_id))
$function$;

-- ---------- RPC untuk aplikasi ----------

-- Aktivitas setiap jam pelajaran satu kelas pada satu tanggal (tampilan Orang Tua).
CREATE OR REPLACE FUNCTION public.get_aktivitas_harian(p_kelas_id uuid, p_tanggal date DEFAULT tanggal_hari_ini())
 RETURNS TABLE(jadwal_id uuid, jam_ke smallint, jam_mulai time without time zone, jam_selesai time without time zone, ruang text, mata_pelajaran text, guru_terjadwal text, guru_mengajar text, status_kelas text, berita_acara text, foto_url text, info_kegiatan text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select j.id, j.jam_ke, j.jam_mulai, j.jam_selesai, coalesce(j.ruang, k.ruang),
         mp.nama,
         g.nama_lengkap,
         coalesce(gp.nama_lengkap, g.nama_lengkap),
         case when ev.judul is not null then 'kegiatan'
              else coalesce(ag.status_kelas::text, 'terjadwal') end,
         ag.berita_acara,
         ag.foto_url,
         case when ev.judul is not null then 'Sedang ada kegiatan: ' || ev.judul end
  from public.jadwal_pelajaran j
  join public.kelas k           on k.id = j.kelas_id
  join public.tahun_ajaran ta   on ta.id = k.tahun_ajaran_id and j.semester = ta.semester_aktif
  join public.mata_pelajaran mp on mp.id = j.mapel_id
  join public.profiles g        on g.id = j.guru_id
  left join public.absensi_guru ag on ag.jadwal_id = j.id and ag.tanggal = p_tanggal
  left join public.profiles gp     on gp.id = ag.guru_pengganti_id
  left join lateral (
    select a.judul
    from public.agenda_sekolah a
    where a.menggantikan_pelajaran
      and p_tanggal between a.tanggal_mulai and a.tanggal_selesai
      and (a.jam_mulai is null or a.jam_selesai is null
           or (j.jam_mulai < a.jam_selesai and j.jam_selesai > a.jam_mulai))
      and (a.untuk_semua_kelas
           or exists (select 1 from public.agenda_kelas ak
                      where ak.agenda_id = a.id and ak.kelas_id = j.kelas_id))
    order by a.tanggal_mulai
    limit 1
  ) ev on true
  where j.kelas_id = p_kelas_id
    and j.hari = public.nama_hari(p_tanggal)
    and public.bisa_lihat_kelas(p_kelas_id)
  order by j.jam_ke
$function$;

-- ---------- fungsi trigger ----------

-- Membuat baris profiles setiap ada akun baru di Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.profiles (id, email, nama_lengkap, role, no_whatsapp, nip)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'nama_lengkap', split_part(new.email, '@', 1)),
    coalesce((new.raw_app_meta_data ->> 'role')::public.user_role, 'orang_tua'),
    new.raw_user_meta_data ->> 'no_whatsapp',
    new.raw_user_meta_data ->> 'nip'
  );
  return new;
end $function$;

-- Memastikan kolom tg_argv[0] berisi akun dengan peran tg_argv[1].
CREATE OR REPLACE FUNCTION public.validasi_peran()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_id uuid := (to_jsonb(new) ->> tg_argv[0])::uuid;
begin
  if v_id is not null and not exists (
      select 1 from public.profiles where id = v_id and role = tg_argv[1]::public.user_role) then
    raise exception 'Kolom % harus berisi akun dengan peran %', tg_argv[0], tg_argv[1];
  end if;
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.absensi_siswa_sebelum_simpan()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    new.kelas_id     := coalesce(new.kelas_id, (select kelas_id from public.siswa where id = new.siswa_id));
    new.dicatat_oleh := coalesce(auth.uid(), new.dicatat_oleh);
  end if;
  new.diubah_oleh := coalesce(auth.uid(), new.diubah_oleh);
  new.updated_at  := now();
  return new;
end $function$;

CREATE OR REPLACE FUNCTION public.catat_riwayat_absensi_siswa()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT'
     or new.status is distinct from old.status
     or new.keterangan is distinct from old.keterangan then
    insert into public.riwayat_absensi_siswa (absensi_siswa_id, status_lama, status_baru, keterangan, diubah_oleh)
    values (new.id,
            case when tg_op = 'UPDATE' then old.status end,
            new.status, new.keterangan, new.diubah_oleh);
  end if;
  return null;
end $function$;

-- Pengajuan izin/sakit orang tua langsung mengubah absensi anak (hari Minggu dilewati).
CREATE OR REPLACE FUNCTION public.terapkan_pengajuan_izin()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_kelas uuid;
begin
  select kelas_id into v_kelas from public.siswa where id = new.siswa_id;
  if v_kelas is null then
    raise exception 'Siswa belum terdaftar di kelas mana pun';
  end if;

  insert into public.absensi_siswa (siswa_id, kelas_id, tanggal, status, keterangan, pengajuan_izin_id)
  select new.siswa_id, v_kelas, d::date,
         new.jenis::text::public.status_kehadiran_siswa,
         'Diajukan orang tua: ' || new.alasan,
         new.id
  from generate_series(new.tanggal_mulai::timestamp, new.tanggal_selesai::timestamp, interval '1 day') d
  where extract(isodow from d) < 7                       -- lewati hari Minggu
  on conflict (siswa_id, tanggal) do update
    set status            = excluded.status,
        keterangan        = excluded.keterangan,
        pengajuan_izin_id = excluded.pengajuan_izin_id;
  return new;
end $function$;

-- Tanggal absensi guru harus sesuai dengan hari pada jadwalnya.
CREATE OR REPLACE FUNCTION public.validasi_absensi_guru()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_hari public.hari_type;
begin
  select hari into v_hari from public.jadwal_pelajaran where id = new.jadwal_id;
  if v_hari is distinct from public.nama_hari(new.tanggal) then
    raise exception 'Tanggal % tidak sesuai dengan hari jadwal (%)', new.tanggal, v_hari;
  end if;
  return new;
end $function$;


-- =====================================================================
-- 3. TABEL
-- =====================================================================

-- ---------- pengguna & data master ----------
create table public.profiles (
  id uuid not null,
  nama_lengkap text not null,
  email text not null,
  no_whatsapp text,
  role user_role not null,
  nip text,
  foto_url text,
  is_active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.tahun_ajaran (
  id uuid default gen_random_uuid() not null,
  nama text not null,
  semester_aktif semester_type default 'ganjil'::semester_type not null,
  tanggal_mulai date not null,
  tanggal_selesai date not null,
  is_active boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table public.kelas (
  id uuid default gen_random_uuid() not null,
  tahun_ajaran_id uuid not null,
  nama_kelas text not null,
  tingkat smallint not null,
  ruang text,
  wali_kelas_id uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.siswa (
  id uuid default gen_random_uuid() not null,
  nis text not null,
  nisn text,
  nama_lengkap text not null,
  jenis_kelamin jenis_kelamin not null,
  tanggal_lahir date,
  alamat text,
  foto_url text,
  kelas_id uuid,
  status status_siswa default 'aktif'::status_siswa not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.orang_tua_siswa (
  orang_tua_id uuid not null,
  siswa_id uuid not null,
  hubungan hubungan_keluarga default 'wali'::hubungan_keluarga not null,
  created_at timestamp with time zone default now() not null
);

create table public.mata_pelajaran (
  id uuid default gen_random_uuid() not null,
  kode text not null,
  nama text not null,
  created_at timestamp with time zone default now() not null
);

create table public.jadwal_pelajaran (
  id uuid default gen_random_uuid() not null,
  kelas_id uuid not null,
  mapel_id uuid not null,
  guru_id uuid not null,
  semester semester_type not null,
  hari hari_type not null,
  jam_ke smallint not null,
  jam_mulai time without time zone not null,
  jam_selesai time without time zone not null,
  ruang text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

-- ---------- absensi ----------
create table public.absensi_guru (
  id uuid default gen_random_uuid() not null,
  jadwal_id uuid not null,
  tanggal date default tanggal_hari_ini() not null,
  guru_id uuid default auth.uid() not null,
  status_kehadiran status_kehadiran_guru not null,
  foto_url text,
  latitude double precision,
  longitude double precision,
  akurasi_meter real,
  foto_diambil_pada timestamp with time zone,
  berita_acara text,
  keterangan_tidak_hadir text,
  surat_url text,
  guru_pengganti_id uuid,
  jadwal_ulang_pada timestamp with time zone,
  status_kelas status_kelas not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.pengajuan_izin (
  id uuid default gen_random_uuid() not null,
  siswa_id uuid not null,
  diajukan_oleh uuid default auth.uid() not null,
  jenis jenis_pengajuan not null,
  tanggal_mulai date not null,
  tanggal_selesai date not null,
  alasan text not null,
  lampiran_url text,
  created_at timestamp with time zone default now() not null
);

create table public.absensi_siswa (
  id uuid default gen_random_uuid() not null,
  siswa_id uuid not null,
  kelas_id uuid not null,
  tanggal date default tanggal_hari_ini() not null,
  status status_kehadiran_siswa not null,
  keterangan text,
  pengajuan_izin_id uuid,
  dicatat_oleh uuid,
  diubah_oleh uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.riwayat_absensi_siswa (
  id bigint generated always as identity not null,
  absensi_siswa_id uuid not null,
  status_lama status_kehadiran_siswa,
  status_baru status_kehadiran_siswa not null,
  keterangan text,
  diubah_oleh uuid,
  diubah_pada timestamp with time zone default now() not null
);

-- ---------- akademik ----------
create table public.tugas (
  id uuid default gen_random_uuid() not null,
  kelas_id uuid not null,
  mapel_id uuid not null,
  guru_id uuid default auth.uid() not null,
  judul text not null,
  deskripsi text,
  tenggat timestamp with time zone not null,
  lampiran_url text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.ujian (
  id uuid default gen_random_uuid() not null,
  kelas_id uuid not null,
  mapel_id uuid not null,
  guru_id uuid default auth.uid() not null,
  jenis jenis_ujian not null,
  judul text not null,
  materi text,
  tanggal date not null,
  jam_mulai time without time zone,
  jam_selesai time without time zone,
  ruang text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.nilai (
  id uuid default gen_random_uuid() not null,
  siswa_id uuid not null,
  mapel_id uuid not null,
  guru_id uuid default auth.uid() not null,
  tahun_ajaran_id uuid not null,
  semester semester_type not null,
  jenis jenis_penilaian not null,
  tugas_id uuid,
  ujian_id uuid,
  judul text not null,
  nilai numeric(5,2) not null,
  catatan text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.rapor (
  id uuid default gen_random_uuid() not null,
  siswa_id uuid not null,
  kelas_id uuid not null,
  tahun_ajaran_id uuid not null,
  semester semester_type not null,
  file_url text,
  catatan_wali_kelas text,
  is_published boolean default false not null,
  diterbitkan_pada timestamp with time zone,
  diterbitkan_oleh uuid,
  diambil_pada timestamp with time zone,
  diambil_oleh_nama text,
  dikonfirmasi_oleh uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.rapor_nilai (
  rapor_id uuid not null,
  mapel_id uuid not null,
  nilai_akhir numeric(5,2),
  predikat text,
  deskripsi text
);

-- ---------- informasi sekolah ----------
create table public.agenda_sekolah (
  id uuid default gen_random_uuid() not null,
  judul text not null,
  deskripsi text,
  kategori kategori_agenda default 'kegiatan'::kategori_agenda not null,
  tanggal_mulai date not null,
  tanggal_selesai date not null,
  jam_mulai time without time zone,
  jam_selesai time without time zone,
  lokasi text,
  ketentuan_pakaian text,
  perlengkapan text,
  ketentuan_lain text,
  menggantikan_pelajaran boolean default false not null,
  untuk_semua_kelas boolean default true not null,
  dibuat_oleh uuid default auth.uid(),
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.agenda_kelas (
  agenda_id uuid not null,
  kelas_id uuid not null
);

create table public.pengumuman (
  id uuid default gen_random_uuid() not null,
  judul text not null,
  isi text not null,
  kategori kategori_pengumuman default 'umum'::kategori_pengumuman not null,
  lampiran_url text,
  agenda_id uuid,
  is_published boolean default true not null,
  dipublikasikan_pada timestamp with time zone default now() not null,
  dibuat_oleh uuid default auth.uid(),
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);


-- =====================================================================
-- 4. CONSTRAINT (primary key, unique, check)
-- =====================================================================
alter table public.profiles add constraint profiles_pkey PRIMARY KEY (id);
alter table public.profiles add constraint profiles_email_key UNIQUE (email);
alter table public.profiles add constraint profiles_nip_key UNIQUE (nip);
alter table public.profiles add constraint profiles_no_whatsapp_check CHECK ((no_whatsapp ~ '^62[0-9]{8,13}$'::text));

alter table public.tahun_ajaran add constraint tahun_ajaran_pkey PRIMARY KEY (id);
alter table public.tahun_ajaran add constraint tahun_ajaran_nama_key UNIQUE (nama);
alter table public.tahun_ajaran add constraint tahun_ajaran_check CHECK ((tanggal_selesai > tanggal_mulai));

alter table public.kelas add constraint kelas_pkey PRIMARY KEY (id);
alter table public.kelas add constraint kelas_tahun_ajaran_id_nama_kelas_key UNIQUE (tahun_ajaran_id, nama_kelas);
alter table public.kelas add constraint kelas_tahun_ajaran_id_wali_kelas_id_key UNIQUE (tahun_ajaran_id, wali_kelas_id);
alter table public.kelas add constraint kelas_tingkat_check CHECK (((tingkat >= 1) AND (tingkat <= 12)));

alter table public.siswa add constraint siswa_pkey PRIMARY KEY (id);
alter table public.siswa add constraint siswa_nis_key UNIQUE (nis);
alter table public.siswa add constraint siswa_nisn_key UNIQUE (nisn);

alter table public.orang_tua_siswa add constraint orang_tua_siswa_pkey PRIMARY KEY (orang_tua_id, siswa_id);

alter table public.mata_pelajaran add constraint mata_pelajaran_pkey PRIMARY KEY (id);
alter table public.mata_pelajaran add constraint mata_pelajaran_kode_key UNIQUE (kode);

alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_pkey PRIMARY KEY (id);
alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_kelas_id_semester_hari_jam_ke_key UNIQUE (kelas_id, semester, hari, jam_ke);
alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_check CHECK ((jam_selesai > jam_mulai));
alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_jam_ke_check CHECK (((jam_ke >= 1) AND (jam_ke <= 15)));

alter table public.absensi_guru add constraint absensi_guru_pkey PRIMARY KEY (id);
alter table public.absensi_guru add constraint absensi_guru_jadwal_id_tanggal_key UNIQUE (jadwal_id, tanggal);
alter table public.absensi_guru add constraint absensi_guru_latitude_check CHECK (((latitude >= ('-90'::integer)::double precision) AND (latitude <= (90)::double precision)));
alter table public.absensi_guru add constraint absensi_guru_longitude_check CHECK (((longitude >= ('-180'::integer)::double precision) AND (longitude <= (180)::double precision)));
-- Foto, lokasi, dan waktu foto wajib diisi bila guru hadir.
alter table public.absensi_guru add constraint absensi_guru_bukti_saat_hadir CHECK (((status_kehadiran <> 'hadir'::status_kehadiran_guru) OR ((foto_url IS NOT NULL) AND (latitude IS NOT NULL) AND (longitude IS NOT NULL) AND (foto_diambil_pada IS NOT NULL))));
-- Hadir → kelas berlangsung tanpa pengganti; tidak hadir → wajib keterangan, digantikan ⇔ ada pengganti.
alter table public.absensi_guru add constraint chk_status_absensi_guru CHECK ((((status_kehadiran = 'hadir'::status_kehadiran_guru) AND (status_kelas = 'berlangsung'::status_kelas) AND (guru_pengganti_id IS NULL)) OR ((status_kehadiran = 'tidak_hadir'::status_kehadiran_guru) AND (status_kelas <> 'berlangsung'::status_kelas) AND (keterangan_tidak_hadir IS NOT NULL) AND ((status_kelas = 'digantikan'::status_kelas) = (guru_pengganti_id IS NOT NULL)))));

alter table public.pengajuan_izin add constraint pengajuan_izin_pkey PRIMARY KEY (id);
alter table public.pengajuan_izin add constraint pengajuan_izin_check CHECK ((tanggal_selesai >= tanggal_mulai));

alter table public.absensi_siswa add constraint absensi_siswa_pkey PRIMARY KEY (id);
alter table public.absensi_siswa add constraint absensi_siswa_siswa_id_tanggal_key UNIQUE (siswa_id, tanggal);

alter table public.riwayat_absensi_siswa add constraint riwayat_absensi_siswa_pkey PRIMARY KEY (id);

alter table public.tugas add constraint tugas_pkey PRIMARY KEY (id);

alter table public.ujian add constraint ujian_pkey PRIMARY KEY (id);

alter table public.nilai add constraint nilai_pkey PRIMARY KEY (id);
alter table public.nilai add constraint nilai_nilai_check CHECK (((nilai >= (0)::numeric) AND (nilai <= (100)::numeric)));

alter table public.rapor add constraint rapor_pkey PRIMARY KEY (id);
alter table public.rapor add constraint rapor_siswa_id_tahun_ajaran_id_semester_key UNIQUE (siswa_id, tahun_ajaran_id, semester);
alter table public.rapor add constraint rapor_check CHECK (((diambil_pada IS NULL) OR is_published));

alter table public.rapor_nilai add constraint rapor_nilai_pkey PRIMARY KEY (rapor_id, mapel_id);
alter table public.rapor_nilai add constraint rapor_nilai_nilai_akhir_check CHECK (((nilai_akhir >= (0)::numeric) AND (nilai_akhir <= (100)::numeric)));
alter table public.rapor_nilai add constraint rapor_nilai_predikat_check CHECK ((predikat = ANY (ARRAY['A'::text, 'B'::text, 'C'::text, 'D'::text, 'E'::text])));

alter table public.agenda_sekolah add constraint agenda_sekolah_pkey PRIMARY KEY (id);
alter table public.agenda_sekolah add constraint agenda_sekolah_check CHECK ((tanggal_selesai >= tanggal_mulai));

alter table public.agenda_kelas add constraint agenda_kelas_pkey PRIMARY KEY (agenda_id, kelas_id);

alter table public.pengumuman add constraint pengumuman_pkey PRIMARY KEY (id);


-- =====================================================================
-- 5. FOREIGN KEY
-- =====================================================================
alter table public.profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table public.kelas add constraint kelas_tahun_ajaran_id_fkey FOREIGN KEY (tahun_ajaran_id) REFERENCES public.tahun_ajaran(id) ON DELETE RESTRICT;
alter table public.kelas add constraint kelas_wali_kelas_id_fkey FOREIGN KEY (wali_kelas_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.siswa add constraint siswa_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE SET NULL;

alter table public.orang_tua_siswa add constraint orang_tua_siswa_orang_tua_id_fkey FOREIGN KEY (orang_tua_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
alter table public.orang_tua_siswa add constraint orang_tua_siswa_siswa_id_fkey FOREIGN KEY (siswa_id) REFERENCES public.siswa(id) ON DELETE CASCADE;

alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE CASCADE;
alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_mapel_id_fkey FOREIGN KEY (mapel_id) REFERENCES public.mata_pelajaran(id) ON DELETE RESTRICT;
alter table public.jadwal_pelajaran add constraint jadwal_pelajaran_guru_id_fkey FOREIGN KEY (guru_id) REFERENCES public.profiles(id) ON DELETE RESTRICT;

alter table public.absensi_guru add constraint absensi_guru_jadwal_id_fkey FOREIGN KEY (jadwal_id) REFERENCES public.jadwal_pelajaran(id) ON DELETE CASCADE;
alter table public.absensi_guru add constraint absensi_guru_guru_id_fkey FOREIGN KEY (guru_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
alter table public.absensi_guru add constraint absensi_guru_guru_pengganti_id_fkey FOREIGN KEY (guru_pengganti_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.pengajuan_izin add constraint pengajuan_izin_siswa_id_fkey FOREIGN KEY (siswa_id) REFERENCES public.siswa(id) ON DELETE CASCADE;
alter table public.pengajuan_izin add constraint pengajuan_izin_diajukan_oleh_fkey FOREIGN KEY (diajukan_oleh) REFERENCES public.profiles(id) ON DELETE CASCADE;

alter table public.absensi_siswa add constraint absensi_siswa_siswa_id_fkey FOREIGN KEY (siswa_id) REFERENCES public.siswa(id) ON DELETE CASCADE;
alter table public.absensi_siswa add constraint absensi_siswa_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE CASCADE;
alter table public.absensi_siswa add constraint absensi_siswa_pengajuan_izin_id_fkey FOREIGN KEY (pengajuan_izin_id) REFERENCES public.pengajuan_izin(id) ON DELETE SET NULL;
alter table public.absensi_siswa add constraint absensi_siswa_dicatat_oleh_fkey FOREIGN KEY (dicatat_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;
alter table public.absensi_siswa add constraint absensi_siswa_diubah_oleh_fkey FOREIGN KEY (diubah_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.riwayat_absensi_siswa add constraint riwayat_absensi_siswa_absensi_siswa_id_fkey FOREIGN KEY (absensi_siswa_id) REFERENCES public.absensi_siswa(id) ON DELETE CASCADE;
alter table public.riwayat_absensi_siswa add constraint riwayat_absensi_siswa_diubah_oleh_fkey FOREIGN KEY (diubah_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.tugas add constraint tugas_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE CASCADE;
alter table public.tugas add constraint tugas_mapel_id_fkey FOREIGN KEY (mapel_id) REFERENCES public.mata_pelajaran(id) ON DELETE RESTRICT;
alter table public.tugas add constraint tugas_guru_id_fkey FOREIGN KEY (guru_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

alter table public.ujian add constraint ujian_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE CASCADE;
alter table public.ujian add constraint ujian_mapel_id_fkey FOREIGN KEY (mapel_id) REFERENCES public.mata_pelajaran(id) ON DELETE RESTRICT;
alter table public.ujian add constraint ujian_guru_id_fkey FOREIGN KEY (guru_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

alter table public.nilai add constraint nilai_siswa_id_fkey FOREIGN KEY (siswa_id) REFERENCES public.siswa(id) ON DELETE CASCADE;
alter table public.nilai add constraint nilai_mapel_id_fkey FOREIGN KEY (mapel_id) REFERENCES public.mata_pelajaran(id) ON DELETE RESTRICT;
alter table public.nilai add constraint nilai_guru_id_fkey FOREIGN KEY (guru_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
alter table public.nilai add constraint nilai_tahun_ajaran_id_fkey FOREIGN KEY (tahun_ajaran_id) REFERENCES public.tahun_ajaran(id) ON DELETE RESTRICT;
alter table public.nilai add constraint nilai_tugas_id_fkey FOREIGN KEY (tugas_id) REFERENCES public.tugas(id) ON DELETE SET NULL;
alter table public.nilai add constraint nilai_ujian_id_fkey FOREIGN KEY (ujian_id) REFERENCES public.ujian(id) ON DELETE SET NULL;

alter table public.rapor add constraint rapor_siswa_id_fkey FOREIGN KEY (siswa_id) REFERENCES public.siswa(id) ON DELETE CASCADE;
alter table public.rapor add constraint rapor_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE RESTRICT;
alter table public.rapor add constraint rapor_tahun_ajaran_id_fkey FOREIGN KEY (tahun_ajaran_id) REFERENCES public.tahun_ajaran(id) ON DELETE RESTRICT;
alter table public.rapor add constraint rapor_diterbitkan_oleh_fkey FOREIGN KEY (diterbitkan_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;
alter table public.rapor add constraint rapor_dikonfirmasi_oleh_fkey FOREIGN KEY (dikonfirmasi_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.rapor_nilai add constraint rapor_nilai_rapor_id_fkey FOREIGN KEY (rapor_id) REFERENCES public.rapor(id) ON DELETE CASCADE;
alter table public.rapor_nilai add constraint rapor_nilai_mapel_id_fkey FOREIGN KEY (mapel_id) REFERENCES public.mata_pelajaran(id) ON DELETE RESTRICT;

alter table public.agenda_sekolah add constraint agenda_sekolah_dibuat_oleh_fkey FOREIGN KEY (dibuat_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;

alter table public.agenda_kelas add constraint agenda_kelas_agenda_id_fkey FOREIGN KEY (agenda_id) REFERENCES public.agenda_sekolah(id) ON DELETE CASCADE;
alter table public.agenda_kelas add constraint agenda_kelas_kelas_id_fkey FOREIGN KEY (kelas_id) REFERENCES public.kelas(id) ON DELETE CASCADE;

alter table public.pengumuman add constraint pengumuman_agenda_id_fkey FOREIGN KEY (agenda_id) REFERENCES public.agenda_sekolah(id) ON DELETE SET NULL;
alter table public.pengumuman add constraint pengumuman_dibuat_oleh_fkey FOREIGN KEY (dibuat_oleh) REFERENCES public.profiles(id) ON DELETE SET NULL;


-- =====================================================================
-- 6. INDEX
-- =====================================================================
CREATE INDEX idx_kelas_wali ON public.kelas USING btree (wali_kelas_id);
CREATE INDEX idx_siswa_kelas ON public.siswa USING btree (kelas_id);
CREATE INDEX idx_ortu_siswa_siswa ON public.orang_tua_siswa USING btree (siswa_id);
CREATE INDEX idx_jadwal_guru_hari ON public.jadwal_pelajaran USING btree (guru_id, hari);
CREATE INDEX idx_jadwal_mapel ON public.jadwal_pelajaran USING btree (mapel_id);
CREATE INDEX idx_absensi_guru_guru ON public.absensi_guru USING btree (guru_id, tanggal);
CREATE INDEX idx_absensi_guru_tanggal ON public.absensi_guru USING btree (tanggal);
CREATE INDEX idx_absensi_siswa_kelas ON public.absensi_siswa USING btree (kelas_id, tanggal);
CREATE INDEX idx_riwayat_absensi ON public.riwayat_absensi_siswa USING btree (absensi_siswa_id, diubah_pada);
CREATE INDEX idx_pengajuan_siswa ON public.pengajuan_izin USING btree (siswa_id, tanggal_mulai);
CREATE INDEX idx_tugas_kelas ON public.tugas USING btree (kelas_id, tenggat);
CREATE INDEX idx_ujian_kelas ON public.ujian USING btree (kelas_id, tanggal);
CREATE INDEX idx_nilai_siswa_mapel ON public.nilai USING btree (siswa_id, mapel_id);
CREATE INDEX idx_rapor_kelas ON public.rapor USING btree (kelas_id);
CREATE INDEX idx_agenda_tanggal ON public.agenda_sekolah USING btree (tanggal_mulai, tanggal_selesai);
CREATE INDEX idx_agenda_kelas_kelas ON public.agenda_kelas USING btree (kelas_id);
CREATE INDEX idx_pengumuman_tanggal ON public.pengumuman USING btree (dipublikasikan_pada DESC);

-- Hanya boleh ada satu tahun ajaran aktif.
CREATE UNIQUE INDEX uq_tahun_ajaran_aktif ON public.tahun_ajaran USING btree (is_active) WHERE is_active;
-- Satu nilai per siswa untuk setiap tugas / ujian.
CREATE UNIQUE INDEX uq_nilai_per_tugas ON public.nilai USING btree (siswa_id, tugas_id) WHERE (tugas_id IS NOT NULL);
CREATE UNIQUE INDEX uq_nilai_per_ujian ON public.nilai USING btree (siswa_id, ujian_id) WHERE (ujian_id IS NOT NULL);


-- =====================================================================
-- 7. VIEW (security_invoker = RLS tabel asal tetap berlaku)
-- =====================================================================

-- Guru yang mengajar / menjadi wali di setiap kelas (kontak untuk orang tua).
create view public.v_kontak_guru_kelas with (security_invoker=true) as
 WITH pengajar AS (
         SELECT j.kelas_id,
            j.guru_id,
            mp.nama AS mapel
           FROM (jadwal_pelajaran j
             JOIN mata_pelajaran mp ON ((mp.id = j.mapel_id)))
        UNION
         SELECT k_1.id,
            k_1.wali_kelas_id,
            NULL::text
           FROM kelas k_1
          WHERE (k_1.wali_kelas_id IS NOT NULL)
        )
 SELECT pg.kelas_id,
    p.id AS guru_id,
    p.nama_lengkap,
    p.no_whatsapp,
    string_agg(DISTINCT pg.mapel, ', '::text) AS mata_pelajaran,
    bool_or((k.wali_kelas_id = p.id)) AS is_wali_kelas
   FROM ((pengajar pg
     JOIN profiles p ON (((p.id = pg.guru_id) AND p.is_active)))
     JOIN kelas k ON ((k.id = pg.kelas_id)))
  GROUP BY pg.kelas_id, p.id, p.nama_lengkap, p.no_whatsapp;

-- Absensi guru lengkap dengan kelas, mapel, dan nama guru (laporan Pihak Sekolah).
create view public.v_laporan_absensi_guru with (security_invoker=true) as
 SELECT ag.id,
    ag.tanggal,
    j.hari,
    j.jam_ke,
    j.jam_mulai,
    j.jam_selesai,
    k.nama_kelas,
    mp.nama AS mata_pelajaran,
    g.nama_lengkap AS guru,
    ag.status_kehadiran,
    ag.status_kelas,
    gp.nama_lengkap AS guru_pengganti,
    ag.foto_url,
    ag.latitude,
    ag.longitude,
    ag.foto_diambil_pada,
    ag.berita_acara,
    ag.keterangan_tidak_hadir,
    ag.surat_url
   FROM (((((absensi_guru ag
     JOIN jadwal_pelajaran j ON ((j.id = ag.jadwal_id)))
     JOIN kelas k ON ((k.id = j.kelas_id)))
     JOIN mata_pelajaran mp ON ((mp.id = j.mapel_id)))
     JOIN profiles g ON ((g.id = ag.guru_id)))
     LEFT JOIN profiles gp ON ((gp.id = ag.guru_pengganti_id)));

-- Jumlah tiap status kehadiran per siswa per bulan.
create view public.v_rekap_kehadiran_siswa with (security_invoker=true) as
 SELECT a.siswa_id,
    s.nama_lengkap,
    a.kelas_id,
    (date_trunc('month'::text, (a.tanggal)::timestamp with time zone))::date AS bulan,
    count(*) FILTER (WHERE (a.status = 'hadir'::status_kehadiran_siswa)) AS hadir,
    count(*) FILTER (WHERE (a.status = 'terlambat'::status_kehadiran_siswa)) AS terlambat,
    count(*) FILTER (WHERE (a.status = 'izin'::status_kehadiran_siswa)) AS izin,
    count(*) FILTER (WHERE (a.status = 'sakit'::status_kehadiran_siswa)) AS sakit,
    count(*) FILTER (WHERE (a.status = 'alpa'::status_kehadiran_siswa)) AS alpa
   FROM (absensi_siswa a
     JOIN siswa s ON ((s.id = a.siswa_id)))
  GROUP BY a.siswa_id, s.nama_lengkap, a.kelas_id, (date_trunc('month'::text, (a.tanggal)::timestamp with time zone));


-- =====================================================================
-- 8. TRIGGER
-- =====================================================================
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- validasi peran
CREATE TRIGGER trg_kelas_wali_harus_guru BEFORE INSERT OR UPDATE OF wali_kelas_id ON public.kelas FOR EACH ROW EXECUTE FUNCTION validasi_peran('wali_kelas_id', 'guru');
CREATE TRIGGER trg_ortu_siswa_harus_ortu BEFORE INSERT OR UPDATE OF orang_tua_id ON public.orang_tua_siswa FOR EACH ROW EXECUTE FUNCTION validasi_peran('orang_tua_id', 'orang_tua');
CREATE TRIGGER trg_jadwal_guru_harus_guru BEFORE INSERT OR UPDATE OF guru_id ON public.jadwal_pelajaran FOR EACH ROW EXECUTE FUNCTION validasi_peran('guru_id', 'guru');
CREATE TRIGGER trg_absensi_guru_pengganti BEFORE INSERT OR UPDATE OF guru_pengganti_id ON public.absensi_guru FOR EACH ROW EXECUTE FUNCTION validasi_peran('guru_pengganti_id', 'guru');

-- absensi
CREATE TRIGGER trg_absensi_guru_validasi BEFORE INSERT OR UPDATE OF jadwal_id, tanggal ON public.absensi_guru FOR EACH ROW EXECUTE FUNCTION validasi_absensi_guru();
CREATE TRIGGER trg_absensi_siswa_sebelum_simpan BEFORE INSERT OR UPDATE ON public.absensi_siswa FOR EACH ROW EXECUTE FUNCTION absensi_siswa_sebelum_simpan();
CREATE TRIGGER trg_absensi_siswa_riwayat AFTER INSERT OR UPDATE ON public.absensi_siswa FOR EACH ROW EXECUTE FUNCTION catat_riwayat_absensi_siswa();
CREATE TRIGGER trg_pengajuan_izin_terapkan AFTER INSERT ON public.pengajuan_izin FOR EACH ROW EXECUTE FUNCTION terapkan_pengajuan_izin();

-- updated_at
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_kelas_updated_at BEFORE UPDATE ON public.kelas FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_siswa_updated_at BEFORE UPDATE ON public.siswa FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_jadwal_pelajaran_updated_at BEFORE UPDATE ON public.jadwal_pelajaran FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_absensi_guru_updated_at BEFORE UPDATE ON public.absensi_guru FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_tugas_updated_at BEFORE UPDATE ON public.tugas FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_ujian_updated_at BEFORE UPDATE ON public.ujian FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_nilai_updated_at BEFORE UPDATE ON public.nilai FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_rapor_updated_at BEFORE UPDATE ON public.rapor FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_agenda_sekolah_updated_at BEFORE UPDATE ON public.agenda_sekolah FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_pengumuman_updated_at BEFORE UPDATE ON public.pengumuman FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =====================================================================
-- 9. ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.tahun_ajaran enable row level security;
alter table public.kelas enable row level security;
alter table public.siswa enable row level security;
alter table public.orang_tua_siswa enable row level security;
alter table public.mata_pelajaran enable row level security;
alter table public.jadwal_pelajaran enable row level security;
alter table public.absensi_guru enable row level security;
alter table public.pengajuan_izin enable row level security;
alter table public.absensi_siswa enable row level security;
alter table public.riwayat_absensi_siswa enable row level security;
alter table public.tugas enable row level security;
alter table public.ujian enable row level security;
alter table public.nilai enable row level security;
alter table public.rapor enable row level security;
alter table public.rapor_nilai enable row level security;
alter table public.agenda_sekolah enable row level security;
alter table public.agenda_kelas enable row level security;
alter table public.pengumuman enable row level security;

-- ---------- profiles ----------
create policy profiles_select on public.profiles as PERMISSIVE for SELECT to authenticated
  using (((id = auth.uid()) OR is_manajemen() OR (is_pengguna_aktif() AND (role = ANY (ARRAY['guru'::user_role, 'manajemen'::user_role])) AND is_active) OR ((role = 'orang_tua'::user_role) AND guru_terhubung_ortu(id))));
create policy profiles_kelola on public.profiles as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- tahun_ajaran ----------
create policy tahun_ajaran_select on public.tahun_ajaran as PERMISSIVE for SELECT to authenticated
  using (is_pengguna_aktif());
create policy tahun_ajaran_kelola on public.tahun_ajaran as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- kelas ----------
create policy kelas_select on public.kelas as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR is_guru() OR ortu_di_kelas(id)));
create policy kelas_kelola on public.kelas as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- siswa ----------
create policy siswa_select on public.siswa as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR guru_di_kelas(kelas_id) OR ortu_dari_siswa(id)));
create policy siswa_kelola on public.siswa as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- orang_tua_siswa ----------
create policy ortu_siswa_select on public.orang_tua_siswa as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR ((orang_tua_id = auth.uid()) AND is_orang_tua()) OR guru_di_kelas(kelas_siswa(siswa_id))));
create policy ortu_siswa_kelola on public.orang_tua_siswa as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- mata_pelajaran ----------
create policy mata_pelajaran_select on public.mata_pelajaran as PERMISSIVE for SELECT to authenticated
  using (is_pengguna_aktif());
create policy mata_pelajaran_kelola on public.mata_pelajaran as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- jadwal_pelajaran ----------
create policy jadwal_select on public.jadwal_pelajaran as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR is_guru() OR ortu_di_kelas(kelas_id)));
create policy jadwal_kelola on public.jadwal_pelajaran as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- absensi_guru ----------
create policy absensi_guru_select on public.absensi_guru as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR (guru_id = auth.uid()) OR (guru_pengganti_id = auth.uid())));
create policy absensi_guru_insert on public.absensi_guru as PERMISSIVE for INSERT to authenticated
  with check ((is_guru() AND (guru_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM jadwal_pelajaran j
  WHERE ((j.id = absensi_guru.jadwal_id) AND (j.guru_id = auth.uid()))))));
create policy absensi_guru_update on public.absensi_guru as PERMISSIVE for UPDATE to authenticated
  using ((is_guru() AND (guru_id = auth.uid()) AND (tanggal = tanggal_hari_ini())))
  with check ((guru_id = auth.uid()));
create policy absensi_guru_manajemen on public.absensi_guru as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- pengajuan_izin ----------
create policy izin_select on public.pengajuan_izin as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR ortu_dari_siswa(siswa_id) OR guru_di_kelas(kelas_siswa(siswa_id))));
create policy izin_insert on public.pengajuan_izin as PERMISSIVE for INSERT to authenticated
  with check ((ortu_dari_siswa(siswa_id) AND (diajukan_oleh = auth.uid())));

-- ---------- absensi_siswa ----------
create policy absensi_siswa_select on public.absensi_siswa as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR guru_di_kelas(kelas_id) OR ortu_dari_siswa(siswa_id)));
create policy absensi_siswa_insert on public.absensi_siswa as PERMISSIVE for INSERT to authenticated
  with check ((is_wali_kelas(kelas_id) OR is_manajemen()));
create policy absensi_siswa_update on public.absensi_siswa as PERMISSIVE for UPDATE to authenticated
  using ((guru_di_kelas(kelas_id) OR is_manajemen()))
  with check ((guru_di_kelas(kelas_id) OR is_manajemen()));
create policy absensi_siswa_delete on public.absensi_siswa as PERMISSIVE for DELETE to authenticated
  using (is_manajemen());

-- ---------- riwayat_absensi_siswa (diisi trigger) ----------
create policy riwayat_select on public.riwayat_absensi_siswa as PERMISSIVE for SELECT to authenticated
  using ((EXISTS ( SELECT 1
   FROM absensi_siswa a
  WHERE (a.id = riwayat_absensi_siswa.absensi_siswa_id))));

-- ---------- tugas ----------
create policy tugas_select on public.tugas as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR is_guru() OR ortu_di_kelas(kelas_id)));
create policy tugas_insert on public.tugas as PERMISSIVE for INSERT to authenticated
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_id, mapel_id)));
create policy tugas_update on public.tugas as PERMISSIVE for UPDATE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()))
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_id, mapel_id)));
create policy tugas_delete on public.tugas as PERMISSIVE for DELETE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()));
create policy tugas_manajemen on public.tugas as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- ujian ----------
create policy ujian_select on public.ujian as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR is_guru() OR ortu_di_kelas(kelas_id)));
create policy ujian_insert on public.ujian as PERMISSIVE for INSERT to authenticated
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_id, mapel_id)));
create policy ujian_update on public.ujian as PERMISSIVE for UPDATE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()))
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_id, mapel_id)));
create policy ujian_delete on public.ujian as PERMISSIVE for DELETE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()));
create policy ujian_manajemen on public.ujian as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- nilai ----------
create policy nilai_select on public.nilai as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR ((guru_id = auth.uid()) AND is_guru()) OR is_wali_kelas(kelas_siswa(siswa_id)) OR ortu_dari_siswa(siswa_id)));
create policy nilai_insert on public.nilai as PERMISSIVE for INSERT to authenticated
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_siswa(siswa_id), mapel_id)));
create policy nilai_update on public.nilai as PERMISSIVE for UPDATE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()))
  with check (((guru_id = auth.uid()) AND mengajar_mapel(kelas_siswa(siswa_id), mapel_id)));
create policy nilai_delete on public.nilai as PERMISSIVE for DELETE to authenticated
  using (((guru_id = auth.uid()) AND is_guru()));
create policy nilai_manajemen on public.nilai as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- rapor (orang tua melihat setelah terbit DAN diambil) ----------
create policy rapor_select on public.rapor as PERMISSIVE for SELECT to authenticated
  using ((is_manajemen() OR is_wali_kelas(kelas_id) OR (ortu_dari_siswa(siswa_id) AND is_published AND (diambil_pada IS NOT NULL))));
create policy rapor_kelola on public.rapor as PERMISSIVE for ALL to authenticated
  using ((is_wali_kelas(kelas_id) OR is_manajemen()))
  with check ((is_wali_kelas(kelas_id) OR is_manajemen()));

-- ---------- rapor_nilai ----------
create policy rapor_nilai_select on public.rapor_nilai as PERMISSIVE for SELECT to authenticated
  using ((EXISTS ( SELECT 1
   FROM rapor r
  WHERE (r.id = rapor_nilai.rapor_id))));
create policy rapor_nilai_kelola on public.rapor_nilai as PERMISSIVE for ALL to authenticated
  using ((EXISTS ( SELECT 1
   FROM rapor r
  WHERE ((r.id = rapor_nilai.rapor_id) AND (is_wali_kelas(r.kelas_id) OR is_manajemen())))))
  with check ((EXISTS ( SELECT 1
   FROM rapor r
  WHERE ((r.id = rapor_nilai.rapor_id) AND (is_wali_kelas(r.kelas_id) OR is_manajemen())))));

-- ---------- agenda ----------
create policy agenda_sekolah_select on public.agenda_sekolah as PERMISSIVE for SELECT to authenticated
  using (is_pengguna_aktif());
create policy agenda_sekolah_kelola on public.agenda_sekolah as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());
create policy agenda_kelas_select on public.agenda_kelas as PERMISSIVE for SELECT to authenticated
  using (is_pengguna_aktif());
create policy agenda_kelas_kelola on public.agenda_kelas as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());

-- ---------- pengumuman ----------
create policy pengumuman_select on public.pengumuman as PERMISSIVE for SELECT to authenticated
  using (((is_published AND is_pengguna_aktif()) OR is_manajemen()));
create policy pengumuman_kelola on public.pengumuman as PERMISSIVE for ALL to authenticated
  using (is_manajemen())
  with check (is_manajemen());


-- =====================================================================
-- 10. STORAGE (semua bucket privat; file dibuka lewat URL sementara)
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('bukti-absensi-guru', 'bukti-absensi-guru', false, 5242880,  '{image/jpeg,image/png,image/webp}'),
  ('surat',              'surat',              false, 5242880,  '{image/jpeg,image/png,application/pdf}'),
  ('lampiran',           'lampiran',           false, 10485760, null),
  ('rapor',              'rapor',              false, 10485760, '{application/pdf}')
on conflict (id) do nothing;

-- unggah (foto, surat, lampiran: hanya ke folder bernama id pengguna sendiri)
create policy schoolcare_upload_bukti on storage.objects as PERMISSIVE for INSERT to authenticated
  with check (((bucket_id = 'bukti-absensi-guru'::text) AND is_guru() AND ((storage.foldername(name))[1] = (auth.uid())::text)));
create policy schoolcare_upload_surat on storage.objects as PERMISSIVE for INSERT to authenticated
  with check (((bucket_id = 'surat'::text) AND is_pengguna_aktif() AND ((storage.foldername(name))[1] = (auth.uid())::text)));
create policy schoolcare_upload_lampiran on storage.objects as PERMISSIVE for INSERT to authenticated
  with check (((bucket_id = 'lampiran'::text) AND (is_guru() OR is_manajemen()) AND ((storage.foldername(name))[1] = (auth.uid())::text)));
create policy schoolcare_upload_rapor on storage.objects as PERMISSIVE for INSERT to authenticated
  with check (((bucket_id = 'rapor'::text) AND (is_guru() OR is_manajemen())));

-- baca
create policy schoolcare_baca_bukti on storage.objects as PERMISSIVE for SELECT to authenticated
  using (((bucket_id = 'bukti-absensi-guru'::text) AND bisa_lihat_foto_absensi(name)));
create policy schoolcare_baca_surat on storage.objects as PERMISSIVE for SELECT to authenticated
  using (((bucket_id = 'surat'::text) AND bisa_lihat_surat(name)));
create policy schoolcare_baca_lampiran on storage.objects as PERMISSIVE for SELECT to authenticated
  using (((bucket_id = 'lampiran'::text) AND is_pengguna_aktif()));
create policy schoolcare_baca_rapor on storage.objects as PERMISSIVE for SELECT to authenticated
  using (((bucket_id = 'rapor'::text) AND (EXISTS ( SELECT 1
   FROM rapor r
  WHERE (r.file_url = objects.name)))));

-- ubah / hapus (milik sendiri; manajemen boleh menghapus semua)
create policy schoolcare_ubah_milik_sendiri on storage.objects as PERMISSIVE for UPDATE to authenticated
  using (((bucket_id = ANY (ARRAY['bukti-absensi-guru'::text, 'surat'::text, 'lampiran'::text, 'rapor'::text])) AND (owner = auth.uid())));
create policy schoolcare_hapus_milik_sendiri on storage.objects as PERMISSIVE for DELETE to authenticated
  using (((bucket_id = ANY (ARRAY['bukti-absensi-guru'::text, 'surat'::text, 'lampiran'::text, 'rapor'::text])) AND ((owner = auth.uid()) OR is_manajemen())));


-- =====================================================================
-- 11. REALTIME
-- =====================================================================
alter publication supabase_realtime add table public.absensi_siswa;
alter publication supabase_realtime add table public.absensi_guru;
alter publication supabase_realtime add table public.pengumuman;
