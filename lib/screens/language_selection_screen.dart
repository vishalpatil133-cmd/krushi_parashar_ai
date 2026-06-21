import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/database_service.dart';
import 'home_dashboard.dart';
import 'profile_setup_screen.dart';
import 'auth_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    // Save selection in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);

    // Update global state
    MyApp.selectedLanguage.value = langCode;

    // Navigate to next screen based on Auth status
    _navigateToNext(context);
  }

  Future<void> _navigateToNext(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbService = DatabaseService();
        final profile = await dbService.getUserProfile(user.uid).timeout(
          const Duration(seconds: 4),
          onTimeout: () => null,
        );

        if (profile != null) {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeDashboard(userId: user.uid)),
          );
          return;
        } else {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Language screen nav error: $e');
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentGold.withOpacity(0.7), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/icon/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'कृषी पराशर AI',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'कृपया भाषा निवडा / Please Select Language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),

              // Language Cards
              _buildLanguageCard(
                context: context,
                title: 'मराठी (Marathi)',
                subtitle: 'मराठीमध्ये ॲप वापरा',
                langCode: 'mr',
                primaryGreen: primaryGreen,
                accentGold: accentGold,
              ),
              const SizedBox(height: 16),
              _buildLanguageCard(
                context: context,
                title: 'हिंदी (Hindi)',
                subtitle: 'हिंदी में ऐप का उपयोग करें',
                langCode: 'hi',
                primaryGreen: primaryGreen,
                accentGold: accentGold,
              ),
              const SizedBox(height: 16),
              _buildLanguageCard(
                context: context,
                title: 'English',
                subtitle: 'Use app in English',
                langCode: 'en',
                primaryGreen: primaryGreen,
                accentGold: accentGold,
              ),

              const Spacer(),
              Center(
                child: Text(
                  'प्राचीन वैदिक ज्ञान • आधुनिक हवामान शास्त्र',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String langCode,
    required Color primaryGreen,
    required Color accentGold,
  }) {
    return InkWell(
      onTap: () => _selectLanguage(context, langCode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: primaryGreen.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.language,
                color: primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: accentGold,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
