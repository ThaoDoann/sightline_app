import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/caption_service.dart';
import 'screens/login_screen.dart';
import './services/auth_services.dart';
import 'styles/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, CaptionService>(
          create: (context) => CaptionService(
              Provider.of<AuthService>(context, listen: false)),
          update: (_, authService, previous) => CaptionService(authService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return Consumer<AuthService>(
          builder: (context, auth, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Sightline',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ).copyWith(
                  onBackground: Colors.white,
                  onSurface: Colors.white,
                ),
                useMaterial3: true,
              ),
              themeMode: currentMode,
              home: auth.token == null ? const LoginScreen() : const HomeScreen(),
            );
          },
        );
      },
    );
  }
}