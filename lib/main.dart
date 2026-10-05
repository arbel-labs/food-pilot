import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:foodpilot/app/router.dart';
import 'package:foodpilot/app/theme/app_theme.dart';
import 'package:foodpilot/core/config.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/business_repository.dart';
import 'package:foodpilot/features/profil/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lisensi OFL wajib ikut bersama font yang dibundel. Dengan didaftarkan di
  // sini, lisensinya juga muncul di halaman lisensi bawaan Flutter.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['Plus Jakarta Sans'], license);
  });

  // Supabase hanya dipakai konsultan AI dan cadangan data. Tanpa konfigurasi,
  // aplikasi tetap jalan penuh secara offline.
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
      );
    } catch (error) {
      debugPrint('Supabase gagal disiapkan: $error');
    }
  }

  await ReminderService.instance.init();

  final database = AppDatabase();
  final hasBusiness = await BusinessRepository(database).hasBusiness();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        initialLocationProvider.overrideWithValue(
          hasBusiness ? '/beranda' : '/onboarding',
        ),
      ],
      child: const FoodPilotApp(),
    ),
  );
}

class FoodPilotApp extends ConsumerWidget {
  const FoodPilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FoodPilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('id'),
      supportedLocales: const <Locale>[Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
