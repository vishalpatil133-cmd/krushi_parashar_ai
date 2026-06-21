import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/secrets.dart';
import '../services/gemini_service.dart';
import '../services/translation_service.dart';

// --- Models ---

class PollModel {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final Map<String, bool> votedUsers;
  final String creatorId;
  final int commentCount;

  PollModel({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.votedUsers,
    required this.creatorId,
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'votes': votes,
      'voted_users': votedUsers,
      'creator_id': creatorId,
    };
  }

  factory PollModel.fromMap(Map<dynamic, dynamic> map, String id) {
    final rawOptions = map['options'];
    List<String> optionsList = [];
    if (rawOptions is List) {
      optionsList = List<String>.from(rawOptions);
    }

    final rawVotes = map['votes'];
    Map<String, int> votesMap = {};
    if (rawVotes is Map) {
      rawVotes.forEach((k, v) {
        votesMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    } else {
      for (var opt in optionsList) {
        votesMap[opt] = 0;
      }
    }

    final rawVoted = map['voted_users'];
    Map<String, bool> votedUsersMap = {};
    if (rawVoted is Map) {
      rawVoted.forEach((k, v) {
        votedUsersMap[k.toString()] = v as bool;
      });
    }

    final rawComments = map['comments'];
    int commentsCount = 0;
    if (rawComments is Map) {
      commentsCount = rawComments.length;
    }

    return PollModel(
      id: id,
      question: map['question'] as String? ?? '',
      options: optionsList,
      votes: votesMap,
      votedUsers: votedUsersMap,
      creatorId: map['creator_id'] as String? ?? '',
      commentCount: commentsCount,
    );
  }
}

class CommunityPostModel {
  final String id;
  final String userId;
  final String userName;
  final String cropName;
  final String description;
  final String photoUrl;
  final int timestamp;
  final String? aiDoctorReply;
  final int commentCount;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.cropName,
    required this.description,
    required this.photoUrl,
    required this.timestamp,
    this.aiDoctorReply,
    this.commentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'crop_name': cropName,
      'description': description,
      'photo_url': photoUrl,
      'timestamp': timestamp,
      'ai_doctor_reply': aiDoctorReply,
    };
  }

  factory CommunityPostModel.fromMap(Map<dynamic, dynamic> map, String id) {
    final rawComments = map['comments'];
    int commentsCount = 0;
    if (rawComments is Map) {
      commentsCount = rawComments.length;
    }

    return CommunityPostModel(
      id: id,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? tr('farmer_friend'),
      cropName: map['crop_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      aiDoctorReply: map['ai_doctor_reply'] as String?,
      commentCount: commentsCount,
    );
  }
}

// --- Main Screen ---

class CommunityScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const CommunityScreen({super.key, required this.userId, required this.userName});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final DatabaseReference _databaseRef;
  late final DatabaseReference _databasePostsRef;
  List<PollModel> _polls = [];
  List<CommunityPostModel> _posts = [];
  bool _isLoadingPolls = true;
  bool _isLoadingPosts = true;

  bool get _isAdmin {
    return widget.userName.toLowerCase().contains('admin') ||
        widget.userId.toLowerCase() == 'admin' ||
        widget.userId.toLowerCase() == 'admin_user';
  }

