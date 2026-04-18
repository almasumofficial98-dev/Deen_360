import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/quran_repository.dart';
import 'data/dua_repository.dart';
import 'data/salah_repository.dart';
import 'data/hadith_repository.dart';
import 'data/asma_repository.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final duaRepo = DuaRepository();
  await duaRepo.init();

  runApp(
    MultiProvider(
      providers: [
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
    return MaterialApp(
      title: 'Deen 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primary),
        fontFamily: 'Inter', // Default to a clean modern font
      ),
      home: const MainLayout(),
    );
  }
}
