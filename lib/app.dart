import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:schoolcare/core/router/app_router.dart';
import 'package:schoolcare/core/theme/app_theme.dart';
import 'package:schoolcare/features/auth/providers/auth_provider.dart';

class SchoolCareApp extends StatefulWidget {
  const SchoolCareApp({super.key});

  @override
  State<SchoolCareApp> createState() => _SchoolCareAppState();
}

class _SchoolCareAppState extends State<SchoolCareApp> {
  late final GoRouter _router = createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SchoolCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Wajib: package pihak ketiga (mis. table_calendar) masih memakai Material lama.
      // Bridge ini meneruskan tema & bahasa ke widget mereka.
      builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
    );
  }
}
