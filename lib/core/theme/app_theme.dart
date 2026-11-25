import 'package:material_ui/material_ui.dart';
import 'package:schoolcare/core/theme/app_colors.dart';
import 'package:schoolcare/shared/widgets/latar_hias.dart';

class AppTheme {
  AppTheme._();

  /// Poppins dibundel di assets/fonts (lihat pubspec.yaml).
  static const _font = 'Poppins';

  static const _extraBold = FontWeight.w800;
  static const _bold = FontWeight.w700;
  static const _regular = FontWeight.w400;

  /// Poppins, 3 ketebalan: ExtraBold (w800) untuk teks "hook" besar (judul halaman,
  /// sapaan, angka statistik), Bold (w700) untuk label kecil, Regular (w400) untuk isi.
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? w(TextStyle? s, FontWeight weight) => s?.copyWith(fontWeight: weight);
    final t = base.apply(fontFamily: _font);
    return t
        .copyWith(
          displayLarge: w(t.displayLarge, _extraBold),
          displayMedium: w(t.displayMedium, _extraBold),
          displaySmall: w(t.displaySmall, _extraBold),
          headlineLarge: w(t.headlineLarge, _extraBold),
          headlineMedium: w(t.headlineMedium, _extraBold),
          headlineSmall: w(t.headlineSmall, _extraBold),
          titleLarge: w(t.titleLarge, _extraBold),
          titleMedium: w(t.titleMedium, _bold),
          titleSmall: w(t.titleSmall, _bold),
          bodyLarge: w(t.bodyLarge, _regular),
          bodyMedium: w(t.bodyMedium, _regular),
          bodySmall: w(t.bodySmall, _regular)?.copyWith(color: AppColors.inkMuted),
          labelLarge: w(t.labelLarge, _bold),
          labelMedium: w(t.labelMedium, _regular),
          labelSmall: w(t.labelSmall, _regular),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  }

  static ThemeData get light {
    final inputRadius = BorderRadius.circular(14);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    const inputSide = BorderSide(color: AppColors.softPink, width: 1.5);

    final base = ThemeData(
      fontFamily: _font,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.pink, surface: AppColors.white),
    );
    final text = _textTheme(base.textTheme);
    final buttonText = TextStyle(fontFamily: _font, fontWeight: _bold, fontSize: 15);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.pink,
        onPrimary: AppColors.white,
        secondary: AppColors.orange,
        onSecondary: AppColors.white,
        tertiary: AppColors.softYellow,
        onTertiary: AppColors.black,
        error: AppColors.pink,
        onError: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkMuted,
        outline: AppColors.softPink,
        outlineVariant: AppColors.softPink,
        primaryContainer: AppColors.softPink,
        onPrimaryContainer: AppColors.black,
        secondaryContainer: AppColors.softYellow,
        onSecondaryContainer: AppColors.black,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: AppColors.white,
        surfaceContainerLow: AppColors.white,
        surfaceContainer: AppColors.white,
        surfaceContainerHigh: AppColors.white,
        surfaceContainerHighest: AppColors.white,
      ),
      // Semua halaman berlatar pink + 2 lingkaran hiasan (LatarHias, dipasang lewat
      // pageTransitionsTheme di bawah), jadi Scaffold sendiri transparan. Konten di kartu putih.
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LatarHiasTransitionsBuilder(),
          TargetPlatform.iOS: LatarHiasTransitionsBuilder(),
          TargetPlatform.macOS: LatarHiasTransitionsBuilder(),
          TargetPlatform.windows: LatarHiasTransitionsBuilder(),
          TargetPlatform.linux: LatarHiasTransitionsBuilder(),
          TargetPlatform.fuchsia: LatarHiasTransitionsBuilder(),
        },
      ),
      canvasColor: AppColors.white,
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: const IconThemeData(color: AppColors.ink),
      dividerTheme: const DividerThemeData(color: AppColors.softPink, thickness: 1),
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.white),
        actionsIconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 22, fontWeight: _extraBold, color: AppColors.white),
      ),
      // Tombol kembali: ikon putih di kotak putih transparan.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: const Color(0x26FFFFFF), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 20),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 6,
        shadowColor: const Color(0x383A1426),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.ink,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: _bold, fontSize: 14),
        subtitleTextStyle: text.bodySmall?.copyWith(fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.inkFaint),
        labelStyle: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: AppColors.pink),
        prefixIconColor: AppColors.inkMuted,
        suffixIconColor: AppColors.inkMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: inputRadius, borderSide: inputSide),
        enabledBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: inputSide),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: inputSide),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
        errorStyle: text.bodySmall?.copyWith(color: AppColors.pink, fontSize: 11),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.softPink,
          disabledForegroundColor: AppColors.inkMuted,
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          iconColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.softPink, width: 1.5),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pink,
          textStyle: TextStyle(fontFamily: _font, fontWeight: _bold, fontSize: 13),
        ),
      ),
      // Orange (aksi kedua) supaya tetap terlihat di atas latar pink maupun kartu putih.
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        // softPink (bukan pink) supaya label ink tetap terbaca saat chip terpilih.
        selectedColor: AppColors.softPink,
        checkmarkColor: AppColors.black,
        side: const BorderSide(color: AppColors.softPink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: text.labelMedium?.copyWith(color: AppColors.ink),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: AppColors.black, fontWeight: _bold),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.ink,
          selectedBackgroundColor: AppColors.pink,
          selectedForegroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.softPink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: TextStyle(fontFamily: _font, fontWeight: _bold, fontSize: 13),
        ),
      ),
      // Default untuk TabBar di AppBar (di atas pink): teks putih, tab aktif Bold + garis putih.
      // TabBar di dalam kartu putih memakai gaya sendiri (lihat akademik_tab.dart).
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.softPink,
        labelStyle: const TextStyle(fontFamily: _font, fontWeight: _bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontFamily: _font, fontWeight: _regular, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Color(0x26FFFFFF)),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.white, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.pink),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.softPink,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        indicatorColor: AppColors.pink,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.white : AppColors.ink),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(fontFamily: _font, 
            fontSize: 10,
            color: AppColors.ink,
            fontWeight: s.contains(WidgetState.selected) ? _bold : _regular,
          ),
        ),
      ),
    );
  }
}
