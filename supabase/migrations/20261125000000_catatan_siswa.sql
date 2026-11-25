-- =====================================================================
-- SchoolCare · Tabel catatan_siswa
--
-- Catatan guru tentang siswa selama jam pelajaran (mis. "pusing, izin ke UKS").
-- Status kehadiran tetap diisi wali kelas; guru mapel cukup menulis catatan,
-- yang bisa dibaca guru di kelas itu, wali kelas, orang tua siswa, dan manajemen.
--
-- Dipakai: lib/features/guru/data/siswa_repository.dart
-- Jalankan sekali di SQL Editor Supabase.
-- =====================================================================

create table public.catatan_siswa (
  id uuid default gen_random_uuid() not null,
  siswa_id uuid not null,
  jadwal_id uuid,                                   -- jam pelajaran saat catatan ditulis
  tanggal date default tanggal_hari_ini() not null,
  isi text not null,
  dibuat_oleh uuid default auth.uid() not null,
  created_at timestamp with time zone default now() not null,
  constraint catatan_siswa_pkey primary key (id),
  constraint catatan_siswa_isi_check check (length(btrim(isi)) between 1 and 1000),
  constraint catatan_siswa_siswa_id_fkey foreign key (siswa_id) references public.siswa(id) on delete cascade,
  constraint catatan_siswa_jadwal_id_fkey foreign key (jadwal_id) references public.jadwal_pelajaran(id) on delete set null,
  constraint catatan_siswa_dibuat_oleh_fkey foreign key (dibuat_oleh) references public.profiles(id) on delete cascade
);

create index idx_catatan_siswa_siswa_tanggal on public.catatan_siswa using btree (siswa_id, tanggal);

alter table public.catatan_siswa enable row level security;

-- Baca: manajemen, guru yang mengajar / wali di kelas siswa, dan orang tua siswa itu.
create policy catatan_siswa_select on public.catatan_siswa as permissive for select to authenticated
  using (is_manajemen() or guru_di_kelas(kelas_siswa(siswa_id)) or ortu_dari_siswa(siswa_id));

-- Tulis: guru di kelas siswa, atas namanya sendiri; kalau menyebut jam pelajaran,
-- jam itu harus miliknya dan di kelas siswa tersebut.
create policy catatan_siswa_insert on public.catatan_siswa as permissive for insert to authenticated
  with check (
    dibuat_oleh = auth.uid()
    and guru_di_kelas(kelas_siswa(siswa_id))
    and (jadwal_id is null or exists (
      select 1 from public.jadwal_pelajaran j
      where j.id = catatan_siswa.jadwal_id
        and j.guru_id = auth.uid()
        and j.kelas_id = kelas_siswa(catatan_siswa.siswa_id)))
  );

-- Ubah / hapus: hanya catatan buatan sendiri (manajemen boleh menghapus semua).
create policy catatan_siswa_update on public.catatan_siswa as permissive for update to authenticated
  using (dibuat_oleh = auth.uid())
  with check (dibuat_oleh = auth.uid());

create policy catatan_siswa_delete on public.catatan_siswa as permissive for delete to authenticated
  using (dibuat_oleh = auth.uid() or is_manajemen());
