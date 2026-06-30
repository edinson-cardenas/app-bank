import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/settings_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase info: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MyApp(isFirebaseReady: firebaseInitialized),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirebaseReady;
  const MyApp({super.key, required this.isFirebaseReady});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'App Bank',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: AuthWrapper(isFirebaseReady: isFirebaseReady),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final bool isFirebaseReady;
  const AuthWrapper({super.key, required this.isFirebaseReady});

  @override
  Widget build(BuildContext context) {
    if (!isFirebaseReady) {
      return const Scaffold(
        body: Center(
          child: Text("Firebase no configurado correctamente."),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const OnboardingScreen();
          } else {
            // Usamos una clave única para que HomeScreen no se recree de forma que pierda el estado 
            // pero que responda al cambio de tema global.
            return const HomeScreen();
          }
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
