-- =====================================================================
-- SchoolCare · Data dummy SD
-- Tahun Ajaran 2026/2027, semester ganjil, Kurikulum Merdeka.
--
-- Cara pakai: Supabase → SQL Editor → tempel seluruh file ini → Run.
-- Aman dijalankan ulang: data dummy lama ditimpa, data buatanmu sendiri tidak dihapus.
--
-- Semua akun dummy memakai domain @schoolcare.test dengan password: SchoolCare123
--   admin@schoolcare.test         Pihak Sekolah
--   guru.1a@ … guru.6b@           guru kelas sekaligus wali kelas 1A–6B
--   guru.pai1@, guru.pai2@        guru PAI (kelas 1–3 dan 4–6)
--   guru.pjok1@, guru.pjok2@      guru PJOK (kelas 1–3 dan 4–6)
--   ortu.1a.1@ … ortu.6b.2@       orang tua (siswa no. 1 = ayah, no. 2 = ibu)
--   ortu.1a.1@ punya 2 anak (kelas 1A dan 4A), untuk mencoba fitur ganti anak.
-- =====================================================================

-- Helper: membuat akun login (auth.users + auth.identities).
-- Trigger handle_new_user otomatis membuat baris public.profiles.
create or replace function pg_temp.buat_akun(
  p_email text, p_nama text, p_role text, p_wa text default null, p_nip text default null)
returns uuid language plpgsql as $f$
declare v_id uuid;
begin
  select id into v_id from auth.users where email = p_email;
  if v_id is null then
    v_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new)
    values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated', p_email,
      extensions.crypt('SchoolCare123', extensions.gen_salt('bf')), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email'), 'role', p_role),
      jsonb_strip_nulls(jsonb_build_object('nama_lengkap', p_nama, 'no_whatsapp', p_wa, 'nip', p_nip)),
      now(), now(), '', '', '', '');
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (
      gen_random_uuid(), v_id, v_id::text,
      jsonb_build_object('sub', v_id::text, 'email', p_email, 'email_verified', true),
      'email', now(), now(), now());
  end if;
  update public.profiles
     set nama_lengkap = p_nama, role = p_role::public.user_role, no_whatsapp = p_wa, nip = p_nip, is_active = true
   where id = v_id;
  return v_id;
end $f$;

do $$
declare
  -- Jam pelajaran SD: 1 JP = 35 menit, istirahat 08.45–09.00 dan 10.45–11.00
  v_hari    text[] := array['senin','selasa','rabu','kamis','jumat','sabtu'];
  v_mulai   time[] := array['07:00','07:35','08:10','09:00','09:35','10:10','11:00','11:35']::time[];
  v_selesai time[] := array['07:35','08:10','08:45','09:35','10:10','10:45','11:35','12:10']::time[];

  v_nama_wali text[] := array[
    'Siti Rahmawati, S.Pd.', 'Dwi Lestari, S.Pd.', 'Ani Suryani, S.Pd.', 'Rina Kartika, S.Pd.',
    'Budi Santoso, S.Pd.', 'Fitri Handayani, S.Pd.', 'Agus Prasetyo, S.Pd.', 'Nur Aini, S.Pd.',
    'Hendra Wijaya, S.Pd.', 'Sri Wahyuni, S.Pd.', 'Joko Susilo, S.Pd.', 'Endang Purwanti, S.Pd.'];
  v_jk_wali int[] := array[2,2,2,2,1,2,1,2,1,2,1,2];

  v_cowok text[] := array['Andi','Bima','Raka','Dimas','Fajar','Galih','Rizky','Arya','Daffa','Farel',
                          'Kevin','Naufal','Rafi','Satria','Yusuf'];
  v_cewek text[] := array['Aisyah','Bunga','Citra','Dinda','Nabila','Salsa','Keisha','Alya','Zahra','Naura',
                          'Putri','Kirana','Syifa','Laras','Tiara'];
  v_marga text[] := array['Pratama','Saputra','Wijaya','Lestari','Kusuma','Ramadhan','Hidayat','Permata','Nugroho',
                          'Maharani','Setiawan','Anggraini','Firmansyah','Puspita','Utami','Gunawan','Santoso','Rahayu'];
  v_ayah  text[] := array['Ahmad','Bambang','Dedy','Eko','Hadi','Irfan','Rahmat','Slamet','Taufik','Wahyu','Yanto','Zainal'];
  v_ibu   text[] := array['Dewi','Eka','Fitria','Indah','Kartini','Lina','Maya','Novi','Ratna','Sari','Tuti','Yuni'];
  v_jalan text[] := array['Melati','Kenanga','Cempaka','Flamboyan','Anggrek','Mawar','Dahlia','Teratai'];
  v_topik_mtk  text[] := array['penjumlahan dan pengurangan sampai 20', 'perkalian dan pembagian dasar',
                               'pecahan sederhana', 'keliling dan luas bangun datar',
                               'operasi hitung pecahan', 'volume kubus dan balok'];
  v_topik_bind text[] := array['menulis huruf tegak bersambung', 'membaca nyaring cerita pendek',
                               'menulis puisi tentang alam', 'menemukan ide pokok paragraf',
                               'menulis teks narasi', 'membuat teks pidato'];

  v_ta uuid; v_admin uuid;
  v_wali uuid[] := '{}'; v_kelas uuid[] := '{}'; v_pai uuid[] := '{}'; v_pjok uuid[] := '{}';
  v_semua_guru uuid[];
  v_k int; v_t int; v_g int; v_i int; v_d int; v_jp int; v_s int; v_x int; v_y int; v_n int;
  v_paralel int; v_angkatan int;
  v_nama_kelas text; v_jk text; v_depan text; v_belakang text; v_last_1a1 text; v_mnama text;
  v_kode text[]; v_jml int[]; v_antrian text[]; v_ada boolean;
  v_id uuid; v_ortu uuid; v_ortu_1a1 uuid; v_demo uuid; v_guru uuid; v_mid uuid;
  v_m_mtk uuid; v_m_bind uuid; v_izin uuid; v_agenda uuid; v_tgl date;
