import 'screens/language_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'config/config.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await AppConfig.init();
  runApp(const NewsifyApp());
}

class NewsifyApp extends StatelessWidget {
  const NewsifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Newsify',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            initialRoute: '/language',
            routes: {
              '/language': (context) => const LanguageSelectionScreen(),
              // '/onboarding': (context) => const OnboardingScreen(),
              '/main': (context) => const MainScreen(),
            },
          );
        },
      ),
    );
  }
}