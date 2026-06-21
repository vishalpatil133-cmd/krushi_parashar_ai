import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../config/secrets.dart';
import '../services/ad_service.dart';

class VideoTutorialModel {
  final String id;
  final String title;
  final String videoId;
  final String description;
  final String crop;

  VideoTutorialModel({
    required this.id,
    required this.title,
    required this.videoId,
    required this.description,
    required this.crop,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'video_id': videoId,
      'description': description,
      'crop': crop,
    };
  }

  factory VideoTutorialModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return VideoTutorialModel(
      id: id,
      title: map['title'] as String? ?? 'कृषी मार्गदर्शिका',
      videoId: map['video_id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      crop: map['crop'] as String? ?? 'सर्व पिके',
    );
  }
}

class VideoGuideScreen extends StatefulWidget {
  const VideoGuideScreen({super.key});

  @override
  State<VideoGuideScreen> createState() => _VideoGuideScreenState();
}

class _VideoGuideScreenState extends State<VideoGuideScreen> {
  late final DatabaseReference _databaseRef;
  List<VideoTutorialModel> _allVideos = [];
  List<VideoTutorialModel> _filteredVideos = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _selectedCrop = 'सर्व पिके';
  final List<String> _cropCategories = [
    'सर्व पिके',
    'भात (तांदूळ)',
    'गहू',
    'कापूस',
    'सोयाबीन',
    'ऊस',
    'इतर पिके'
  ];

  @override
  void initState() {
    super.initState();
    final url = Secrets.firebaseDatabaseUrl;
    if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
      _databaseRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url,
      ).ref('youtube_tutorials');
    } else {
      _databaseRef = FirebaseDatabase.instance.ref('youtube_tutorials');
    }
    _listenToVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _listenToVideos() {
    _databaseRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<VideoTutorialModel> tempVideos = [];
        data.forEach((key, value) {
          if (value is Map) {
            tempVideos.add(VideoTutorialModel.fromMap(value, key.toString()));
          }
        });
        setState(() {
          _allVideos = tempVideos;
          _isLoading = false;
        });
        _filterVideos(_searchController.text);
      } else {
        setState(() {
          _allVideos = [];
          _filteredVideos = [];
          _isLoading = false;
        });
      }
    }, onError: (error) {
      setState(() => _isLoading = false);
    });
  }

  void _filterVideos(String query) {
    setState(() {
      _filteredVideos = _allVideos.where((v) {
        final matchesCrop = _selectedCrop == 'सर्व पिके' || v.crop == _selectedCrop;
        final matchesSearch = query.trim().isEmpty ||
            v.title.toLowerCase().contains(query.toLowerCase()) ||
            v.description.toLowerCase().contains(query.toLowerCase());
        return matchesCrop && matchesSearch;
      }).toList();
    });
  }

  void _onCropSelected(String crop) {
    setState(() {
      _selectedCrop = crop;
    });
    _filterVideos(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: const Text(
          'कृषी व्हिडिओ मार्गदर्शिका',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterVideos,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: primaryGreen),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterVideos('');
                              },
                            )
                          : null,
                      hintText: 'व्हिडिओ किंवा विषय शोधा...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cropCategories.length,
                    itemBuilder: (context, index) {
                      final category = _cropCategories[index];
                      final isSelected = _selectedCrop == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => _onCropSelected(category),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accentGold : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? accentGold : Colors.grey.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryGreen,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Video List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : _filteredVideos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'अद्याप कोणतेही व्हिडिओ उपलब्ध नाहीत.',
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = _filteredVideos[index];
                          final thumbnailUrl = 'https://img.youtube.com/vi/${video.videoId}/hqdefault.jpg';

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                AdService.instance.showInterstitialAd(() {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        videoId: video.videoId,
                                        title: video.title,
                                      ),
                                    ),
                                  );
                                });
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail with Play Button overlay
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          thumbnailUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: Colors.grey[100],
                                              child: const Center(
                                                child: CircularProgressIndicator(color: primaryGreen),
                                              ),
                                            );
                                          },
                                        ),
                                        Container(
                                          color: Colors.black.withOpacity(0.15),
                                        ),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Details
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        if (video.description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            video.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
}
