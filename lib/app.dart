// app.dart (Updated)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Import Riverpod
import 'package:statushub/providers/locale_provider.dart'; // 👈 Import your provider file
import 'package:statushub/router/app_router.dart';
import 'l10n/app_localizations.dart';

// Convert MyApp to a ConsumerWidget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // The build method now receives a `WidgetRef`
  Widget build(BuildContext context, WidgetRef ref) {
    // "watch" the localeProvider. The widget will rebuild whenever the locale changes.
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      // ✅ Get the locale directly from the provider
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