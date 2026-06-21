import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'video_guide_screen.dart';
import 'community_screen.dart';
import 'pest_advisor_screen.dart';
import 'agri_tools_marketplace_screen.dart';

class NotificationListScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const NotificationListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when opening this screen
    NotificationService.instance.markAllAsRead();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'आता';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} मि. पूर्वी';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ता. पूर्वी';
    } else {
      return '${difference.inDays} दिवसांपूर्वी';
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read (already done on screen open, but good to ensure)
    NotificationService.instance.markAsRead(notification.id);

    // Navigate to target screen
    Widget? targetScreen;
    switch (notification.type) {
      case 'video':
        targetScreen = const VideoGuideScreen();
        break;
      case 'poll':
        targetScreen = CommunityScreen(
          userId: widget.userId,
          userName: widget.userName,
        );
        break;
      case 'disease':
        targetScreen = const PestAdvisorScreen();
        break;
      case 'tool':
        targetScreen = const AgriToolsMarketplaceScreen();
        break;
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      ).then((_) {
        // Refresh state on return
        setState(() {});
      });
    }
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_fill;
      case 'poll':
        return Icons.poll_rounded;
      case 'disease':
        return Icons.bug_report_rounded;
      case 'tool':
        return Icons.handyman_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'video':
        return Colors.redAccent;
      case 'poll':
        return const Color(0xFFE5A93B); // Accent Gold
      case 'disease':
        return Colors.orangeAccent;
      case 'tool':
        return const Color(0xFF1E5631); // Primary Green
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);
    final notifications = NotificationService.instance.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: const Text(
          'सूचना इतिहास (Notifications)',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              label: const Text('सर्व पुसा', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFFFAFAF7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('सर्व सूचना हटवायच्या आहेत का?', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                    content: const Text('यामुळे सर्व जुन्या सूचना इतिहासामधून डिलीट केल्या जातील.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('रद्द करा', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          NotificationService.instance.clearAll();
                          Navigator.pop(context);
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('होय, पुसा', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'अद्याप एकही सूचना नाही!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'नवीन अपडेट्स आल्यावर तुम्हाला इथे दिसतील.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: notification.isRead ? Colors.transparent : primaryGreen.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  elevation: notification.isRead ? 1 : 2,
                  child: InkWell(
                    onTap: () => _handleNotificationTap(notification),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Icon Indicator
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getIconColor(notification.type).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconData(notification.type),
                              color: _getIconColor(notification.type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      notification.title,
                                      style: TextStyle(
                                        color: _getIconColor(notification.type),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(notification.timestamp),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Unread green/gold dot indicator
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
