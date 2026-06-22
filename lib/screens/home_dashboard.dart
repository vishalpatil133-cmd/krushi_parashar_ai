import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/prediction.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../services/gemini_service.dart';
import '../services/ad_service.dart';
import 'prediction_result_screen.dart';
import 'profile_setup_screen.dart';
import 'radar_screen.dart';
import 'pest_advisor_screen.dart';
import 'fertilizer_advisor_screen.dart';
import 'agri_tools_marketplace_screen.dart';
import 'market_prices_screen.dart';
import 'general_chat_screen.dart';
import 'farm_calculator_screen.dart';
import 'crop_health_check_screen.dart';
import 'voice_assistant_screen.dart';

import '../main.dart';
import 'community_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'video_guide_screen.dart';
import 'admin_panel_screen.dart';
import '../services/notification_service.dart';
import '../components/floating_notification.dart';
import 'notification_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/translation_service.dart';
import '../config/secrets.dart';

class HomeDashboard extends StatefulWidget {
  final String userId;
  const HomeDashboard({super.key, required this.userId});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _dbService = DatabaseService();
  final _weatherService = WeatherService();
  final _geminiService = GeminiService();

  UserProfile? _profile;
  WeatherData? _currentWeather;
  List<PredictionModel> _history = [];
  bool _isLoadingProfile = true;
  bool _isLoadingWeather = true;
  bool _isLoadingHistory = true;
  bool _isGenerating = false;

