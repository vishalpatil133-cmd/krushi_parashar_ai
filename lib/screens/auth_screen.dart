import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';
import '../models/prediction.dart';
import '../models/crop_scan.dart';
import 'home_dashboard.dart';
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getMarathiErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'या ईमेल आयडीवर कोणतेही खाते आढळले नाही.';
      case 'wrong-password':
        return 'कृपया योग्य पासवर्ड टाका.';
      case 'email-already-in-use':
        return 'हा ईमेल आयडी आधीच नोंदणीकृत आहे.';
      case 'invalid-email':
        return 'कृपया योग्य ईमेल आयडी प्रविष्ट करा.';
      case 'weak-password':
        return 'पासवर्ड किमान ६ अक्षरांचा असावा.';
      case 'network-request-failed':
        return 'कृपया तुमची इंटरनेट जोडणी (Network Connection) तपासा.';
      default:
        return 'काहीतरी त्रुटी आली ($code). कृपया पुन्हा प्रयत्न करा.';
    }
  }

  Future<void> _handlePostAuth(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final oldId = prefs.getString('user_profile_id');

    // Check if the old ID exists and represents a guest/farmer ID
    if (oldId != null && oldId.startsWith('farmer_') && oldId != user.uid) {
      print('Migrating guest user data from $oldId to ${user.uid}');

      // 1. Migrate predictions history
      final oldPredictionsKey = 'predictions_history_$oldId';
      final newPredictionsKey = 'predictions_history_${user.uid}';
      final predictionsList = prefs.getStringList(oldPredictionsKey);
      if (predictionsList != null && predictionsList.isNotEmpty) {
        await prefs.setStringList(newPredictionsKey, predictionsList);
        // Sync them to Firebase Realtime Database under the new user.uid
        for (var jsonStr in predictionsList) {
          try {
            final map = json.decode(jsonStr) as Map<dynamic, dynamic>;
            final ts = map['timestamp'] as String? ?? '';
            final prediction = PredictionModel.fromMap(map, ts);
            await _dbService.savePrediction(user.uid, prediction);
          } catch (e) {
            print('Error migrating prediction: $e');
          }
        }
      }

      // 2. Migrate crop scans history
      final oldScansKey = 'crop_scans_history_$oldId';
      final newScansKey = 'crop_scans_history_${user.uid}';
      final scansList = prefs.getStringList(oldScansKey);
      if (scansList != null && scansList.isNotEmpty) {
        await prefs.setStringList(newScansKey, scansList);
        // Sync them to Firebase Realtime Database under the new user.uid
        for (var jsonStr in scansList) {
          try {
            final map = json.decode(jsonStr) as Map<dynamic, dynamic>;
            final ts = map['timestamp'] as String? ?? '';
            final scan = CropScanModel.fromMap(map, ts);
            await _dbService.saveCropScan(user.uid, scan);
          } catch (e) {
            print('Error migrating crop scan: $e');
          }
        }
      }

      // 3. Migrate user profile
      final name = prefs.getString('user_profile_name');
      final location = prefs.getString('user_profile_location');
      final crop = prefs.getString('user_profile_crop');
      if (name != null && location != null && crop != null) {
        final newProfile = UserProfile(
          id: user.uid,
          name: name,
          location: location,
          primaryCrop: crop,
        );
        await _dbService.saveUserProfile(newProfile);
      }
    }

    // Set the active session ID
    await prefs.setString('user_profile_id', user.uid);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential;
      if (_isLogin) {
        // Sign In
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Sign Up
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = userCredential.user;
      if (user != null) {
        // Perform guest migration and update user ID in session
        await _handlePostAuth(user);

        // Check if user has an existing profile
        final profile = await _dbService.getUserProfile(user.uid);

        if (!mounted) return;

        if (profile != null) {
          // Profile exists -> Direct to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDashboard(userId: user.uid),
            ),
          );
        } else {
          // New user without profile -> Direct to setup profile screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getMarathiErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'त्रुटी: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Perform guest migration and update user ID in session
        await _handlePostAuth(user);

        final profile = await _dbService.getUserProfile(user.uid);

        if (!mounted) return;

        if (profile != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDashboard(userId: user.uid),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getMarathiErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'गुगल लॉगिन त्रुटी: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.agritech.krishi-parashara-ai-service',
          redirectUri: Uri.parse('https://gw-parashar-ai-based.firebaseapp.com/__/auth/handler'),
        ),
      );

      final OAuthProvider provider = OAuthProvider('apple.com');
      final AuthCredential authCredential = provider.credential(
        idToken: credential.identityToken,
        rawNonce: null,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(authCredential);
      final user = userCredential.user;

      if (user != null) {
        // Perform guest migration and update user ID in session
        await _handlePostAuth(user);

        final profile = await _dbService.getUserProfile(user.uid);

        if (!mounted) return;

        if (profile != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDashboard(userId: user.uid),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        }
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      setState(() {
        if (e.code == AuthorizationErrorCode.canceled) {
          _errorMessage = 'ॲपल लॉगिन रद्द केले गेले.';
        } else {
          _errorMessage = 'ॲपल लॉगिन त्रुटी: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ॲपल लॉगिन त्रुटी: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentGold, width: 2),
                ),
                child: const Icon(
                  Icons.eco,
                  size: 48,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'कृषि पराशर AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'वैदिक शेती सल्लागार ॲप',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Form Card
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'लॉगिन (प्रवेश करा)' : 'नवीन शेतकरी नोंदणी',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'ईमेल आयडी (Email ID)',
                            prefixIcon: const Icon(Icons.email_outlined, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'कृपया ईमेल आयडी प्रविष्ट करा';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'कृपया योग्य ईमेल आयडी प्रविष्ट करा';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'पासवर्ड (किमान ६ अक्षरे)',
                            prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'कृपया पासवर्ड प्रविष्ट करा';
                            }
                            if (value.length < 6) {
                              return 'पासवर्ड किमान ६ अक्षरांचा असावा';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isLogin ? 'प्रवेश करा' : 'नोंदणी करा',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Switch State Button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'नवीन खाते तयार करायचे आहे? येथे नोंदणी करा'
                                : 'आधीच नोंदणी केली आहे? लॉगिन करा',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text('किंवा', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ),
                            Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Sign-In Button
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: Image.network(
                              'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                              height: 20,
                              width: 20,
                            ),
                            label: const Text(
                              'Google द्वारे लॉगिन करा',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Apple Sign-In Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _signInWithApple,
                            icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                            label: const Text(
                              'Apple द्वारे लॉगिन करा',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
