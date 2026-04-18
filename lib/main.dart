import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'data/quran_repository.dart';
import 'data/dua_repository.dart';
import 'data/salah_repository.dart';
import 'data/hadith_repository.dart';
import 'data/asma_repository.dart';
import 'data/salah_tracker_provider.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final duaRepo = DuaRepository();
  await duaRepo.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SalahTrackerProvider()),
        Provider<QuranRepository>(create: (_) => QuranRepository()),
        Provider<DuaRepository>(create: (_) => duaRepo),
        Provider<SalahRepository>(create: (_) => SalahRepository()),
        Provider<HadithRepository>(create: (_) => HadithRepository()),
        Provider<AsmaRepository>(create: (_) => AsmaRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Deen 360',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppTheme.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primaryColor,
              primary: theme.primaryColor,
            ),
            fontFamily: 'Inter',
          ),
          home: const MainLayout(),
        );
      },
    );
  }
}