  Offset _fabPosition = const Offset(0, 0);
  bool _isFabInitialized = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadProfile();
    if (_profile != null) {
      _fetchCurrentWeather();
      _loadHistory();
      _initNotifications();
      _checkAppUpdate();
    }
  }

  void _initNotifications() {
    NotificationService.instance.initialize(
      onNewNotification: (notification) {
        if (mounted) {
          FloatingNotification.show(
            context,
            notification,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationListScreen(
                    userId: widget.userId,
                    userName: _profile?.name ?? tr('farmer_name'),
                  ),
                ),
              );
            },
          );
        }
      },
    ).then((_) {
      NotificationService.instance.generateDailyVedicNotification();
    });
    NotificationService.instance.listenToUserNotifications(widget.userId);
  }


  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    final profile = await _dbService.getUserProfile(widget.userId);
    setState(() {
      _profile = profile;
      _isLoadingProfile = false;
    });
  }

  Future<void> _fetchCurrentWeather() async {
    if (_profile == null) return;
    setState(() => _isLoadingWeather = true);
    try {
      final weather = await _weatherService.fetchWeather(_profile!.location);
      setState(() {
        _currentWeather = weather;
        _isLoadingWeather = false;
      });
    } catch (e) {
      print('Dashboard Weather Fetch Error: $e');
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _dbService.getPredictionsHistory(widget.userId);
    setState(() {
      _history = history;
      _isLoadingHistory = false;
    });
  }

  // Dynamic Nakshatra in Marathi Devnagari
  String _getNakshatra() {
    final nakshatras = [
      'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशीर्ष', 'आर्द्रा',
      'पुनर्वसू', 'पुष्य', 'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी',
      'हस्त', 'चित्रा', 'स्वाती', 'विशाखा', 'अनुराधा', 'ज्येष्ठा',
      'मूळ', 'पूर्वाषाढा', 'उत्तराषाढा', 'श्रावण', 'धनिष्ठा',
      'शततारका', 'पूर्वाभाद्रपदा', 'उत्तराभाद्रपदा', 'रेवती'
    ];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = (dayOfYear + now.year) % 27;
    return '${nakshatras[index]} नक्षत्र';
  }

  // Dynamic Lunar Tithi in Marathi Devnagari
  String _getPanchangTithi() {
    final tithis = [
      'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पंचमी', 'षष्ठी',
      'सप्तमी', 'अष्टमी', 'नवमी', 'दशमी', 'एकादशी', 'द्वादशी',
      'त्रयोदशी', 'चतुर्दशी', 'पौर्णिमा/अमावास्या'
    ];
    final now = DateTime.now();
    final index = (now.day + now.month) % 15;
    final paksha = now.day > 15 ? 'कृष्ण पक्ष' : 'शुक्ल पक्ष';
    return '$paksha - ${tithis[index]}';
  }

  Future<void> _generatePrediction() async {
    if (_profile == null) return;
    
    await AdService.instance.showInterstitialAd(() async {
      if (!mounted) return;
      setState(() => _isGenerating = true);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: const Color(0xFFFAFAF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A93B)),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('generating_advice'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E5631),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('generating_advice_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      try {
        // 1. Fetch live weather
        final weather = await _weatherService.fetchWeather(_profile!.location);
        
        // 2. Query Gemini API
        final geminiResult = await _geminiService.generateVedicPrediction(
          farmerName: _profile!.name,
          location: _profile!.location,
          primaryCrop: _profile!.primaryCrop,
          weather: weather,
        );

        // 3. Format timestamp
        final String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

        // 4. Create prediction model
        final prediction = PredictionModel(
          timestamp: formattedDate,
          liveTemp: weather.temp,
          shortTermForecast: geminiResult.shortTerm,
          vedicLongTermForecast: geminiResult.vedicLongTerm,
          liveHumidity: weather.humidity,
          liveWindSpeed: weather.windSpeed,
        );

        // 5. Save to database
        await _dbService.savePrediction(_profile!.id, prediction);

        // Dismiss dialog
        if (mounted) Navigator.pop(context);

        // Reload history & update weather
        await _loadHistory();
        if (mounted) {
          setState(() {
            _currentWeather = weather;
          });
        }

        // Navigate to Prediction Result Screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PredictionResultScreen(prediction: prediction),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('advice_error') + e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isGenerating = false);
        }
      }
    });
  }

  bool get _isAdmin {
    final name = _profile?.name.toLowerCase() ?? '';
    final uid = widget.userId.toLowerCase();
    final currentUser = FirebaseAuth.instance.currentUser;
    final email = currentUser?.email?.toLowerCase() ?? '';
    return name.contains('admin') ||
        uid == 'admin' ||
        uid == 'admin_user' ||
        email == 'vasant.1982patil@gmail.com' ||
        email == 'vasant.1982@gmail.com';
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile_id');
    await prefs.remove('user_profile_name');
    await prefs.remove('user_profile_location');
    await prefs.remove('user_profile_crop');
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  void _showEditProfileDialog() {
    if (_profile == null) return;

    final nameController = TextEditingController(text: _profile!.name);
    String? tempLocation = _profile!.location;
    String? tempCrop = _profile!.primaryCrop;
    final formKey = GlobalKey<FormState>();

    // Reset temporary variables if they are not in the predefined lists to prevent errors
    if (!UserProfile.locations.contains(tempLocation)) {
      tempLocation = null;
    }
    if (!UserProfile.crops.contains(tempCrop)) {
      tempCrop = null;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        const primaryGreen = Color(0xFF1E5631);
        const accentGold = Color(0xFFE5A93B);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAFAF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(
                tr('edit_profile_dialog_title'),
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('farmer_name'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: primaryGreen, size: 20),
                          hintText: tr('name_hint'),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr('enter_name_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr('farm_location'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: tempLocation,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined, color: primaryGreen, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        hint: Text(tr('select_district'), style: const TextStyle(fontSize: 11)),
                        items: UserProfile.locations.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            tempLocation = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr('select_district_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tr('select_crop'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: tempCrop,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.agriculture_outlined, color: primaryGreen, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: primaryGreen, width: 2),
                          ),
                        ),
                        hint: Text(tr('select_crop'), style: const TextStyle(fontSize: 11)),
                        items: UserProfile.crops.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setStateDialog(() {
                            tempCrop = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr('select_crop_error');
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      
                      setState(() {
                        _isLoadingProfile = true;
                      });
                      try {
                        final updatedProfile = UserProfile(
                          id: _profile!.id,
                          name: nameController.text.trim(),
                          location: tempLocation!,
                          primaryCrop: tempCrop!,
                        );
                        
                        await _dbService.saveUserProfile(updatedProfile);
                        
                        if (!mounted) return;
                        setState(() {
                          _profile = updatedProfile;
                        });
                        
                        _fetchCurrentWeather();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('advice_error') + e.toString())),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoadingProfile = false;
                          });
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAF7),
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)),
        ),
      );
    }

    if (_profile == null) {
      return const ProfileSetupScreen();
    }

    if (!_isFabInitialized) {
      final size = MediaQuery.of(context).size;
      final statusBarHeight = MediaQuery.of(context).padding.top;
      final appBarHeight = AppBar().preferredSize.height;
      _fabPosition = Offset(
        size.width - 76.0,
        size.height - statusBarHeight - appBarHeight - 140.0,
      );
      _isFabInitialized = true;
    }

    final List<Widget> pages = [
      _buildHomeBody(context),
      CommunityScreen(
        userId: widget.userId,
        userName: _profile?.name ?? tr('farmer_name'),
      ),
      const VideoGuideScreen(),
      const GeneralChatScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: primaryGreen.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdService.instance.getBannerWidget(context),
              BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: primaryGreen,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                unselectedLabelStyle: const TextStyle(fontSize: 9),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined, size: 22),
                    activeIcon: const Icon(Icons.home, size: 22),
                    label: tr('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.people_outline, size: 22),
                    activeIcon: const Icon(Icons.people, size: 22),
                    label: tr('community'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.video_library_outlined, size: 22),
                    activeIcon: const Icon(Icons.video_library, size: 22),
                    label: tr('video_guide'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.chat_bubble_outline, size: 22),
                    activeIcon: const Icon(Icons.chat_bubble, size: 22),
                    label: tr('general_chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      appBar: _currentIndex == 0 ? _buildHomeAppBar(context) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      endDrawer: _buildRightDrawer(context),
    );
  }

  AppBar _buildHomeAppBar(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    return AppBar(
      leading: ValueListenableBuilder<int>(
        valueListenable: NotificationService.instance.unreadCount,
        builder: (context, count, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationListScreen(
                        userId: widget.userId,
                        userName: _profile?.name ?? tr('farmer_name'),
                      ),
                    ),
                  );
                },
              ),
              if (count > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      title: Text(
        tr('app_title'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: primaryGreen,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.g_translate_rounded, color: Colors.white),
          onPressed: () => _showLanguageSelectorDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            _fetchCurrentWeather();
            _loadHistory();
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);
    return Stack(
      children: [
          RefreshIndicator(
        onRefresh: () async {
          await _fetchCurrentWeather();
          await _loadHistory();
        },
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'नमस्ते,',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                _profile!.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Weather Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accentGold.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thermostat, color: accentGold, size: 20),
                              const SizedBox(width: 4),
                              _isLoadingWeather
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1.5,
                                      ),
                                    )
                                  : Text(
                                      _currentWeather?.temp ?? '--',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Responsive wrap to prevent 38-pixel overflow on small devices
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.brightness_5_rounded, color: accentGold, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _getPanchangTithi(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.brightness_3_rounded, color: accentGold, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _getNakshatra(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_profile!.location} • मुख्य पीक: ${_profile!.primaryCrop}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  tr('change'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ACTION CARD - Generate Prediction
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: accentGold.withOpacity(0.2), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentGold.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: accentGold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('get_vedic_advice_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('get_vedic_advice_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : _generatePrediction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            tr('get_vedic_advice_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // RADAR MAP CARD - Live Radar Map
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('live_radar_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('live_radar_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            final lat = _currentWeather?.latitude ?? 18.52;
                            final lon = _currentWeather?.longitude ?? 73.85;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RadarScreen(latitude: lat, longitude: lon),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('live_radar_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // PEST ADVISOR CARD - Organic Pest & Disease Advisor
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bug_report_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('pest_advisor_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('pest_advisor_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PestAdvisorScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('pest_advisor_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // FERTILIZER ADVISOR CARD - Fertilizer Advisor & Calculator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.science_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('fertilizer_advisor_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('fertilizer_advisor_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FertilizerAdvisorScreen(weather: _currentWeather),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('fertilizer_advisor_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // FARM CALCULATOR CARD - Budget and Expense calculator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calculate_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('farm_calculator_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('farm_calculator_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FarmCalculatorScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('farm_calculator_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // AGRI-TOOLS MARKETPLACE CARD - Agricultural tools store
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('tools_marketplace_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('tools_marketplace_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AgriToolsMarketplaceScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('tools_marketplace_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // LIVE MARKET COMMITTEE PRICES CARD - Bajarbhav
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: primaryGreen.withOpacity(0.12), width: 1.2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: primaryGreen,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('market_prices_card_title'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('market_prices_card_desc'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MarketPricesScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 1.5),
                            foregroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            tr('market_prices_btn'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // HISTORY LIST SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  tr('previous_advice_header'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _isLoadingHistory
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                        ),
                      ),
                    )
                  : _history.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_edu_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tr('no_advice_taken'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tr('no_advice_taken_desc'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final pred = _history[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                              child: Card(
                                color: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PredictionResultScreen(prediction: pred),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: primaryGreen.withOpacity(0.06),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today_outlined,
                                            color: primaryGreen,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pred.timestamp,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryGreen,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'तापमान: ${pred.liveTemp} | अंदाज: ${_getSnippet(pred.shortTermForecast)}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      Positioned(
        left: _fabPosition.dx,
        top: _fabPosition.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final size = MediaQuery.of(context).size;
              final statusBarHeight = MediaQuery.of(context).padding.top;
              final appBarHeight = AppBar().preferredSize.height;
              
              double newX = _fabPosition.dx + details.delta.dx;
              double newY = _fabPosition.dy + details.delta.dy;
              
              newX = newX.clamp(16.0, size.width - 76.0);
              newY = newY.clamp(16.0, size.height - statusBarHeight - appBarHeight - 96.0);
              
              _fabPosition = Offset(newX, newY);
            });
          },
          onTap: () {
            _showGeminiOptionsBottomSheet(context);
          },
          child: _buildFloatingButton(context),
        ),
      ),
    ],
  );
}

  String _getSnippet(String text) {
    if (text.length > 35) {
      return '${text.substring(0, 32)}...';
    }
    return text;
  }

  Widget _buildFloatingButton(BuildContext context) {
    const accentGold = Color(0xFFE5A93B);
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [accentGold, Color(0xFFF3C677)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentGold.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  void _showGeminiOptionsBottomSheet(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF7),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('vedic_assistant_header'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('vedic_assistant_desc'),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: primaryGreen.withOpacity(0.15), width: 1.5),
                ),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GeneralChatScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: primaryGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('ask_anything_title'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('ask_anything_desc'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: accentGold.withOpacity(0.25), width: 1.5),
                ),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceAssistantScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_voice_outlined,
                            color: accentGold,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'एआय बोलणारा मित्र (Voice Assistant)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'तुमचे प्रश्न थेट बोलून विचारण्यासाठी आणि ऐकण्यासाठी',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: accentGold.withOpacity(0.25), width: 1.5),
                ),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropHealthCheckScreen(userId: widget.userId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: accentGold,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('disease_scan_title'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('disease_scan_desc'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: accentGold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightDrawer(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return Drawer(
      backgroundColor: const Color(0xFFFAFAF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: accentGold,
              child: Text(
                _profile?.name.isNotEmpty == true ? _profile!.name[0].toUpperCase() : 'शे',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            accountName: Text(
              _profile?.name ?? tr('farmer_name'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              tr('crop_location_subtitle').replaceAll('\$crop', _profile?.primaryCrop ?? '...').replaceAll('\$loc', _profile?.location ?? '...'),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: primaryGreen),
                  title: Text(
                    tr('edit_profile_dialog_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('change_profile_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.group_outlined, color: primaryGreen),
                  title: Text(
                    tr('community_forum_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('community_forum_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CommunityScreen(
                          userId: widget.userId,
                          userName: _profile?.name ?? tr('farmer_name'),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.video_library_outlined, color: primaryGreen),
                  title: Text(
                    tr('video_guides_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('video_guides_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoGuideScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),

                if (_isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: primaryGreen),
                    title: Text(
                      tr('admin_panel_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(tr('admin_panel_subtitle')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminPanelScreen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],

                ValueListenableBuilder<bool>(
                  valueListenable: MyApp.isDarkMode,
                  builder: (context, isDark, child) {
                    return SwitchListTile(
                      activeColor: primaryGreen,
                      secondary: const Icon(Icons.dark_mode_outlined, color: primaryGreen),
                      title: Text(
                        tr('dark_mode_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(tr('dark_mode_subtitle')),
                      value: isDark,
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_dark_mode', val);
                        MyApp.isDarkMode.value = val;
                      },
                    );
                  },
                ),
                const Divider(),
                
                StatefulBuilder(
                  builder: (context, setState) {
                    return FutureBuilder<bool>(
                      future: SharedPreferences.getInstance().then((p) => p.getBool('weather_alerts_enabled') ?? true),
                      builder: (context, snapshot) {
                        final isEnabled = snapshot.data ?? true;
                        return SwitchListTile(
                          activeColor: primaryGreen,
                          secondary: const Icon(Icons.notifications_none, color: primaryGreen),
                          title: Text(
                            tr('weather_alert_title'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(tr('weather_alert_subtitle')),
                          value: isEnabled,
                          onChanged: (val) async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('weather_alerts_enabled', val);
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.info_outline, color: primaryGreen),
                  title: Text(
                    tr('about_app_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('about_app_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    _showAppInfoDialog(context);
                  },
                ),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.security_outlined, color: primaryGreen),
                  title: Text(
                    tr('privacy_policy_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('privacy_policy_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    _showPrivacyPolicyDialog(context);
                  },
                ),
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.help_outline, color: primaryGreen),
                  title: Text(
                    tr('help_contact_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(tr('help_contact_subtitle')),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('contact_service_soon'))),
                    );
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                tr('logout_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC84B31),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFFFAFAF7),
          title: Row(
            children: [
              const Icon(Icons.info, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                tr('about_app_dialog_title'),
                style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('app_title'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryGreen),
              ),
              const SizedBox(height: 6),
              Text(tr('version')),
              const SizedBox(height: 12),
              Text(
                tr('vedic_wisdom'),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok'), style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFFFAFAF7),
          title: Row(
            children: [
              const Icon(Icons.security, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                tr('privacy_policy_dialog_title'),
                style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('privacy_policy_subtitle'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('privacy_policy_item1'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('privacy_policy_item2'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('privacy_policy_item3'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('privacy_policy_footer'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok'), style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogoutDialog(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFFFAFAF7),
          title: Text(
            tr('logout_confirm_title'),
            style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Text(tr('logout_confirm_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'), style: const TextStyle(color: primaryGreen)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: Text(tr('logout_title'), style: const TextStyle(color: Color(0xFFC84B31), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAppUpdate() async {
    try {
      final DatabaseReference updateRef;
      final url = Secrets.firebaseDatabaseUrl;
      if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
        updateRef = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: url,
        ).ref('app_update');
      } else {
        updateRef = FirebaseDatabase.instance.ref('app_update');
      }

      final event = await updateRef.once();
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final int dbVersion = data['version_code'] as int? ?? 2002;
        final String updateUrl = data['update_url'] as String? ?? '';
        final String updateDesc = data['update_desc'] as String? ?? 'नवीन अपडेट उपलब्ध आहे.';
        final bool isForce = data['is_force'] as bool? ?? false;

        const int currentVersionCode = 2002;
        if (dbVersion > currentVersionCode && updateUrl.isNotEmpty) {
          if (!mounted) return;
          _showUpdateDialog(updateUrl, updateDesc, isForce);
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  void _showUpdateDialog(String updateUrl, String updateDesc, bool isForce) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (context) {
        const primaryGreen = Color(0xFF1E5631);
        const accentGold = Color(0xFFE5A93B);
        return PopScope(
          canPop: !isForce,
          child: AlertDialog(
            backgroundColor: const Color(0xFFFAFAF7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: primaryGreen, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isForce ? tr('force_update_title') : tr('update_available'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryGreen),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  updateDesc,
                  style: const TextStyle(fontSize: 11, height: 1.4),
                ),
                if (isForce) ...[
                  const SizedBox(height: 12),
                  Text(
                    tr('force_update_message'),
                    style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isForce)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('update_later'), style: const TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(tr('update_now')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        const primaryGreen = Color(0xFF1E5631);
        return AlertDialog(
          backgroundColor: const Color(0xFFFAFAF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            tr('select_language'),
            style: const TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogLanguageOption(context, 'मराठी (Marathi)', 'mr', primaryGreen),
              const Divider(),
              _buildDialogLanguageOption(context, 'हिंदी (Hindi)', 'hi', primaryGreen),
              const Divider(),
              _buildDialogLanguageOption(context, 'English', 'en', primaryGreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogLanguageOption(BuildContext context, String name, String code, Color primaryColor) {
    final isSelected = MyApp.selectedLanguage.value == code;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', code);
        MyApp.selectedLanguage.value = code;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }
}
