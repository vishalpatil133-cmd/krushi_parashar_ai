import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase Initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase Core initialized successfully.');
  } catch (e) {
    print('Warning: Firebase could not be initialized ($e). Operating in offline local fallback mode.');
  }

  // Initialize Ads
  await AdService.instance.initialize();

  // Load theme preference from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  MyApp.isDarkMode.value = prefs.getBool('is_dark_mode') ?? false;
  MyApp.selectedLanguage.value = prefs.getString('selected_language') ?? 'mr';
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final isDarkMode = ValueNotifier<bool>(false);
  static final selectedLanguage = ValueNotifier<String>('mr');
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631); // Earth Green
    const accentGold = Color(0xFFE5A93B); // Golden Saffron
    const backgroundColor = Color(0xFFFAFAF7); // Soft Off-white

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, child) {
        return ValueListenableBuilder<String>(
          valueListenable: selectedLanguage,
          builder: (context, language, child) {
            return MaterialApp(
          title: 'Krishi Parashara AI',
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          
          // Light Theme Setup
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: primaryGreen,
            scaffoldBackgroundColor: backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.light,
              primary: primaryGreen,
              secondary: accentGold,
              background: backgroundColor,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryGreen, width: 1.5),
                foregroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            fontFamily: 'Roboto',
          ),
          
          // Dark Theme Setup
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: primaryGreen,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              brightness: Brightness.dark,
              primary: primaryGreen,
              secondary: accentGold,
              background: const Color(0xFF121212),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryGreen, width: 1.5),
                foregroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            fontFamily: 'Roboto',
          ),
          
          home: const SplashScreen(),
        );
          },
        );
      },
    );
  }
}
