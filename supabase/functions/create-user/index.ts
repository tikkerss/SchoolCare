// Supabase Edge Function: create-user
// Dipanggil dari halaman admin (Kelola Akun) untuk membuat akun login baru.
// Hanya akun berperan 'manajemen' yang aktif yang boleh memanggil fungsi ini.
//
// Deploy lewat dashboard: Edge Functions → Deploy a new function → Via Editor
// → nama: create-user → tempel isi file ini → Deploy.
// SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY sudah tersedia otomatis di Edge Functions.

import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // 1. Pastikan pemanggil adalah Pihak Sekolah yang aktif
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: auth, error: authError } = await admin.auth.getUser(token);
    if (authError || !auth.user) return json({ error: "Sesi login tidak valid. Silakan login ulang." }, 401);

    const { data: pemanggil } = await admin
      .from("profiles")
      .select("role, is_active")
      .eq("id", auth.user.id)
      .single();
    if (!pemanggil || pemanggil.role !== "manajemen" || !pemanggil.is_active) {
      return json({ error: "Hanya Pihak Sekolah yang boleh membuat akun." }, 403);
    }

    // 2. Validasi isian
    const { email, password, nama_lengkap, role, no_whatsapp, nip } = await req.json();
    if (!email || !password || !nama_lengkap) return json({ error: "Email, password, dan nama wajib diisi." }, 400);
    if (!["manajemen", "guru", "orang_tua"].includes(role)) return json({ error: "Peran tidak valid." }, 400);
    if (String(password).length < 6) return json({ error: "Password minimal 6 karakter." }, 400);

    // 3. Buat user. Trigger handle_new_user di database otomatis membuat baris profiles.
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { role },
      user_metadata: { nama_lengkap, no_whatsapp: no_whatsapp || null, nip: nip || null },
    });
    if (error) {
      const pesan = error.message.includes("already been registered")
        ? "Email ini sudah terdaftar."
        : error.message;
      return json({ error: pesan }, 400);
    }

    return json({ id: data.user.id });
  } catch (e) {
    return json({ error: `Terjadi kesalahan: ${e instanceof Error ? e.message : String(e)}` }, 500);
  }
});
