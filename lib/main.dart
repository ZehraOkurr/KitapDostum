import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';

// Provider'lar
import 'providers/reading_provider.dart';
import 'providers/theme_provider.dart';

// Ekranlar
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart'; // Splash ekranını ekledik

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Font ayarlarını dışarıya taşıdık ki temiz olsun
    TextTheme createTextTheme(Color titleColor, Color bodyColor) {
      return TextTheme(
        displayLarge: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, color: titleColor),
        titleLarge: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, color: titleColor),
        bodyLarge: GoogleFonts.sourceSans3(color: bodyColor),
        bodyMedium: GoogleFonts.sourceSans3(color: bodyColor),
        bodySmall: GoogleFonts.sourceSans3(color: Colors.grey),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KitapDostum',
      
      themeMode: themeProvider.themeMode,
      
      // ☀️ 1. AYDINLIK TEMA
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F0EB),
        primaryColor: const Color(0xFFC69C82),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC69C82),
          brightness: Brightness.light,
          primary: const Color(0xFFC69C82),
          secondary: const Color(0xFF8D6E63),
        ),

        textTheme: createTextTheme(const Color(0xFF3E2723), const Color(0xFF3E2723)),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF3E2723)),
          titleTextStyle: TextStyle(color: Color(0xFF3E2723), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF5F0EB),
          selectedItemColor: Color(0xFF8D6E63),
          unselectedItemColor: Colors.grey,
        ),
      ),

      // 🌙 2. KARANLIK TEMA
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1B18),
        primaryColor: const Color(0xFFC69C82),
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC69C82),
          brightness: Brightness.dark,
          primary: const Color(0xFFC69C82),
          surface: const Color(0xFF2C2623),
          onSurface: const Color(0xFFEDE0D4),
        ),

        textTheme: createTextTheme(const Color(0xFFEDE0D4), const Color(0xFFEDE0D4)),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFEDE0D4)),
          titleTextStyle: TextStyle(color: Color(0xFFEDE0D4), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF25201D),
          selectedItemColor: Color(0xFFC69C82),
          unselectedItemColor: Colors.grey,
        ),
        
        cardColor: const Color(0xFF2C2623),
        dialogBackgroundColor: const Color(0xFF2C2623),
        
        inputDecorationTheme: InputDecorationTheme(
          fillColor: const Color(0xFF2C2623),
          filled: true,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),

      // Başlangıç Ekranı: Splash Screen
      home: const SplashScreen(),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

// --- GÜVENLİ OTOBAN (AUTH WRAPPER) ---
// Splash Screen bittiğinde buraya yönlendirilmeli
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC69C82))),
          );
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const WelcomeScreen();
      },
    );
  }
}