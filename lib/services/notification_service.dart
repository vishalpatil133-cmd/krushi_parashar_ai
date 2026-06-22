import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/secrets.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'video', 'poll', 'disease', 'tool'
  final String payload;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.payload,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'payload': payload,
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? '',
      payload: map['payload'] ?? '',
      isRead: map['isRead'] ?? false,
    );
  }
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final List<NotificationItem> _notifications = [];
  final Set<String> _knownKeys = {};
  bool _initialized = false;
  
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  Function(NotificationItem)? _onNewNotificationCallback;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  FirebaseDatabase get _db {
    final url = Secrets.firebaseDatabaseUrl;
    if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url,
      );
    }
    return FirebaseDatabase.instance;
  }

  /// Initialize the notification service, load history, and listen to database changes
  Future<void> initialize({Function(NotificationItem)? onNewNotification}) async {
    if (_initialized) {
      _onNewNotificationCallback = onNewNotification;
      return;
    }

    _onNewNotificationCallback = onNewNotification;
    await _loadFromPrefs();
    await _initializeListeners();
    _initialized = true;
  }

  /// Load existing notifications from SharedPreferences
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('local_notifications_history') ?? [];
      
      _notifications.clear();
      for (var jsonStr in jsonList) {
        final map = json.decode(jsonStr);
        _notifications.add(NotificationItem.fromMap(map));
      }

      // Sort notifications by timestamp descending (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Update unread count
      _updateUnreadCount();
    } catch (e) {
      print('NotificationService: Load from prefs error: $e');
    }
  }

  /// Save notifications to SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => json.encode(n.toMap())).toList();
      await prefs.setStringList('local_notifications_history', jsonList);
    } catch (e) {
      print('NotificationService: Save to prefs error: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = _notifications.where((n) => !n.isRead).length;
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    _updateUnreadCount();
    await _saveToPrefs();
  }

  /// Mark a specific notification as read
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _updateUnreadCount();
      await _saveToPrefs();
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    unreadCount.value = 0;
    await _saveToPrefs();
  }

  /// Generate a daily Vedic notification based on the day's Nakshatra
  Future<void> generateDailyVedicNotification() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGenerated = prefs.getString('last_vedic_notification_date');
      if (lastGenerated == todayStr) {
        return; // Already generated today
      }
      
      final nakshatras = [
        'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशीर्ष', 'आर्द्रा',
        'पुनर्वसू', 'पुष्य', 'आश्लेषा', 'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी',
        'हस्त', 'चित्रा', 'स्वाती', 'विशाखा', 'अनुराधा', 'ज्येष्ठा',
        'मूळ', 'पूर्वाषाढा', 'उत्तराषाढा', 'श्रावण', 'धनिष्ठा',
        'शततारका', 'पूर्वाभाद्रपदा', 'उत्तराभाद्रपदा', 'रेवती'
      ];
      
      final advices = [
        'आज नवीन शेतीकामाची सुरुवात करण्यासाठी आणि बियाणे पेरण्यासाठी अतिशय शुभ दिवस आहे.',
        'आज झाडांना खत घालणे आणि शेत स्वच्छ करण्यासाठी अनुकूल वेळ आहे.',
        'अग्नीचे नक्षत्र असल्याने आज मशागत किंवा तण काढण्याचे काम करावे, पाणी देणे टाळावे.',
        'आज नवीन रोपे लावणे, विहीर किंवा पाण्याचे कालवे खोदण्यासाठी अत्यंत शुभ काळ आहे.',
        'धान्य पेरणी आणि शेत नांगरण्यासाठी आजचा दिवस सर्वोत्तम मानला जातो.',
        'पावसाचे नक्षत्र असल्याने आज ओलावा टिकवण्यासाठी मशागत करा आणि पिकांची काळजी घ्या.',
        'नष्ट झालेली पिके पुन्हा लावण्यासाठी आणि खते देण्यासाठी उत्तम काळ आहे.',
        'पुष्य नक्षत्र शेतीसाठी अत्यंत पवित्र आहे. आज पेरणी केल्यास पिकांचे मोठे उत्पादन मिळते.',
        'कीटकनाशक फवारणी आणि तण काढण्यासाठी आजचा काळ योग्य आहे.',
        'आज नवीन झाडे लावणे आणि शेतजमिनीची पूजा करण्यासाठी शुभ मुहूर्त आहे.',
        'आज तयार झालेले पिके गोळा करणे आणि साठवणूक करण्याचे काम करावे.',
        'आज नवीन धान्याची खरेदी किंवा विक्री करण्यासाठी शुभ दिवस आहे.',
        'हस्त नक्षत्र हस्तकलेसाठी आणि पिकांची कापणी करण्यासाठी अत्यंत शुभ मानले जाते.',
        'शेतात पाणी व्यवस्थापन करणे आणि फळझाडांची छाटणी करण्यासाठी आजचा काळ चांगला आहे.',
        'आज शेत नांगरणे आणि माती तयार करण्यासाठी उत्तम हवामान आणि वेळ आहे.',
        'आज धान्य साठवून ठेवणे आणि गोदामांची स्वच्छता करण्यासाठी शुभ काळ आहे.',
        'आज पाणी देण्याचे काम आणि औषधी वनस्पती लावण्याचे काम करावे.',
        'आज शेतातील कीड आणि रोग नियंत्रणावर लक्ष केंद्रित करण्यासाठी अनुकूल दिवस आहे.',
        'मूळ नक्षत्र झाडे लावणे आणि जमिनीतील पिके (उदा. बटाटे, आले) काढण्यासाठी योग्य आहे.',
        'आज नवीन सिंचन पद्धती किंवा ठिबक सिंचन सुरू करण्यासाठी शुभ मुहूर्त आहे.',
        'आज शेतात नवीन खतांचा वापर आणि माती परीक्षण करण्यासाठी चांगला काळ आहे.',
        'श्रावण नक्षत्र अतिशय शुभ आहे. आज नवीन धान्याची पेरणी आणि खरेदी करावी.',
        'शेतातील अवजारे खरेदी करण्यासाठी आणि दुरुस्तीसाठी आजचा दिवस अनुकूल आहे.',
        'आज औषध फवारणी आणि तणनाशक वापरण्यासाठी योग्य नक्षत्र आहे.',
        'आज सेंद्रिय शेतीची कामे सुरू करणे आणि कंपोस्ट खत तयार करण्यासाठी उत्तम काळ आहे.',
        'आज भाजीपाला लागवड करणे आणि नवीन मशागत सुरू करण्यासाठी अनुकूल दिवस आहे.',
        'रेवती नक्षत्र पिकांच्या काढणीसाठी आणि साठवणूक पूजेसाठी अत्यंत शुभ मानले जाते.'
      ];
      
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final index = (dayOfYear + now.year) % 27;
      
      final nakshatraName = nakshatras[index];
      final advice = advices[index];
      
      final item = NotificationItem(
        id: 'vedic_${now.millisecondsSinceEpoch}',
        title: 'दैनिक वैदिक पंचांग सल्ला: $nakshatraName नक्षत्र',
        message: 'आज $nakshatraName नक्षत्र चालू आहे. आजचा सल्ला: $advice',
        timestamp: now,
        type: 'disease',
        payload: 'vedic',
      );
      
      _notifications.insert(0, item);
      _updateUnreadCount();
      await _saveToPrefs();
      await prefs.setString('last_vedic_notification_date', todayStr);
      
      if (_onNewNotificationCallback != null) {
        _onNewNotificationCallback!(item);
      }
    } catch (e) {
      print('NotificationService: generateDailyVedicNotification error: $e');
    }
  }

  /// Set up Realtime Database listeners
  Future<void> _initializeListeners() async {
    try {
      final db = _db;

      // 1. YouTube Tutorials
      final videoRef = db.ref('youtube_tutorials');
      await _prepopulateKeys(videoRef);
      videoRef.onChildAdded.listen((event) {
        final key = event.snapshot.key;
        if (key == null) return;

        if (!_knownKeys.contains(key)) {
          _knownKeys.add(key);
          final data = event.snapshot.value as Map?;
          if (data != null) {
            final title = data['title'] ?? 'नवीन व्हिडिओ';
            _addNotification(
              NotificationItem(
                id: 'video_$key',
                title: '🎥 नवीन मार्गदर्शन व्हिडिओ',
                message: title,
                timestamp: DateTime.now(),
                type: 'video',
                payload: key,
              ),
            );
          }
        }
      });

      // 2. Community Polls
      final pollRef = db.ref('community_polls');
      await _prepopulateKeys(pollRef);
      pollRef.onChildAdded.listen((event) {
        final key = event.snapshot.key;
        if (key == null) return;

        if (!_knownKeys.contains(key)) {
          _knownKeys.add(key);
          final data = event.snapshot.value as Map?;
          if (data != null) {
            final question = data['question'] ?? 'नवीन मतदान';
            _addNotification(
              NotificationItem(
                id: 'poll_$key',
                title: '📊 नवीन शेतकरी मतदान',
                message: question,
                timestamp: DateTime.now(),
                type: 'poll',
                payload: key,
              ),
            );
          }
        }
      });

      // 3. Crop Diseases
      final diseaseRef = db.ref('diseases');
      await _prepopulateKeys(diseaseRef);
      diseaseRef.onChildAdded.listen((event) {
        final key = event.snapshot.key;
        if (key == null) return;

        if (!_knownKeys.contains(key)) {
          _knownKeys.add(key);
          final data = event.snapshot.value as Map?;
          if (data != null) {
            final name = data['name'] ?? 'नवीन रोग माहिती';
            _addNotification(
              NotificationItem(
                id: 'disease_$key',
                title: '🐛 नवीन पीक रोग सल्ला',
                message: name,
                timestamp: DateTime.now(),
                type: 'disease',
                payload: key,
              ),
            );
          }
        }
      });

      // 4. Agricultural Tools
      final toolRef = db.ref('tools');
      await _prepopulateKeys(toolRef);
      toolRef.onChildAdded.listen((event) {
        final key = event.snapshot.key;
        if (key == null) return;

        if (!_knownKeys.contains(key)) {
          _knownKeys.add(key);
          final data = event.snapshot.value as Map?;
          if (data != null) {
            final name = data['name'] ?? 'नवीन कृषी साधन';
            _addNotification(
              NotificationItem(
                id: 'tool_$key',
                title: '🛠️ नवीन कृषी यंत्र / साधन',
                message: name,
                timestamp: DateTime.now(),
                type: 'tool',
                payload: key,
              ),
            );
          }
        }
      });

      print('NotificationService: Database listeners initialized.');
    } catch (e) {
      print('NotificationService: Initialize listeners error: $e');
    }
  }

  /// Listen to user-specific notifications in real-time
  void listenToUserNotifications(String userId) {
    try {
      final db = _db;
      final userNotifRef = db.ref('user_notifications/$userId');

      _prepopulateKeys(userNotifRef).then((_) {
        userNotifRef.onChildAdded.listen((event) {
          final key = event.snapshot.key;
          if (key == null) return;

          if (!_knownKeys.contains(key)) {
            _knownKeys.add(key);
            final data = event.snapshot.value as Map?;
            if (data != null) {
              final title = data['title'] ?? 'नवीन सूचना';
              final message = data['message'] ?? '';
              final type = data['type'] ?? 'general';
              final payload = data['payload'] ?? '';

              _addNotification(
                NotificationItem(
                  id: 'user_notif_$key',
                  title: title,
                  message: message,
                  timestamp: DateTime.now(),
                  type: type,
                  payload: payload,
                ),
              );
            }
          }
        });
      });
    } catch (e) {
      print('NotificationService: User notification listener setup failed: $e');
    }
  }

  /// Helper to get all existing keys at app startup to prevent notifications for old records
  Future<void> _prepopulateKeys(DatabaseReference ref) async {
    try {
      final snapshot = await ref.get().timeout(const Duration(seconds: 3));
      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          data.keys.forEach((k) {
            _knownKeys.add(k.toString());
          });
        }
      }
    } catch (e) {
      print('NotificationService: Prepopulate keys error for ${ref.path}: $e');
    }
  }

  /// Internal helper to add and broadcast a notification
  void _addNotification(NotificationItem item) {
    // Check if we already have this notification ID to prevent duplicates
    if (_notifications.any((n) => n.id == item.id)) return;

    _notifications.insert(0, item);
    _updateUnreadCount();
    _saveToPrefs();

    // Trigger UI floating notification
    if (_onNewNotificationCallback != null) {
      _onNewNotificationCallback!(item);
    }
  }
}