  @override
  void initState() {
    super.initState();
    final url = Secrets.firebaseDatabaseUrl;
    if (url.startsWith('http') && !url.contains('YOUR_FIREBASE_DATABASE_URL_HERE')) {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url,
      );
      _databaseRef = db.ref('community_polls');
      _databasePostsRef = db.ref('community_posts');
    } else {
      _databaseRef = FirebaseDatabase.instance.ref('community_polls');
      _databasePostsRef = FirebaseDatabase.instance.ref('community_posts');
    }
    _listenToPolls();
    _listenToPosts();
  }

  void _listenToPolls() {
    _databaseRef.onValue.listen((event) {
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
      debugPrint('Database error in community polls: $error');
      setState(() => _isLoadingPolls = false);
    });
  }

  void _listenToPosts() {
    _databasePostsRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<CommunityPostModel> tempPosts = [];
        data.forEach((key, value) {
          if (value is Map) {
            tempPosts.add(CommunityPostModel.fromMap(value, key.toString()));
          }
        });
        // Sort by timestamp descending
        tempPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        setState(() {
          _posts = tempPosts;
          _isLoadingPosts = false;
        });
      } else {
        setState(() {
          _posts = [];
          _isLoadingPosts = false;
        });
      }
    }, onError: (error) {
      debugPrint('Database error in community posts: $error');
      setState(() => _isLoadingPosts = false);
    });
  }

  Future<void> _vote(PollModel poll, String option) async {
    if (poll.votedUsers.containsKey(widget.userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('poll_already_voted'))),
      );
      return;
    }

    final currentVotes = poll.votes[option] ?? 0;
    final pollRef = _databaseRef.child(poll.id);
    await pollRef.child('votes/$option').set(currentVotes + 1);
    await pollRef.child('voted_users/${widget.userId}').set(true);
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    List<TextEditingController> optionControllers = [
      TextEditingController(text: tr('yes')),
      TextEditingController(text: tr('no')),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAFAF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_task, color: Color(0xFF1E5631)),
                  const SizedBox(width: 8),
                  Text(
                    tr('add_new_poll'),
                    style: const TextStyle(color: Color(0xFF1E5631), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(
                        labelText: tr('ask_your_question'),
                        labelStyle: TextStyle(color: Color(0xFF1E5631)),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1E5631)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('options_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
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
                                  labelText: tr('option_index').replaceAll('$index', (index + 1).toString()),
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
                        label: Text(tr('add_option'), style: const TextStyle(color: Color(0xFFE5A93B))),
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
                  child: Text(tr('cancel'), style: const TextStyle(color: Color(0xFF1E5631))),
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
                      commentCount: 0,
                    );

                    await _databaseRef.child(newPollId).set(newPoll.toMap());
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5631),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tr('publish')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreatePostDialog() {
    final cropController = TextEditingController();
    final descController = TextEditingController();
    File? selectedImage;
    bool isUploadingImage = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFAFAF7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF1E5631)),
                  const SizedBox(width: 8),
                  Text(
                    tr('post_new_crop_problem'),
                    style: const TextStyle(color: Color(0xFF1E5631), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: cropController,
                        decoration: InputDecoration(
                          labelText: tr('crop_name_label'),
                          border: const OutlineInputBorder(),
                          hintText: tr('crop_name_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr('enter_crop_name_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: tr('symptoms_description_label'),
                          border: const OutlineInputBorder(),
                          hintText: tr('symptoms_description_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return tr('enter_symptoms_error');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Image Display & Selector
                      if (selectedImage != null)
                        Stack(
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: CircleAvatar(
                                backgroundColor: Colors.red.withOpacity(0.8),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                  selectedImage = File(picked.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library, color: Color(0xFFE5A93B)),
                          label: Text(tr('add_photo'), style: const TextStyle(color: Color(0xFFE5A93B))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5A93B)),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      if (isUploadingImage) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Color(0xFF1E5631), strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(tr('uploading_photo'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploadingImage ? null : () => Navigator.pop(context),
                  child: Text(tr('cancel'), style: const TextStyle(color: Color(0xFF1E5631))),
                ),
                ElevatedButton(
                  onPressed: isUploadingImage
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isUploadingImage = true;
                            });

                            String photoUrl = '';
                            if (selectedImage != null) {
                              final uploadUrl = await _uploadImageToFirebase(selectedImage!);
                              if (uploadUrl != null) {
                                photoUrl = uploadUrl;
                              } else {
                                setDialogState(() {
                                  isUploadingImage = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('photo_upload_failed')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            final postId = DateTime.now().millisecondsSinceEpoch.toString();
                            final newPost = CommunityPostModel(
                              id: postId,
                              userId: widget.userId,
                              userName: widget.userName,
                              cropName: cropController.text.trim(),
                              description: descController.text.trim(),
                              photoUrl: photoUrl,
                              timestamp: DateTime.now().millisecondsSinceEpoch,
                            );

                            await _databasePostsRef.child(postId).set(newPost.toMap());
                            
                            setDialogState(() {
                              isUploadingImage = false;
                            });
                            
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5631),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tr('post_btn')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jpg|.jpeg|.heic'));
      if (lastIndex == -1) return file;
      final splitted = filePath.substring(0, lastIndex);
      final outPath = "${splitted}_compressed.jpg";

      int quality = 85;
      File? compressedFile;
      
      for (int i = 0; i < 5; i++) {
        var result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          outPath,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (result == null) break;
        compressedFile = File(result.path);
        final size = await compressedFile.length();
        if (size < 500 * 1024) {
          break;
        }
        quality -= 15;
        if (quality <= 10) break;
      }
      return compressedFile ?? file;
    } catch (e) {
      debugPrint('Compression error: $e');
      return file;
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      // 1. Compression (Capture & Pre-processing)
      final File? compressed = await _compressImage(imageFile);
      if (compressed == null) {
        throw Exception(tr('compress_failed'));
      }

      final size = await compressed.length();
      debugPrint('Compressed image size: ${size / 1024} KB');

      // 2. Storage Agent
      final storageRef = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'disease_uploads/${widget.userId}/$timestamp.jpg';
      final fileRef = storageRef.ref().child(path);

      String? downloadUrl;
      bool success = false;
      int attempt = 0;

      // 3. Validation Agent & Retry Logic
      while (!success && attempt < 2) {
        attempt++;
        try {
          final uploadTask = fileRef.putFile(compressed);
          final snapshot = await uploadTask;
          if (snapshot.state == TaskState.success) {
            downloadUrl = await fileRef.getDownloadURL();
            success = true;
          }
        } catch (e) {
          debugPrint('Upload attempt $attempt failed: $e');
          if (attempt >= 2) {
            rethrow;
          }
        }
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage Upload Error: $e');
      return null;
    }
  }

  Future<void> _generateAIDoctorReply(CommunityPostModel post) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAFAF7),
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E5631)),
              const SizedBox(width: 16),
              Expanded(child: Text(tr('generating_ai_doctor_remedy'))),
            ],
          ),
        );
      },
    );

    try {
      final gemini = GeminiService();
      String replyText = '';

      if (post.photoUrl.isNotEmpty) {
        // Fetch image bytes from url
        final response = await http.get(Uri.parse(post.photoUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final diagnosis = await gemini.diagnoseCropDisease(post.cropName, bytes);
          replyText = "👨‍⚕️ *" + tr('ai_doctor_advice_pinned') + "*\n"
              "• *" + tr('disease_name_label') + "* ${diagnosis['disease_name']}\n"
              "• *" + tr('symptoms_label') + "* ${diagnosis['symptoms']}\n"
              "• *" + tr('organic_remedy_label') + "* ${diagnosis['remedy']}\n"
              "• *" + tr('recipe_label') + "* ${diagnosis['recipe']}";
        } else {
          replyText = await gemini.getCropRemedyFromText(post.cropName, post.description);
        }
      } else {
        replyText = await gemini.getCropRemedyFromText(post.cropName, post.description);
      }

      // Save reply to post node
      await _databasePostsRef.child(post.id).child('ai_doctor_reply').set(replyText);

      // Push notification to user
      final url = Secrets.firebaseDatabaseUrl;
      final notifRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: url,
      ).ref('user_notifications/${post.userId}');

      final notifId = DateTime.now().millisecondsSinceEpoch.toString();
      await notifRef.child(notifId).set({
        'title': tr('ai_doctor_replied_title'),
        'message': tr('ai_doctor_replied_message').replaceAll('\$crop', post.cropName),
        'type': 'disease',
        'payload': post.id,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('ai_doctor_published_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('ai_doctor_error').replaceAll('$e', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCommentsBottomSheet(BuildContext context, PollModel poll) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PollCommentsWidget(
          databaseRef: _databaseRef.child(poll.id).child('comments'),
          userId: widget.userId,
          userName: widget.userName,
          isAdmin: _isAdmin,
        );
      },
    );
  }

  void _showPostCommentsBottomSheet(BuildContext context, CommunityPostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PollCommentsWidget(
          databaseRef: _databasePostsRef.child(post.id).child('comments'),
          userId: widget.userId,
          userName: widget.userName,
          isAdmin: _isAdmin,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAF7),
        appBar: AppBar(
          title: Text(
            tr('farmers_community_forum'),
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: accentGold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: accentGold,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: const Icon(Icons.forum_rounded), text: tr('crop_discussion_tab')),
              Tab(icon: const Icon(Icons.poll_rounded), text: tr('farmers_polls_tab')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Crop Discussions (Community Feed)
            _buildCropDiscussionsTab(primaryGreen, accentGold),

            // Tab 2: Polls (Existing)
            _buildPollsTab(primaryGreen, accentGold),
          ],
        ),
      ),
    );
  }

  Widget _buildCropDiscussionsTab(Color primaryGreen, Color accentGold) {
    return _isLoadingPosts
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : Stack(
            children: [
              _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            tr('no_discussions_posted'),
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showCreatePostDialog,
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(tr('create_first_post')),
                            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final dateStr = DateFormat('dd MMM, hh:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(post.timestamp),
                        );

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: User details
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryGreen.withOpacity(0.08),
                                      child: Text(
                                        post.userName.isNotEmpty ? post.userName[0].toUpperCase() : 'श',
                                        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateStr,
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isAdmin)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          await _databasePostsRef.child(post.id).remove();
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Crop Name badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentGold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: accentGold.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    tr('crop_display_label').replaceAll('\$crop', post.cropName),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Description / Symptoms
                                Text(
                                  post.description,
                                  style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                                ),
                                const SizedBox(height: 12),

                                // Photo Display
                                if (post.photoUrl.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: Image.network(
                                        post.photoUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: CircularProgressIndicator(color: primaryGreen),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // --- AI Doctor Pinned Reply ---
                                if (post.aiDoctorReply != null && post.aiDoctorReply!.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9), // Light green background
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: primaryGreen.withOpacity(0.4), width: 1.5),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, color: primaryGreen, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              tr('ai_doctor_advice_pinned'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          post.aiDoctorReply!,
                                          style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Admin AI Button
                                    if (_isAdmin)
                                      TextButton.icon(
                                        icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                                        label: Text(
                                          tr('get_doctor_advice_btn'),
                                          style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        onPressed: () => _generateAIDoctorReply(post),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                      
                                    TextButton.icon(
                                      icon: Icon(Icons.comment_outlined, size: 16, color: primaryGreen),
                                      label: Text(
                                        tr('comments_count').replaceAll('\$count', post.commentCount.toString()),
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onPressed: () => _showPostCommentsBottomSheet(context, post),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  backgroundColor: primaryGreen,
                  onPressed: _showCreatePostDialog,
                  child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                ),
              ),
            ],
          );
  }

  Widget _buildPollsTab(Color primaryGreen, Color accentGold) {
    return _isLoadingPolls
        ? Center(child: CircularProgressIndicator(color: primaryGreen))
        : Stack(
            children: [
              _polls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            tr('no_active_polls'),
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          if (_isAdmin) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showCreatePollDialog,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: Text(tr('start_poll_btn')),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _polls.length,
                      itemBuilder: (context, index) {
                        final poll = _polls[index];
                        final hasVoted = poll.votedUsers.containsKey(widget.userId);

                        int totalVotes = 0;
                        poll.votes.forEach((key, val) => totalVotes += val);

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.poll, color: accentGold, size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          tr('farmers_polls_tab') + ' #' + poll.id.substring(poll.id.length - 4),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: accentGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_isAdmin)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () async {
                                          await _databaseRef.child(poll.id).remove();
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Question
                                Text(
                                  poll.question,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Options
                                ...poll.options.map((opt) {
                                  final voteCount = poll.votes[opt] ?? 0;
                                  final percentage = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;
                                  final percentString = (percentage * 100).toStringAsFixed(0);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: InkWell(
                                      onTap: hasVoted ? null : () => _vote(poll, opt),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (hasVoted) ...[
                                            // Results View
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey[300]!),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        opt,
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      Text('$percentString% ($voteCount ' + tr('votes') + ')'),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: LinearProgressIndicator(
                                                      value: percentage,
                                                      backgroundColor: Colors.grey[200],
                                                      valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                                                      minHeight: 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else ...[
                                            // Tap-to-Vote View
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: primaryGreen.withOpacity(0.3)),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    opt,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: primaryGreen,
                                                    ),
                                                  ),
                                                  Icon(Icons.radio_button_off, color: primaryGreen),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tr('total_votes').replaceAll('\$count', totalVotes.toString()),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: Icon(Icons.comment_outlined, size: 16, color: primaryGreen),
                                      label: Text(
                                        tr('comments_count').replaceAll('\$count', poll.commentCount.toString()),
                                        style: TextStyle(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onPressed: () => _showCommentsBottomSheet(context, poll),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              if (_isAdmin)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    backgroundColor: primaryGreen,
                    onPressed: _showCreatePollDialog,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          );
  }
}

// --- Comments List & Form Widget ---

class PollCommentsWidget extends StatefulWidget {
  final DatabaseReference databaseRef;
  final String userId;
  final String userName;
  final bool isAdmin;

  const PollCommentsWidget({
    super.key,
    required this.databaseRef,
    required this.userId,
    required this.userName,
    required this.isAdmin,
  });

  @override
  State<PollCommentsWidget> createState() => _PollCommentsWidgetState();
}

class _PollCommentsWidgetState extends State<PollCommentsWidget> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  late final Stream<DatabaseEvent> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.databaseRef.onValue;
    _listenToComments();
  }

  void _listenToComments() {
    _stream.listen((event) {
      if (!mounted) return;
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = snapshot.value;
        List<Map<String, dynamic>> temp = [];
        if (data is Map) {
          data.forEach((key, val) {
            if (val is Map) {
              temp.add({
                'key': key.toString(),
                'id': val['id']?.toString() ?? '',
                'userName': val['userName']?.toString() ?? tr('farmer_friend'),
                'userId': val['userId']?.toString() ?? '',
                'text': val['text']?.toString() ?? '',
                'timestamp': val['timestamp']?.toString() ?? '',
              });
            }
          });
          temp.sort((a, b) => a['id'].compareTo(b['id']));
        }
        setState(() {
          _comments = temp;
          _loading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _comments = [];
          _loading = false;
        });
      }
    }, onError: (err) {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final commentId = DateTime.now().millisecondsSinceEpoch.toString();
    final newComment = {
      'id': commentId,
      'userName': widget.userName,
      'userId': widget.userId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    widget.databaseRef.push().set(newComment).then((_) {
      _commentController.clear();
      _scrollToBottom();
    });
  }

  void _deleteComment(String commentKey) {
    widget.databaseRef.child(commentKey).remove();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.forum, color: primaryGreen),
                    const SizedBox(width: 10),
                    Text(
                      tr('discussion_comments_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(),

              // Comments List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.comment_bank_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  tr('no_comments_yet'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final isMe = comment['userId'] == widget.userId;
                              final dateStr = comment['timestamp'].isNotEmpty
                                  ? DateFormat('dd MMM, hh:mm a').format(DateTime.parse(comment['timestamp']))
                                  : '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      CircleAvatar(
                                        backgroundColor: primaryGreen.withOpacity(0.1),
                                        child: Text(
                                          comment['userName'].isNotEmpty
                                              ? comment['userName'][0].toUpperCase()
                                              : 'श',
                                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (!isMe) const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isMe ? primaryGreen : Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                                            bottomRight: Radius.circular(isMe ? 0 : 16),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.03),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isMe)
                                              Text(
                                                comment['userName'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: accentGold,
                                                ),
                                              ),
                                            if (!isMe) const SizedBox(height: 4),
                                            Text(
                                              comment['text'],
                                              style: TextStyle(
                                                color: isMe ? Colors.white : Colors.black87,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isMe ? Colors.white70 : Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isMe) const SizedBox(width: 8),
                                    if (isMe)
                                      CircleAvatar(
                                        backgroundColor: accentGold.withOpacity(0.15),
                                        child: Text(
                                          comment['userName'].isNotEmpty
                                              ? comment['userName'][0].toUpperCase()
                                              : 'श',
                                          style: const TextStyle(color: accentGold, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (widget.isAdmin || isMe)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                                        onPressed: () => _deleteComment(comment['key']),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Comment Input Field
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: tr('write_comment_hint'),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: primaryGreen),
                      onPressed: _sendComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
