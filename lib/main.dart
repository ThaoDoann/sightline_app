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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, CaptionService>(
          create: (context) =>
              CaptionService(Provider.of<AuthService>(context, listen: false)),
          update: (_, authService, previous) => CaptionService(authService),
        ),
      ],

      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Sightline',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: AppTheme.primaryColor,
              fontFamily: 'Poppins',
            ),
            home: auth.token == null ? const LoginScreen() : const HomeScreen(),
          );
        },
      ),
    );
  }
}
