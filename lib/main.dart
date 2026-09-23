import 'package:flutter/material.dart';
import 'data/repository.dart';
import 'state/app_controller.dart';
import 'ui/screens.dart';

const demoMode = bool.fromEnvironment('EXAM_PULSE_DEMO', defaultValue: true);
const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    demoMode ? DemoStudyRepository() : ApiStudyRepository(apiBaseUrl), demo: demoMode);
  runApp(ExamPulseApp(controller: controller));
}

class ExamPulseApp extends StatelessWidget {
  final AppController controller;
  const ExamPulseApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EXAM PULSE', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6554DF),
        surface: const Color(0xFFF7F8FD)),
      scaffoldBackgroundColor: const Color(0xFFF7F8FD),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F8FD),
        scrolledUnderElevation: 0, centerTitle: false),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFE2E5F1)),
          borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFE2E5F1)),
          borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))),
    ),
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, child) => controller.signedIn
          ? MainShell(key: const ValueKey('shell'), controller: controller)
          : SignInScreen(key: const ValueKey('auth'), controller: controller),
    ),
  );
}
