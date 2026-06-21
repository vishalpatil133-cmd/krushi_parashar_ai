import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';
import '../models/user_profile.dart';
import '../models/prediction.dart';
import '../models/crop_scan.dart';

class DatabaseService {
  FirebaseDatabase? get _db {
    try {
      if (Firebase.apps.isNotEmpty) {
        final url = Secrets.firebaseDatabaseUrl;
        if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
          return FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: url,
          );
        }
      }
    } catch (e) {
      print('Firebase Database instance error: $e');
    }
    return null;
  }

  bool get _isFirebaseEnabled {
    try {
      if (Firebase.apps.isEmpty) return false;
      final url = Secrets.firebaseDatabaseUrl;
      return url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE');
    } catch (_) {
      return false;
    }
  }

  // --- USER PROFILE OPERATIONS ---

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Always store profile locally in SharedPrefs for instant offline load
    await prefs.setString('user_profile_name', profile.name);
    await prefs.setString('user_profile_location', profile.location);
    await prefs.setString('user_profile_crop', profile.primaryCrop);
    await prefs.setString('user_profile_id', profile.id);

    if (_isFirebaseEnabled) {
      try {
        final ref = _db!.ref('users/${profile.id}');
        await ref.set(profile.toMap());
        print('Profile successfully synced to Firebase Database.');
      } catch (e) {
        print('Firebase sync failed: $e. Kept locally.');
      }
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_profile_name');
    final location = prefs.getString('user_profile_location');
    final crop = prefs.getString('user_profile_crop');
    final storedId = prefs.getString('user_profile_id');

    // If local cache matches, return it immediately
    if (name != null && location != null && crop != null && storedId == userId) {
      return UserProfile(id: userId, name: name, location: location, primaryCrop: crop);
    }

    if (_isFirebaseEnabled) {
      try {
        final ref = _db!.ref('users/$userId');
        final snapshot = await ref.get().timeout(const Duration(seconds: 4));
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final profile = UserProfile.fromMap(data, userId);
          
          // Cache locally
          await saveUserProfile(profile);
          return profile;
        }
      } catch (e) {
        print('Firebase fetch profile failed: $e. Checking local storage.');
      }
    }
    return null;
  }

  // --- PREDICTIONS OPERATIONS ---

  Future<void> savePrediction(String userId, PredictionModel prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'predictions_history_$userId';
    
    // Load local history list
    final historyJsonList = prefs.getStringList(historyKey) ?? [];
    
    // Prepare map
    final predictionData = {
      'timestamp': prediction.timestamp,
      'live_temp': prediction.liveTemp,
      'short_term_forecast': prediction.shortTermForecast,
      'vedic_long_term_forecast': prediction.vedicLongTermForecast,
      'live_humidity': prediction.liveHumidity,
      'live_wind_speed': prediction.liveWindSpeed,
    };
    
    // Prepend to show newest first locally
    historyJsonList.insert(0, json.encode(predictionData));
    
    // Limit local history to 5 elements
    while (historyJsonList.length > 5) {
      historyJsonList.removeLast();
    }
    
    await prefs.setStringList(historyKey, historyJsonList);

    if (_isFirebaseEnabled) {
      try {
        // Standardize timestamp for Firebase path
        final pathTimestamp = prediction.timestamp
            .replaceAll('.', '_')
            .replaceAll(':', '_')
            .replaceAll(' ', '_')
            .replaceAll('-', '_');
        
        final ref = _db!.ref('predictions/$userId/$pathTimestamp');
        await ref.set(prediction.toMap());
        print('Prediction successfully synced to Firebase Realtime Database.');
        
        // Trim Firebase history to keep only 5 newest items
        final userRef = _db!.ref('predictions/$userId');
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (data.length > 5) {
            final sortedKeys = data.keys.toList()..sort();
            final keysToDeleteCount = data.length - 5;
            for (int i = 0; i < keysToDeleteCount; i++) {
              final keyToDelete = sortedKeys[i];
              await userRef.child(keyToDelete.toString()).remove();
              print('Trimmed oldest prediction from Firebase: $keyToDelete');
            }
          }
        }
      } catch (e) {
        print('Firebase prediction sync failed: $e. Saved locally.');
      }
    }
  }

  Future<List<PredictionModel>> getPredictionsHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'predictions_history_$userId';
    List<PredictionModel> localPredictions = [];

    // Load local data
    final historyJsonList = prefs.getStringList(historyKey) ?? [];
    for (var jsonStr in historyJsonList) {
      try {
        final map = json.decode(jsonStr) as Map<dynamic, dynamic>;
        final ts = map['timestamp'] as String? ?? '';
        localPredictions.add(PredictionModel.fromMap(map, ts));
      } catch (e) {
        print('Failed to parse cached prediction: $e');
      }
    }

    if (_isFirebaseEnabled) {
      try {
        final ref = _db!.ref('predictions/$userId');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          List<PredictionModel> firebasePredictions = [];
          
          data.forEach((key, value) {
            final mapVal = value as Map<dynamic, dynamic>;
            final formattedTimestamp = key.toString().replaceAll('_', ' ');
            firebasePredictions.add(PredictionModel.fromMap(mapVal, formattedTimestamp));
          });

          // Sort by timestamp descending
          firebasePredictions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Sync local storage with Firebase list
          final syncedJsonList = firebasePredictions.map((p) => json.encode({
            'timestamp': p.timestamp,
            'live_temp': p.liveTemp,
            'short_term_forecast': p.shortTermForecast,
            'vedic_long_term_forecast': p.vedicLongTermForecast,
            'live_humidity': p.liveHumidity,
            'live_wind_speed': p.liveWindSpeed,
          })).toList();
          
          await prefs.setStringList(historyKey, syncedJsonList);
          return firebasePredictions;
        }
      } catch (e) {
        print('Firebase fetch predictions failed: $e. Using local database.');
      }
    }

    return localPredictions;
  }

  // --- DISEASE SCANS OPERATIONS ---

  Future<void> saveCropScan(String userId, CropScanModel scan) async {
    final prefs = await SharedPreferences.getInstance();
    final scansKey = 'crop_scans_history_$userId';

    // Load local history list
    final scansJsonList = prefs.getStringList(scansKey) ?? [];

    // Prepare map
    final scanData = {
      'timestamp': scan.timestamp,
      'crop_type': scan.cropType,
      'disease_name': scan.diseaseName,
      'symptoms': scan.symptoms,
      'remedy': scan.remedy,
      'recipe': scan.recipe,
      if (scan.localImagePath != null) 'local_image_path': scan.localImagePath,
    };

    // Prepend to show newest first
    scansJsonList.insert(0, json.encode(scanData));

    // Limit local history to 5 elements
    while (scansJsonList.length > 5) {
      scansJsonList.removeLast();
    }

    await prefs.setStringList(scansKey, scansJsonList);

    if (_isFirebaseEnabled) {
      try {
        // Standardize timestamp for Firebase path
        final pathTimestamp = scan.timestamp
            .replaceAll('.', '_')
            .replaceAll(':', '_')
            .replaceAll(' ', '_')
            .replaceAll('-', '_');

        final ref = _db!.ref('disease_scans/$userId/$pathTimestamp');
        await ref.set(scan.toMap());
        print('Crop scan successfully synced to Firebase Database.');

        // Trim Firebase history to keep only 5 newest items
        final userRef = _db!.ref('disease_scans/$userId');
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          if (data.length > 5) {
            final sortedKeys = data.keys.toList()..sort();
            final keysToDeleteCount = data.length - 5;
            for (int i = 0; i < keysToDeleteCount; i++) {
              final keyToDelete = sortedKeys[i];
              await userRef.child(keyToDelete.toString()).remove();
              print('Trimmed oldest crop scan from Firebase: $keyToDelete');
            }
          }
        }
      } catch (e) {
        print('Firebase crop scan sync failed: $e. Saved locally.');
      }
    }
  }

  Future<List<CropScanModel>> getCropScansHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final scansKey = 'crop_scans_history_$userId';
    List<CropScanModel> localScans = [];

    // Load local data
    final scansJsonList = prefs.getStringList(scansKey) ?? [];
    for (var jsonStr in scansJsonList) {
      try {
        final map = json.decode(jsonStr) as Map<dynamic, dynamic>;
        final ts = map['timestamp'] as String? ?? '';
        localScans.add(CropScanModel.fromMap(map, ts));
      } catch (e) {
        print('Failed to parse cached crop scan: $e');
      }
    }

    if (localScans.length > 5) {
      localScans = localScans.sublist(0, 5);
    }

    if (_isFirebaseEnabled) {
      try {
        final ref = _db!.ref('disease_scans/$userId');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          List<CropScanModel> firebaseScans = [];

          data.forEach((key, value) {
            final mapVal = value as Map<dynamic, dynamic>;
            final formattedTimestamp = key.toString().replaceAll('_', ' ');
            firebaseScans.add(CropScanModel.fromMap(mapVal, formattedTimestamp));
          });

          // Sort by timestamp descending
          firebaseScans.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Limit to 5
          if (firebaseScans.length > 5) {
            firebaseScans = firebaseScans.sublist(0, 5);
          }

          // Sync local storage with Firebase list
          final syncedJsonList = firebaseScans.map((s) => json.encode({
            'timestamp': s.timestamp,
            'crop_type': s.cropType,
            'disease_name': s.diseaseName,
            'symptoms': s.symptoms,
            'remedy': s.remedy,
            'recipe': s.recipe,
            if (s.localImagePath != null) 'local_image_path': s.localImagePath,
          })).toList();

          await prefs.setStringList(scansKey, syncedJsonList);
          return firebaseScans;
        }
      } catch (e) {
        print('Firebase fetch crop scans failed: $e. Using local database.');
      }
    }

    return localScans;
  }
}