begin
  -- ================================================================ TAHUN AJARAN
  update public.tahun_ajaran set is_active = false where is_active and nama <> '2026/2027';
  insert into public.tahun_ajaran (nama, semester_aktif, tanggal_mulai, tanggal_selesai, is_active)
  values ('2026/2027', 'ganjil', '2026-07-13', '2027-06-26', true)
  on conflict (nama) do update
    set semester_aktif = excluded.semester_aktif, tanggal_mulai = excluded.tanggal_mulai,
        tanggal_selesai = excluded.tanggal_selesai, is_active = true
  returning id into v_ta;

  -- ================================================================ MATA PELAJARAN (Kurikulum Merdeka SD)
  insert into public.mata_pelajaran (kode, nama) values
    ('PAI',   'Pendidikan Agama Islam dan Budi Pekerti'),
    ('PP',    'Pendidikan Pancasila'),
    ('BIND',  'Bahasa Indonesia'),
    ('MTK',   'Matematika'),
    ('IPAS',  'Ilmu Pengetahuan Alam dan Sosial'),
    ('SENI',  'Seni dan Budaya'),
    ('PJOK',  'Pendidikan Jasmani, Olahraga, dan Kesehatan'),
    ('BING',  'Bahasa Inggris'),
    ('MULOK', 'Bahasa Jawa (Muatan Lokal)')
  on conflict (kode) do update set nama = excluded.nama;
  select id into v_m_mtk  from public.mata_pelajaran where kode = 'MTK';
  select id into v_m_bind from public.mata_pelajaran where kode = 'BIND';

  -- ================================================================ AKUN ADMIN & GURU
  v_admin := pg_temp.buat_akun('admin@schoolcare.test', 'Admin Tata Usaha', 'manajemen', '6281200000100');

  for v_k in 1..12 loop
    v_t := (v_k + 1) / 2;
    v_nama_kelas := v_t || case when v_k % 2 = 1 then 'A' else 'B' end;
    v_wali[v_k] := pg_temp.buat_akun(
      format('guru.%s@schoolcare.test', lower(v_nama_kelas)), v_nama_wali[v_k], 'guru',
      '6281200000' || lpad(v_k::text, 3, '0'),
      format('%s%s15201007%s%s', 1978 + v_k, lpad((v_k % 12 + 1)::text, 2, '0'), v_jk_wali[v_k], lpad(v_k::text, 3, '0')));
  end loop;

  v_pai[1]  := pg_temp.buat_akun('guru.pai1@schoolcare.test',  'Ahmad Fauzi, S.Pd.I.',   'guru', '6281200000013', '198203152010071013');
  v_pai[2]  := pg_temp.buat_akun('guru.pai2@schoolcare.test',  'Muhammad Ridwan, S.Ag.', 'guru', '6281200000014', '198406152010071014');
  v_pjok[1] := pg_temp.buat_akun('guru.pjok1@schoolcare.test', 'Dedi Kurniawan, S.Pd.',  'guru', '6281200000015', '198608152010071015');
  v_pjok[2] := pg_temp.buat_akun('guru.pjok2@schoolcare.test', 'Rudi Hartono, S.Pd.',    'guru', '6281200000016', '198810152010071016');
  v_semua_guru := v_wali || v_pai || v_pjok;

  -- ================================================================ KELAS 1A–6B + WALI KELAS
  for v_k in 1..12 loop
    v_t := (v_k + 1) / 2;
    v_nama_kelas := v_t || case when v_k % 2 = 1 then 'A' else 'B' end;
    insert into public.kelas (tahun_ajaran_id, nama_kelas, tingkat, ruang, wali_kelas_id)
    values (v_ta, v_nama_kelas, v_t, 'Ruang ' || v_nama_kelas, v_wali[v_k])
    on conflict (tahun_ajaran_id, nama_kelas) do update
      set tingkat = excluded.tingkat, ruang = excluded.ruang, wali_kelas_id = excluded.wali_kelas_id
    returning id into v_id;
    v_kelas[v_k] := v_id;
  end loop;

  -- ================================================================ SISWA (10 per kelas) + ORANG TUA
  drop table if exists _siswa;
  create temp table _siswa (id uuid, kk int, ss int, kelas_id uuid, wali uuid);

  for v_k in 1..12 loop
    v_t := (v_k + 1) / 2;
    v_paralel := case when v_k % 2 = 1 then 1 else 2 end;
    v_nama_kelas := v_t || case when v_paralel = 1 then 'A' else 'B' end;
    v_angkatan := 2027 - v_t;                        -- kelas 1 = angkatan 2026
    for v_s in 1..10 loop
      v_jk := case when v_s % 2 = 1 then 'L' else 'P' end;
      v_depan := case when v_jk = 'L' then v_cowok[(v_k * 3 + v_s) % 15 + 1]
                                      else v_cewek[(v_k * 3 + v_s) % 15 + 1] end;
      v_belakang := v_marga[(v_k * 5 + v_s * 7) % 18 + 1];
      if v_k = 1 and v_s = 1 then v_last_1a1 := v_belakang; end if;
      if v_k = 7 and v_s = 1 then v_belakang := v_last_1a1; end if;   -- kakak dari siswa 1A no. 1

      insert into public.siswa (nis, nisn, nama_lengkap, jenis_kelamin, tanggal_lahir, alamat, kelas_id, status)
      values (
        (v_angkatan % 100) || v_paralel::text || lpad(v_s::text, 3, '0'),
        '00' || (v_angkatan % 100) || v_paralel::text || lpad(v_s::text, 5, '0'),
        v_depan || ' ' || v_belakang,
        v_jk::public.jenis_kelamin,
        make_date(2020 - v_t, (v_k + v_s * 5) % 12 + 1, (v_k * 3 + v_s * 7) % 28 + 1),
        format('Jl. %s No. %s', v_jalan[(v_k + v_s) % 8 + 1], (v_k * 10 + v_s) % 97 + 1),
        v_kelas[v_k], 'aktif')
      on conflict (nis) do update
        set nisn = excluded.nisn, nama_lengkap = excluded.nama_lengkap, jenis_kelamin = excluded.jenis_kelamin,
            tanggal_lahir = excluded.tanggal_lahir, alamat = excluded.alamat, kelas_id = excluded.kelas_id,
            status = 'aktif'
      returning id into v_id;

      insert into _siswa values (v_id, v_k, v_s, v_kelas[v_k], v_wali[v_k]);
      if v_k = 1 and v_s = 1 then v_demo := v_id; end if;

      -- siswa no. 1 dan 2 tiap kelas punya akun orang tua
      if v_s <= 2 then
        if v_k = 7 and v_s = 1 then
          v_ortu := v_ortu_1a1;
        else
          v_ortu := pg_temp.buat_akun(
            format('ortu.%s.%s@schoolcare.test', lower(v_nama_kelas), v_s),
            case when v_s = 1 then v_ayah[v_k] else v_ibu[v_k] end || ' ' || v_belakang,
            'orang_tua', '628130' || lpad((v_k * 10 + v_s)::text, 5, '0'));
        end if;
        if v_k = 1 and v_s = 1 then v_ortu_1a1 := v_ortu; end if;
        insert into public.orang_tua_siswa (orang_tua_id, siswa_id, hubungan)
        values (v_ortu, v_id, (case when v_s = 1 then 'ayah' else 'ibu' end)::public.hubungan_keluarga)
        on conflict do nothing;
      end if;
    end loop;
  end loop;

  -- ================================================================ JADWAL PELAJARAN (Senin–Jumat)
  -- Kelas 1–2: 6 JP/hari = 30 JP/minggu (tanpa IPAS).
  -- Kelas 3–6: 8 JP Senin–Kamis + 6 JP Jumat = 38 JP/minggu.
  -- PAI dan PJOK diajar guru mapel (blok 3 JP, diatur supaya tidak bentrok antarkelas);
  -- mapel lain diajar guru kelas.
  drop table if exists _slot;
  create temp table _slot (kk int, hh int, jj int, kode_m text, guru_m uuid);

  for v_k in 1..12 loop
    v_t := (v_k + 1) / 2;
    v_g := case when v_t <= 3 then 1 else 2 end;
    v_i := (v_k - 1) % 6;
    for v_x in 0..2 loop
      insert into _slot values (v_k, v_i % 5 + 1,       case when v_i < 5 then 1 else 4 end + v_x, 'PAI',  v_pai[v_g]);
      insert into _slot values (v_k, (v_i + 2) % 5 + 1, case when v_i < 5 then 4 else 1 end + v_x, 'PJOK', v_pjok[v_g]);
    end loop;

    if v_t <= 2 then
      v_kode := array['BIND','MTK','PP','SENI','MULOK','BING'];        v_jml := array[7,6,4,3,2,2];
    else
      v_kode := array['BIND','MTK','IPAS','PP','SENI','BING','MULOK']; v_jml := array[8,7,6,4,3,2,2];
    end if;

    -- antrean mapel guru kelas, diselang-seling 2 JP supaya tersebar
    v_antrian := '{}';
    loop
      v_ada := false;
      for v_x in 1..array_length(v_kode, 1) loop
        if v_jml[v_x] > 0 then
          v_ada := true;
          for v_y in 1..least(2, v_jml[v_x]) loop
            v_antrian := v_antrian || v_kode[v_x];
          end loop;
          v_jml[v_x] := greatest(v_jml[v_x] - 2, 0);
        end if;
      end loop;
      exit when not v_ada;
    end loop;

    v_n := 1;
    for v_d in 1..5 loop
      for v_jp in 1..(case when v_t <= 2 or v_d = 5 then 6 else 8 end) loop
        if not exists (select 1 from _slot where kk = v_k and hh = v_d and jj = v_jp) then
          insert into _slot values (v_k, v_d, v_jp, v_antrian[v_n], v_wali[v_k]);
          v_n := v_n + 1;
        end if;
      end loop;
    end loop;
  end loop;

  delete from public.jadwal_pelajaran where kelas_id = any(v_kelas) and semester = 'ganjil';
  insert into public.jadwal_pelajaran (kelas_id, mapel_id, guru_id, semester, hari, jam_ke, jam_mulai, jam_selesai, ruang)
  select v_kelas[s.kk], m.id, s.guru_m, 'ganjil'::public.semester_type, v_hari[s.hh]::public.hari_type,
         s.jj, v_mulai[s.jj], v_selesai[s.jj],
         case when s.kode_m = 'PJOK' then 'Lapangan'
              else 'Ruang ' || ((s.kk + 1) / 2) || case when s.kk % 2 = 1 then 'A' else 'B' end end
  from _slot s
  join public.mata_pelajaran m on m.kode = s.kode_m;

  -- ================================================================ ABSENSI SISWA (3 minggu terakhir)
  perform setseed(0.42);
  insert into public.absensi_siswa (siswa_id, kelas_id, tanggal, status, keterangan, dicatat_oleh)
  select y.id, y.kelas_id, y.tgl, y.st::public.status_kehadiran_siswa,
         case y.st when 'terlambat' then 'Datang pukul 07.15'
                   when 'sakit'     then 'Demam'
                   when 'izin'      then 'Acara keluarga'
                   when 'alpa'      then 'Tanpa keterangan' end,
         y.wali
  from (
    select x.*, case when x.r < 0.88 then 'hadir' when x.r < 0.92 then 'terlambat'
                     when x.r < 0.95 then 'sakit' when x.r < 0.98 then 'izin' else 'alpa' end as st
    from (
      select s.id, s.kelas_id, s.wali, g.tgl::date as tgl, random() as r
      from _siswa s
      cross join generate_series(greatest(current_date - 20, date '2026-07-13'), current_date, interval '1 day') as g(tgl)
      where extract(isodow from g.tgl) <= 5
    ) x
  ) y
  on conflict (siswa_id, tanggal) do nothing;

  -- anak akun demo (ortu.1a.1) hadir hari ini
  update public.absensi_siswa set status = 'hadir', keterangan = null
   where siswa_id = v_demo and tanggal = current_date;

  -- contoh pengajuan izin sakit dari orang tua (3 hari sekolah yang lalu)
  delete from public.pengajuan_izin where diajukan_oleh = v_ortu_1a1;
  select g.tgl::date into v_tgl
    from generate_series(current_date - 10, current_date - 1, interval '1 day') as g(tgl)
   where extract(isodow from g.tgl) <= 5
   order by g.tgl desc offset 2 limit 1;
  insert into public.pengajuan_izin (siswa_id, diajukan_oleh, jenis, tanggal_mulai, tanggal_selesai, alasan)
  values (v_demo, v_ortu_1a1, 'sakit', v_tgl, v_tgl, 'Demam dan batuk sejak malam, sudah diperiksa ke dokter.')
  returning id into v_izin;
  insert into public.absensi_siswa (siswa_id, kelas_id, tanggal, status, keterangan, pengajuan_izin_id, dicatat_oleh)
  values (v_demo, v_kelas[1], v_tgl, 'sakit', 'Demam (pengajuan dari orang tua)', v_izin, v_wali[1])
  on conflict (siswa_id, tanggal) do update
    set status = excluded.status, keterangan = excluded.keterangan, pengajuan_izin_id = excluded.pengajuan_izin_id;

  -- ================================================================ ABSENSI GURU (5 hari sekolah terakhir)
  -- Foto bukti hanya path contoh (file tidak ada di Storage).
  -- Contoh guru berhalangan: PJOK kelas 1A hari Rabu lalu, digantikan wali kelas 1A.
  select g.tgl::date into v_tgl
    from generate_series(current_date - 7, current_date - 1, interval '1 day') as g(tgl)
   where extract(isodow from g.tgl) = 3
   limit 1;
  insert into public.absensi_guru (jadwal_id, tanggal, guru_id, status_kehadiran, foto_url, latitude, longitude,
      akurasi_meter, foto_diambil_pada, keterangan_tidak_hadir, guru_pengganti_id, status_kelas)
  select j.id, v_tgl, j.guru_id, 'tidak_hadir'::public.status_kehadiran_guru, 'dummy/surat-sakit.jpg',
         -6.9147, 107.6098, 15, ((v_tgl + j.jam_mulai - interval '30 min') at time zone 'Asia/Jakarta'),
         'Sakit, surat dokter menyusul.', v_wali[1], 'digantikan'::public.status_kelas
  from public.jadwal_pelajaran j
  where j.kelas_id = v_kelas[1] and j.semester = 'ganjil' and j.hari = 'rabu' and j.guru_id = v_pjok[1]
  on conflict (jadwal_id, tanggal) do nothing;

  insert into public.absensi_guru (jadwal_id, tanggal, guru_id, status_kehadiran, foto_url, latitude, longitude,
      akurasi_meter, foto_diambil_pada, berita_acara, status_kelas)
  select j.id, g.tgl::date, j.guru_id, 'hadir'::public.status_kehadiran_guru,
         format('dummy/%s/%s.jpg', g.tgl::date, j.id),
         -6.9147 + random() * 0.0005, 107.6098 + random() * 0.0005, 5 + random() * 15,
         ((g.tgl::date + j.jam_mulai + interval '2 min') at time zone 'Asia/Jakarta'),
         format('Pembelajaran %s berjalan lancar. Siswa mengerjakan latihan dan tanya jawab.', m.nama),
         'berlangsung'::public.status_kelas
  from public.jadwal_pelajaran j
  join public.mata_pelajaran m on m.id = j.mapel_id
  join generate_series(current_date - 7, current_date - 1, interval '1 day') as g(tgl)
    on extract(isodow from g.tgl) <= 5
   and j.hari = v_hari[extract(isodow from g.tgl)::int]::public.hari_type
  where j.kelas_id = any(v_kelas) and j.semester = 'ganjil'
  on conflict (jadwal_id, tanggal) do nothing;

  -- ================================================================ TUGAS, UJIAN, NILAI
  delete from public.nilai where guru_id = any(v_semua_guru);
  delete from public.tugas where guru_id = any(v_semua_guru);
  delete from public.ujian where guru_id = any(v_semua_guru);

  for v_k in 1..12 loop
    v_t := (v_k + 1) / 2;
    v_g := case when v_t <= 3 then 1 else 2 end;
    v_nama_kelas := v_t || case when v_k % 2 = 1 then 'A' else 'B' end;

    insert into public.tugas (kelas_id, mapel_id, guru_id, judul, deskripsi, tenggat) values
      (v_kelas[v_k], v_m_mtk, v_wali[v_k], 'Latihan ' || v_topik_mtk[v_t],
       format('Kerjakan soal latihan di buku paket halaman %s nomor 1–10.', 20 + v_t * 5),
       ((current_date - 5) + time '20:00') at time zone 'Asia/Jakarta'),
      (v_kelas[v_k], v_m_bind, v_wali[v_k], 'Tugas ' || v_topik_bind[v_t],
       'Kerjakan di buku tulis Bahasa Indonesia, dikumpulkan pada pelajaran berikutnya.',
       ((current_date - 3) + time '20:00') at time zone 'Asia/Jakarta'),
      (v_kelas[v_k], v_m_mtk, v_wali[v_k], 'PR soal cerita ' || v_topik_mtk[v_t],
       'Kerjakan 5 soal cerita di lembar kerja yang dibagikan di kelas.',
       ((current_date + 3) + time '20:00') at time zone 'Asia/Jakarta'),
      (v_kelas[v_k], v_m_bind, v_wali[v_k], 'Proyek ' || v_topik_bind[v_t],
       'Boleh dibantu orang tua. Hasil karya dibawa ke sekolah untuk dipresentasikan.',
       ((current_date + 6) + time '20:00') at time zone 'Asia/Jakarta');

    -- STS (sudah lewat) dan SAS (akan datang), satu mapel per hari
    v_kode := case when v_t <= 2 then array['BIND','MTK','PP','PAI']
                                 else array['BIND','MTK','PP','IPAS','PAI'] end;
    for v_x in 1..array_length(v_kode, 1) loop
      select id, nama into v_mid, v_mnama from public.mata_pelajaran where kode = v_kode[v_x];
      v_guru := case when v_kode[v_x] = 'PAI' then v_pai[v_g] else v_wali[v_k] end;
      insert into public.ujian (kelas_id, mapel_id, guru_id, jenis, judul, materi, tanggal, jam_mulai, jam_selesai, ruang) values
        (v_kelas[v_k], v_mid, v_guru, 'uts', 'Sumatif Tengah Semester – ' || v_mnama, 'Materi bab 1 sampai bab 3',
         date '2026-09-21' + (v_x - 1), '07:30', '09:00', 'Ruang ' || v_nama_kelas),
        (v_kelas[v_k], v_mid, v_guru, 'uas', 'Sumatif Akhir Semester – ' || v_mnama, 'Seluruh materi semester ganjil',
         date '2026-11-30' + (v_x - 1), '07:30', '09:00', 'Ruang ' || v_nama_kelas);
    end loop;

    insert into public.ujian (kelas_id, mapel_id, guru_id, jenis, judul, materi, tanggal, jam_mulai, jam_selesai, ruang)
    values (v_kelas[v_k], v_m_mtk, v_wali[v_k], 'ulangan_harian', 'Ulangan harian Matematika',
            'Materi ' || v_topik_mtk[v_t], current_date + 7, '07:35', '08:45', 'Ruang ' || v_nama_kelas);
  end loop;

  -- nilai tugas yang tenggatnya sudah lewat
  insert into public.nilai (siswa_id, mapel_id, guru_id, tahun_ajaran_id, semester, jenis, tugas_id, judul, nilai)
  select s.id, t.mapel_id, t.guru_id, v_ta, 'ganjil'::public.semester_type, 'tugas'::public.jenis_penilaian,
         t.id, t.judul, round((62 + random() * 38)::numeric, 0)
  from _siswa s
  join public.tugas t on t.kelas_id = s.kelas_id
  where t.guru_id = any(v_semua_guru) and t.tenggat < now();

  -- nilai STS
  insert into public.nilai (siswa_id, mapel_id, guru_id, tahun_ajaran_id, semester, jenis, ujian_id, judul, nilai)
  select s.id, u.mapel_id, u.guru_id, v_ta, 'ganjil'::public.semester_type, 'uts'::public.jenis_penilaian,
         u.id, u.judul, round((58 + random() * 42)::numeric, 0)
  from _siswa s
  join public.ujian u on u.kelas_id = s.kelas_id
  where u.guru_id = any(v_semua_guru) and u.jenis = 'uts' and u.tanggal < current_date;

  -- ================================================================ AGENDA / KALENDER
  delete from public.pengumuman where dibuat_oleh = v_admin;
  delete from public.agenda_sekolah where dibuat_oleh = v_admin;

  insert into public.agenda_sekolah (judul, deskripsi, kategori, tanggal_mulai, tanggal_selesai, jam_mulai, jam_selesai,
      lokasi, ketentuan_pakaian, perlengkapan, ketentuan_lain, menggantikan_pelajaran, untuk_semua_kelas, dibuat_oleh) values
    ('Masa Pengenalan Lingkungan Sekolah (MPLS)', 'Pengenalan lingkungan sekolah untuk siswa baru kelas 1.',
     'kegiatan', '2026-07-13', '2026-07-15', '07:00', '10:00', 'Lingkungan sekolah',
     'Seragam merah putih', 'Alat tulis', null, true, true, v_admin),
    ('Upacara Peringatan HUT ke-81 RI', 'Upacara bendera dilanjutkan lomba tujuh belasan.',
     'kegiatan', '2026-08-17', '2026-08-17', '07:00', '11:00', 'Lapangan sekolah',
     'Seragam merah putih lengkap dengan topi dan dasi', null, 'Siswa hadir paling lambat pukul 06.45.', true, true, v_admin),
    ('Sumatif Tengah Semester (STS) Ganjil', 'Penilaian tengah semester untuk semua kelas.',
     'ujian', '2026-09-21', '2026-09-25', '07:30', '09:00', null,
     null, 'Alat tulis lengkap dan papan ujian', null, true, true, v_admin),
    ('Peringatan Hari Guru Nasional', 'Upacara dan pentas seni persembahan siswa untuk bapak/ibu guru.',
     'kegiatan', '2026-11-25', '2026-11-25', '07:00', '10:00', 'Lapangan sekolah',
     'Pakaian adat daerah', 'Kartu ucapan untuk guru (tidak wajib)', 'Siswa pulang pukul 10.00.', true, true, v_admin),
    ('Sumatif Akhir Semester (SAS) Ganjil', 'Penilaian akhir semester ganjil untuk semua kelas.',
     'ujian', '2026-11-30', '2026-12-04', '07:30', '09:00', null,
     null, 'Alat tulis lengkap dan papan ujian', 'Kisi-kisi dibagikan oleh wali kelas.', true, true, v_admin),
    ('Class Meeting', 'Lomba antarkelas setelah SAS.',
     'kegiatan', '2026-12-14', '2026-12-16', '07:30', '10:30', 'Lapangan sekolah',
     'Seragam olahraga', 'Botol minum', null, true, true, v_admin),
    ('Pembagian Rapor Semester Ganjil', 'Rapor diambil oleh orang tua/wali di kelas masing-masing.',
     'pembagian_rapor', '2026-12-19', '2026-12-19', '08:00', '11:00', 'Ruang kelas masing-masing',
     null, null, 'Rapor hanya diserahkan kepada orang tua/wali siswa.', true, true, v_admin),
    ('Libur Semester Ganjil', 'Kegiatan belajar dimulai kembali Senin, 4 Januari 2027.',
     'libur', '2026-12-21', '2027-01-02', null, null, null,
     null, null, null, false, true, v_admin);

  -- agenda khusus kelas 6
  insert into public.agenda_sekolah (judul, deskripsi, kategori, tanggal_mulai, tanggal_selesai, jam_mulai, jam_selesai,
      lokasi, perlengkapan, ketentuan_lain, menggantikan_pelajaran, untuk_semua_kelas, dibuat_oleh)
  values ('Kunjungan Edukatif ke Museum (Kelas 6)', 'Belajar sejarah perjuangan bangsa sebagai bagian materi IPAS.',
          'kegiatan', '2026-11-27', '2026-11-27', '07:30', '12:00', 'Museum kota',
          'Bekal makan siang, botol minum, alat tulis', 'Wajib membawa surat izin yang ditandatangani orang tua.',
          true, false, v_admin)
  returning id into v_agenda;
  insert into public.agenda_kelas (agenda_id, kelas_id) values (v_agenda, v_kelas[11]), (v_agenda, v_kelas[12]);

  -- ================================================================ PENGUMUMAN
  select id into v_agenda from public.agenda_sekolah
   where dibuat_oleh = v_admin and judul = 'Peringatan Hari Guru Nasional';

  insert into public.pengumuman (judul, isi, kategori, agenda_id, is_published, dipublikasikan_pada, dibuat_oleh) values
    ('Tata tertib seragam sekolah',
     'Senin–Selasa: seragam merah putih. Rabu–Kamis: batik sekolah. Jumat: seragam Pramuka. '
     'Siswa wajib memakai sepatu hitam dan kaus kaki putih.',
     'kebijakan', null, true, now() - interval '30 days', v_admin),
    ('Perubahan jam pulang hari Jumat',
     'Mulai Jumat, 20 November 2026, kegiatan belajar hari Jumat selesai pukul 10.45 untuk semua kelas '
     'karena ada kegiatan Jumat bersih.',
     'perubahan_jadwal', null, true, now() - interval '3 days', v_admin),
    ('Jadwal Sumatif Akhir Semester (SAS) Ganjil',
     'SAS dilaksanakan 30 November – 4 Desember 2026 pukul 07.30–09.00. Kisi-kisi dibagikan oleh wali kelas. '
     'Mohon bapak/ibu mendampingi anak belajar di rumah.',
     'umum', null, true, now() - interval '2 days', v_admin),
    ('Peringatan Hari Guru Nasional 25 November 2026',
     'Siswa memakai pakaian adat daerah dan pulang pukul 10.00. Tidak ada kegiatan belajar seperti biasa.',
     'kegiatan', v_agenda, true, now() - interval '1 day', v_admin),
    ('Rencana class meeting (draf)',
     'Daftar lomba dan pembagian panitia class meeting akan diumumkan setelah SAS.',
     'kegiatan', null, false, now(), v_admin);
end $$;

-- Ringkasan hasil
select
  (select count(*) from public.profiles where email like '%@schoolcare.test')                  as akun_dummy,
  (select count(*) from public.kelas k join public.tahun_ajaran t on t.id = k.tahun_ajaran_id
    where t.nama = '2026/2027')                                                                 as kelas,
  (select count(*) from public.siswa s join public.kelas k on k.id = s.kelas_id
     join public.tahun_ajaran t on t.id = k.tahun_ajaran_id where t.nama = '2026/2027')          as siswa,
  (select count(*) from public.jadwal_pelajaran where semester = 'ganjil')                       as jadwal,
  (select count(*) from public.absensi_siswa)                                                   as absensi_siswa,
  (select count(*) from public.absensi_guru)                                                    as absensi_guru,
  (select count(*) from public.nilai)                                                           as nilai;
