import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  await ThemeController.instance.load();
  runApp(const PdfToolkitApp());
}

class PdfToolkitApp extends StatelessWidget {
  const PdfToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PDFly',
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
