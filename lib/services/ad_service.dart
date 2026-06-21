import 'package:flutter/material.dart';
import 'package:startapp_sdk/startapp.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  StartAppInterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  VoidCallback? _activeDismissCallback;

  /// Check if the current logged-in user should be in test/admin mode
  bool get isAdminUser {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase();
    return user != null &&
        (email == 'vasant.1982patil@gmail.com' ||
         email == 'vasant.1982@gmail.com');
  }

  /// Initialize Start.io Ads SDK
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('Start.io: Initializing SDK (testMode: $isAdminUser)...');
      
      // Enable/disable test ads based on admin status
      StartAppSdk().setTestAdsEnabled(isAdminUser);
      
      _initialized = true;
      print('Start.io: SDK Initialized successfully.');
      _loadInterstitial();
    } catch (e) {
      print('Start.io: SDK Initialization exception: $e');
    }
  }

  // --- INTERSTITIAL AD IMPLEMENTATION ---

  void _loadInterstitial() {
    if (!_initialized || _isInterstitialLoading) return;
    
    _isInterstitialLoading = true;
    print('Start.io: Preloading interstitial ad...');
    
    StartAppSdk().loadInterstitialAd(
      onAdDisplayed: () {
        print('Start.io: Interstitial ad displayed.');
      },
      onAdHidden: () {
        print('Start.io: Interstitial ad closed.');
        _interstitialAd?.dispose();
        _interstitialAd = null;
        
        // Trigger screen callback
        final callback = _activeDismissCallback;
        _activeDismissCallback = null;
        callback?.call();
        
        // Preload next ad
        _loadInterstitial();
      },
    ).then((ad) {
      _interstitialAd = ad;
      _isInterstitialLoading = false;
      print('Start.io: Interstitial ad loaded successfully.');
    }).catchError((error) {
      _isInterstitialLoading = false;
      print('Start.io: Interstitial ad load failed: $error');
      
      // If there was an active callback waiting for this ad, release it
      final callback = _activeDismissCallback;
      _activeDismissCallback = null;
      callback?.call();
      
      // Retry loading after a short delay
      Future.delayed(const Duration(seconds: 15), () => _loadInterstitial());
    });
  }

  /// Show Interstitial ad with a callback on completion
  Future<void> showInterstitialAd(VoidCallback onDismissed) async {
    if (!_initialized) {
      onDismissed();
      return;
    }

    if (_interstitialAd != null) {
      try {
        _activeDismissCallback = onDismissed;
        print('Start.io: Showing preloaded interstitial.');
        _interstitialAd!.show();
      } catch (e) {
        print('Start.io: Error showing interstitial: $e');
        _activeDismissCallback = null;
        onDismissed();
        _loadInterstitial();
      }
    } else {
      print('Start.io: Interstitial not ready. Proceeding immediately.');
      onDismissed();
      _loadInterstitial();
    }
  }

  // --- BANNER AD WIDGET IMPLEMENTATION ---

  /// Returns a Banner Ad widget or a placeholder
  Widget getBannerWidget(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// A stateful wrapper widget that loads and renders the Start.io banner ad
class StartIoBannerWidget extends StatefulWidget {
  const StartIoBannerWidget({super.key});

  @override
  State<StartIoBannerWidget> createState() => _StartIoBannerWidgetState();
}

class _StartIoBannerWidgetState extends State<StartIoBannerWidget> {
  StartAppBannerAd? _bannerAd;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    StartAppSdk().loadBannerAd(StartAppBannerType.BANNER).then((ad) {
      if (mounted) {
        setState(() {
          _bannerAd = ad;
          _loading = false;
        });
      }
    }).catchError((error) {
      print('Start.io: Banner ad load failed: $error');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: StartAppBanner(_bannerAd!),
    );
  }
}
