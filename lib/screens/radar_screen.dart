import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/secrets.dart';

class RadarScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const RadarScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  late final String _windyUrl;

  @override
  void initState() {
    super.initState();
    
    final lat = widget.latitude;
    final lon = widget.longitude;
    final windyKey = Secrets.windyApiKey;
    
    // Windy Radar Embed URL
    _windyUrl = 'https://embed.windy.com/embed2.html?lat=$lat&lon=$lon&zoom=6&level=surface&overlay=radar&product=radar&menu=&message=&marker=true&calendar=now&pressure=&type=map&location=coordinates&detail=&detailLat=$lat&detailLon=$lon&metricWind=default&metricTemp=default&radarRange=-1&key=$windyKey';

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_windyUrl), headers: {
          'Referer': 'http://localhost',
        });
    } else {
      _isLoading = false;
    }
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(_windyUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('नकाशा उघडता आला नाही: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'लाईव्ह हवामान रडार',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: kIsWeb
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: primaryGreen.withOpacity(0.15), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 64,
                          color: primaryGreen,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'लाईव्ह हवामान नकाशा',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'वेब ब्राउझरवर सर्वोत्तम अनुभवासाठी, हवामान रडार नकाशा नवीन विंडोमध्ये उघडा.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _launchUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGold,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'नकाशा उघडा',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A93B)),
                      strokeWidth: 4,
                    ),
                  ),
              ],
            ),
    );
  }
}
