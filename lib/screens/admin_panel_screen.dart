import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../config/secrets.dart';
import 'video_guide_screen.dart';
import 'community_screen.dart';
import 'pest_advisor_screen.dart';
import 'agri_tools_marketplace_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final String userId;
  const AdminPanelScreen({super.key, required this.userId});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final DatabaseReference _databaseVideoRef;
  late final DatabaseReference _databasePollRef;
  late final DatabaseReference _databaseDiseaseRef;
  late final DatabaseReference _databaseToolRef;

  List<VideoTutorialModel> _videos = [];
  List<PollModel> _polls = [];
  List<DiseaseModel> _diseases = [];
  List<ToolModel> _tools = [];
  bool _isLoadingVideos = true;
  bool _isLoadingPolls = true;
  bool _isLoadingDiseases = true;
  bool _isLoadingTools = true;

  // Video Form controllers
  final _videoTitleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _videoDescController = TextEditingController();
  final _videoFormKey = GlobalKey<FormState>();
  String _selectedVideoCrop = 'सर्व पिके';

  // Disease Form controllers
  final _diseaseNameController = TextEditingController();
  final _diseaseSymptomsController = TextEditingController();
  final _diseaseRemedyController = TextEditingController();
  final _diseaseRecipeController = TextEditingController();
  final _diseaseChemicalRemedyController = TextEditingController();
  final _diseaseVedicQuoteController = TextEditingController();
  final _diseasePhotoUrlController = TextEditingController();
  String _selectedDiseaseCrop = 'भात (तांदूळ)';
  final _diseaseFormKey = GlobalKey<FormState>();

  // Tool Form controllers
  final _toolNameController = TextEditingController();
  final _toolPriceController = TextEditingController();
  final _toolPhotoUrlController = TextEditingController();
  final _toolPurchaseUrlController = TextEditingController();
  String _selectedToolCategory = 'Hand Tools';
  final _toolFormKey = GlobalKey<FormState>();

  // App Update controllers
  final _updateVersionController = TextEditingController();
  final _updateUrlController = TextEditingController();
  final _updateDescController = TextEditingController();
  bool _isForceUpdate = false;
  final _appUpdateFormKey = GlobalKey<FormState>();
  late final DatabaseReference _databaseUpdateRef;

  @override
  void initState() {
    super.initState();
    final url = Secrets.firebaseDatabaseUrl;
    if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url,
      );
      _databaseVideoRef = db.ref('youtube_tutorials');
      _databasePollRef = db.ref('community_polls');
      _databaseDiseaseRef = db.ref('diseases');
      _databaseToolRef = db.ref('tools');
      _databaseUpdateRef = db.ref('app_update');
    } else {
      _databaseVideoRef = FirebaseDatabase.instance.ref('youtube_tutorials');
      _databasePollRef = FirebaseDatabase.instance.ref('community_polls');
      _databaseDiseaseRef = FirebaseDatabase.instance.ref('diseases');
      _databaseToolRef = FirebaseDatabase.instance.ref('tools');
      _databaseUpdateRef = FirebaseDatabase.instance.ref('app_update');
    }
    _listenToVideos();
    _listenToPolls();
    _listenToDiseases();
    _listenToTools();
    _loadCurrentUpdateInfo();
  }

  @override
  void dispose() {
    _videoTitleController.dispose();
    _videoUrlController.dispose();
    _videoDescController.dispose();
    _diseaseNameController.dispose();
    _diseaseSymptomsController.dispose();
    _diseaseRemedyController.dispose();
    _diseaseRecipeController.dispose();
    _diseaseChemicalRemedyController.dispose();
    _diseaseVedicQuoteController.dispose();
    _diseasePhotoUrlController.dispose();
    _toolNameController.dispose();
    _toolPriceController.dispose();
    _toolPhotoUrlController.dispose();
    _toolPurchaseUrlController.dispose();
    _updateVersionController.dispose();
    _updateUrlController.dispose();
    _updateDescController.dispose();
    super.dispose();
  }

  void _listenToVideos() {
    _databaseVideoRef.onValue.listen((event) {
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
          _videos = tempVideos;
          _isLoadingVideos = false;
        });
      } else {
        setState(() {
          _videos = [];
          _isLoadingVideos = false;
        });
      }
    }, onError: (error) {
      setState(() => _isLoadingVideos = false);
    });
  }

  void _listenToPolls() {
    _databasePollRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<PollModel> tempPolls = [];
        data.forEach((key, value) {
          if (value is Map) {
            tempPolls.add(PollModel.fromMap(value, key.toString()));
          }
        });
        tempPolls.sort((a, b) => b.id.compareTo(a.id));
        setState(() {
          _polls = tempPolls;
          _isLoadingPolls = false;
        });
      } else {
        setState(() {
          _polls = [];
          _isLoadingPolls = false;
        });
      }
    }, onError: (error) {
      setState(() => _isLoadingPolls = false);
    });
  }

  void _listenToDiseases() {
    _databaseDiseaseRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<DiseaseModel> temp = [];
        data.forEach((key, value) {
          if (value is Map) {
            temp.add(DiseaseModel.fromMap(value));
          }
        });
        setState(() {
          _diseases = temp;
          _isLoadingDiseases = false;
        });
      } else {
        setState(() {
          _diseases = [];
          _isLoadingDiseases = false;
        });
      }
    }, onError: (error) {
      setState(() => _isLoadingDiseases = false);
    });
  }

  void _listenToTools() {
    _databaseToolRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<ToolModel> temp = [];
        data.forEach((key, value) {
          if (value is Map) {
            temp.add(ToolModel.fromMap(value, key.toString()));
          }
        });
        setState(() {
          _tools = temp;
          _isLoadingTools = false;
        });
      } else {
        setState(() {
          _tools = [];
          _isLoadingTools = false;
        });
      }
    }, onError: (error) {
      setState(() => _isLoadingTools = false);
    });
  }

  Future<void> _addDisease() async {
    if (!_diseaseFormKey.currentState!.validate()) return;
    
    final name = _diseaseNameController.text.trim();
    final symptoms = _diseaseSymptomsController.text.trim();
    final remedy = _diseaseRemedyController.text.trim();
    final recipe = _diseaseRecipeController.text.trim();
    final chemical = _diseaseChemicalRemedyController.text.trim();
    final quote = _diseaseVedicQuoteController.text.trim();
    final photo = _diseasePhotoUrlController.text.trim();
    
    final key = name.replaceAll(' ', '_')
                    .replaceAll('(', '_')
                    .replaceAll(')', '_')
                    .replaceAll('/', '_');
                    
    final newDisease = DiseaseModel(
      name: name,
      crop: _selectedDiseaseCrop,
      symptoms: symptoms,
      organicRemedy: remedy,
      recipe: recipe,
      vedicQuote: quote,
      photoUrl: photo,
      chemicalRemedy: chemical.isNotEmpty ? chemical : 'माहिती उपलब्ध नाही.',
    );
    
    await _databaseDiseaseRef.child(key).set(newDisease.toMap());
    
    // Clear
    _diseaseNameController.clear();
    _diseaseSymptomsController.clear();
    _diseaseRemedyController.clear();
    _diseaseRecipeController.clear();
    _diseaseChemicalRemedyController.clear();
    _diseaseVedicQuoteController.clear();
    _diseasePhotoUrlController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('रोग यशस्वीरित्या जतन केला!')),
      );
    }
  }

  Future<void> _deleteDisease(String name) async {
    final key = name.replaceAll(' ', '_')
                    .replaceAll('(', '_')
                    .replaceAll(')', '_')
                    .replaceAll('/', '_');
    await _databaseDiseaseRef.child(key).remove();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('रोग यशस्वीरित्या डिलीट केला!')),
      );
    }
  }

  Future<void> _addTool() async {
    if (!_toolFormKey.currentState!.validate()) return;

    final name = _toolNameController.text.trim();
    final priceStr = _toolPriceController.text.trim();
    final price = double.tryParse(priceStr) ?? 0.0;
    final photo = _toolPhotoUrlController.text.trim();
    final buyLink = _toolPurchaseUrlController.text.trim();
    
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    
    final toolMap = {
      'name': name,
      'price': price,
      'category': _selectedToolCategory,
      'photoUrl': photo,
      'purchaseUrl': buyLink.isNotEmpty ? buyLink : 'https://amazon.in',
    };
    
    await _databaseToolRef.child(key).set(toolMap);
    
    // Clear
    _toolNameController.clear();
    _toolPriceController.clear();
    _toolPhotoUrlController.clear();
    _toolPurchaseUrlController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('साधन यशस्वीरित्या जतन केले!')),
      );
    }
  }

  Future<void> _deleteTool(String toolId) async {
    await _databaseToolRef.child(toolId).remove();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('साधन यशस्वीरित्या डिलीट केले!')),
      );
    }
  }

  String? _extractVideoId(String url) {
    url = url.trim();
    if (url.length == 11) return url;

    final regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      final id = match.group(2);
      if (id != null && id.length == 11) {
        return id;
      }
    }
    return null;
  }

  Future<void> _addVideo() async {
    if (!_videoFormKey.currentState!.validate()) return;

    final url = _videoUrlController.text.trim();
    final videoId = _extractVideoId(url);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया वैध युट्यूब व्हिडिओ URL प्रविष्ट करा.')),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newVideo = VideoTutorialModel(
      id: id,
      title: _videoTitleController.text.trim(),
      videoId: videoId,
      description: _videoDescController.text.trim(),
      crop: _selectedVideoCrop,
    );

    await _databaseVideoRef.child(id).set(newVideo.toMap());

    _videoTitleController.clear();
    _videoUrlController.clear();
    _videoDescController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('मार्गदर्शिका व्हिडिओ यशस्वीरित्या जोडला गेला!')),
      );
    }
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    List<TextEditingController> optionControllers = [
      TextEditingController(text: 'होय'),
      TextEditingController(text: 'नाही'),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAFAF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_task, color: Color(0xFF1E5631)),
                  SizedBox(width: 8),
                  Text(
                    'नवीन मतदान जोडा',
                    style: TextStyle(color: Color(0xFF1E5631), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: const InputDecoration(
                        labelText: 'प्रश्न विचारा...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'पर्याय:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(optionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: '${index + 1} ला पर्याय',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            if (optionControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    optionControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (optionControllers.length < 5)
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: Color(0xFFE5A93B)),
                        label: const Text('पर्याय जोडा', style: TextStyle(color: Color(0xFFE5A93B))),
                        onPressed: () {
                          setDialogState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('रद्द करा', style: TextStyle(color: Color(0xFF1E5631))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final q = questionController.text.trim();
                    if (q.isEmpty) return;

                    List<String> opts = [];
                    for (var controller in optionControllers) {
                      final val = controller.text.trim();
                      if (val.isNotEmpty) opts.add(val);
                    }

                    if (opts.length < 2) return;

                    final newPollId = DateTime.now().millisecondsSinceEpoch.toString();
                    Map<String, int> initialVotes = {};
                    for (var opt in opts) {
                      initialVotes[opt] = 0;
                    }

                    final newPoll = PollModel(
                      id: newPollId,
                      question: q,
                      options: opts,
                      votes: initialVotes,
                      votedUsers: {},
                      creatorId: widget.userId,
                    );

                    await _databasePollRef.child(newPollId).set(newPoll.toMap());
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5631),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('प्रसिद्ध करा'),
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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAF7),
        appBar: AppBar(
          title: const Text(
            'प्रशासक पॅनेल (Admin)',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: accentGold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentGold,
            indicatorWeight: 3,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.video_collection), text: 'व्हिडिओ'),
              Tab(icon: Icon(Icons.poll), text: 'मतदान'),
              Tab(icon: Icon(Icons.bug_report), text: 'पीक रोग'),
              Tab(icon: Icon(Icons.handyman), text: 'कृषी साधने'),
              Tab(icon: Icon(Icons.system_update_rounded), text: 'अपडेट्स'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Video Management
            _buildVideoManagementTab(primaryGreen, accentGold),

            // Tab 2: Poll Management
            _buildPollManagementTab(primaryGreen, accentGold),

            // Tab 3: Crop Disease Management
            _buildDiseaseManagementTab(primaryGreen, accentGold),

            // Tab 4: Machinery Tools Management
            _buildToolsManagementTab(primaryGreen, accentGold),

            // Tab 5: App Update Management
            _buildAppUpdateTab(primaryGreen, accentGold),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoManagementTab(Color primaryGreen, Color accentGold) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Video Form Card
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _videoFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'नवीन मार्गदर्शिका व्हिडिओ जोडा',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoTitleController,
                      decoration: const InputDecoration(
                        labelText: 'व्हिडिओचे शीर्षक (Title)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'कृपया व्हिडिओचे शीर्षक टाका';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'युट्यूब लिंक / व्हिडिओ आयडी (YouTube URL / ID)',
                        border: OutlineInputBorder(),
                        hintText: 'उदा. https://www.youtube.com/watch?v=...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'कृपया युट्यूब व्हिडिओ लिंक टाका';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedVideoCrop,
                      decoration: const InputDecoration(
                        labelText: 'पिकाची श्रेणी (Crop Category)',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>[
                        'सर्व पिके',
                        'भात (तांदूळ)',
                        'गहू',
                        'कापूस',
                        'सोयाबीन',
                        'ऊस',
                        'इतर पिके'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedVideoCrop = newValue ?? 'सर्व पिके';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _videoDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'व्हिडिओचे वर्णन (Description - ऐच्छिक)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addVideo,
                      icon: const Icon(Icons.add_to_queue, color: Colors.white),
                      label: const Text('व्हिडिओ जतन करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'सध्याचे मार्गदर्शिका व्हिडिओ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const SizedBox(height: 8),

          // Video list
          _isLoadingVideos
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _videos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('अद्याप एकही व्हिडिओ जोडलेला नाही.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 36),
                            title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${video.videoId}', style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                await _databaseVideoRef.child(video.id).remove();
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildPollManagementTab(Color primaryGreen, Color accentGold) {
    return Column(
      children: [
        // Create Poll Button Area
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showCreatePollDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('नवीन शेतकरी मतदान सुरू करा'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'सक्रिय मतदाने (Polls)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
            ),
          ),
        ),

        // Poll list
        Expanded(
          child: _isLoadingPolls
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _polls.isEmpty
                  ? const Center(
                      child: Text('सध्या कोणतेही मतदान सुरू नाही.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _polls.length,
                      itemBuilder: (context, index) {
                        final poll = _polls[index];
                        int total = 0;
                        poll.votes.forEach((k, v) => total += v);

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: #${poll.id.substring(poll.id.length - 4)} (एकूण मते: $total)',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        await _databasePollRef.child(poll.id).remove();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  poll.question,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryGreen),
                                ),
                                const SizedBox(height: 8),
                                ...poll.options.map((opt) {
                                  final count = poll.votes[opt] ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('• $opt', style: const TextStyle(fontSize: 13)),
                                        Text('$count मते', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDiseaseManagementTab(Color primaryGreen, Color accentGold) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _diseaseFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'नवीन पीक रोग जोडा',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diseaseNameController,
                      decoration: const InputDecoration(
                        labelText: 'रोगाचे नाव (उदा. तांबेरा रोग)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया नाव टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDiseaseCrop,
                      decoration: const InputDecoration(
                        labelText: 'संबंधित पीक',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'भात (तांदूळ)', child: Text('भात (तांदूळ)')),
                        DropdownMenuItem(value: 'गहू', child: Text('गहू')),
                        DropdownMenuItem(value: 'कापूस', child: Text('कापूस')),
                        DropdownMenuItem(value: 'सोयाबीन', child: Text('सोयाबीन')),
                        DropdownMenuItem(value: 'ऊस', child: Text('ऊस')),
                        DropdownMenuItem(value: 'इतर पिके', child: Text('इतर पिके')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDiseaseCrop = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseaseSymptomsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'रोगाची लक्षणे (Symptoms)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया लक्षणे टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseaseRemedyController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'सेंद्रिय उपाय (Organic Remedy)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया उपाय टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseaseRecipeController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'औषध बनवण्याची पद्धत (Recipe)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया औषध बनवण्याची पद्धत टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseaseChemicalRemedyController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'रासायनिक उपाय (Chemical Remedy)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया रासायनिक उपाय टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseaseVedicQuoteController,
                      decoration: const InputDecoration(
                        labelText: 'वैदिक श्लोक / संदर्भ (Vedic Quote - ऐच्छिक)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diseasePhotoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'फोटो लिंक (Photo URL)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया फोटो लिंक टाका' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addDisease,
                      icon: const Icon(Icons.add_circle, color: Colors.white),
                      label: const Text('रोग जतन करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'सध्याचे रोग सल्ला रेकॉर्ड्स',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const SizedBox(height: 8),
          _isLoadingDiseases
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _diseases.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('अद्याप एकही रोग जोडलेला नाही.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _diseases.length,
                      itemBuilder: (context, index) {
                        final disease = _diseases[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: disease.photoUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      disease.photoUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.bug_report, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.bug_report, color: Colors.grey),
                            title: Text(disease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('पीक: ${disease.crop}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteDisease(disease.name),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildToolsManagementTab(Color primaryGreen, Color accentGold) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _toolFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'नवीन कृषी यंत्र / साधन जोडा',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _toolNameController,
                      decoration: const InputDecoration(
                        labelText: 'साधनाचे नाव (उदा. कोळपे यंत्र)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया नाव टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _toolPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'किंमत (रुपये)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया किंमत टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedToolCategory,
                      decoration: const InputDecoration(
                        labelText: 'साधन श्रेणी (Category)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Hand Tools', child: Text('Hand Tools')),
                        DropdownMenuItem(value: 'Pumps', child: Text('Pumps')),
                        DropdownMenuItem(value: 'Seeds', child: Text('Seeds')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedToolCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _toolPhotoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'फोटो लिंक (Photo URL)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'कृपया फोटो लिंक टाका' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _toolPurchaseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'खरेदी लिंक (Purchase URL - Amazon/etc.)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addTool,
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                      label: const Text('साधन जतन करा'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'सध्याची कृषी साधने',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const SizedBox(height: 8),
          _isLoadingTools
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _tools.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('अद्याप एकही साधन जोडलेले नाही.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tools.length,
                      itemBuilder: (context, index) {
                        final tool = _tools[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: tool.photoUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      tool.photoUrl,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.handyman, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.handyman, color: Colors.grey),
                            title: Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('किंमत: ₹${tool.price} | श्रेणी: ${tool.category}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTool(tool.id),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  void _loadCurrentUpdateInfo() {
    _databaseUpdateRef.once().then((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        setState(() {
          _updateVersionController.text = (data['version_code'] ?? 2002).toString();
          _updateUrlController.text = data['update_url'] ?? '';
          _updateDescController.text = data['update_desc'] ?? '';
          _isForceUpdate = data['is_force'] as bool? ?? false;
        });
      }
    });
  }

  void _saveAppUpdateInfo() async {
    if (_appUpdateFormKey.currentState!.validate()) {
      final int newVersion = int.tryParse(_updateVersionController.text.trim()) ?? 2002;
      final String newUrl = _updateUrlController.text.trim();
      final String newDesc = _updateDescController.text.trim();

      await _databaseUpdateRef.set({
        'version_code': newVersion,
        'update_url': newUrl,
        'update_desc': newDesc,
        'is_force': _isForceUpdate,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('अपडेट माहिती यशस्वीरीत्या जतन केली!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildAppUpdateTab(Color primaryGreen, Color accentGold) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _appUpdateFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ॲप अपडेट व्यवस्थापन (App Update)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _updateVersionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'नवीन व्हर्जन कोड (Version Code - e.g. 2003)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'कृपया व्हर्जन कोड टाका';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'कृपया वैध संख्या टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _updateUrlController,
                  decoration: const InputDecoration(
                    labelText: 'नवीन APK डाऊनलोड लिंक (Google Drive/Direct Link)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'कृपया डाउनलोड लिंक टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _updateDescController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'अपडेट बद्दल माहिती (Description)',
                    border: OutlineInputBorder(),
                    hintText: 'उदा. नवीन वैशिष्ट्ये जोडली आहेत व बग फिक्स केले आहेत.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'कृपया अपडेट वर्णन टाका';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('सक्तीचे अपडेट (Force Update)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('युझरला ॲप वापरण्यासाठी अपडेट करणे बंधनकारक राहील.'),
                  value: _isForceUpdate,
                  activeColor: primaryGreen,
                  onChanged: (bool value) {
                    setState(() {
                      _isForceUpdate = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveAppUpdateInfo,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('अपडेट जतन आणि लागू करा'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
