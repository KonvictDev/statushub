import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statushub/providers/locale_provider.dart';
import 'package:statushub/providers/theme_provider.dart'; // 👈 Import theme provider
import 'package:statushub/router/app_router.dart';
import 'l10n/app_localizations.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);           // Current locale
    final themeMode = ref.watch(themeProvider);        // Current theme

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,                            // Apply the theme here
        theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green, // 👈 Brand color (affects other widgets too)
        brightness: Brightness.light,
    ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green, // ✅ button bg
              foregroundColor: Colors.white, // ✅ text & icon
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),  // Optional dark theme
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: AppRouter().router,
    );
  }
}
