import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/providers/storage_provider.dart';
import 'src/screens/home_screen.dart';
import 'src/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage
  final storageService = await StorageService.init();

  // Allow system auto-rotation (portrait & landscape)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const FoldComicApp(),
    ),
  );
}

class FoldComicApp extends StatelessWidget {
  const FoldComicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoldComic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF12121E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF12121E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E2E),
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
