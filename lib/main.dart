import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/app.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env di root project berisi SUPABASE_URL dan SUPABASE_ANON_KEY
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await initializeDateFormatting('id_ID'); // format tanggal bahasa Indonesia

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        // Provider global milik anggota lain didaftarkan di sini (lewat Pull Request).
      ],
      child: const SchoolCareApp(),
    ),
  );
}
