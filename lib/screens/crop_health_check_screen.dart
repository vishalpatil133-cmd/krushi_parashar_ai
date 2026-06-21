import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/crop_scan.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/ad_service.dart';
import 'tts_button.dart';

class CropHealthCheckScreen extends StatefulWidget {
  final String userId;
  const CropHealthCheckScreen({super.key, required this.userId});

  @override
  State<CropHealthCheckScreen> createState() => _CropHealthCheckScreenState();
}

class _HealthDecoration {
  static const Color primaryGreen = Color(0xFF1E5631);
  static const Color accentGold = Color(0xFFE5A93B);
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color textDark = Color(0xFF2E3D30);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF7A8D7C);
  static const Color dangerRed = Color(0xFFC84B31);
}

class _CropHealthCheckScreenState extends State<CropHealthCheckScreen> {
  final _geminiService = GeminiService();
  final _dbService = DatabaseService();
  final _picker = ImagePicker();

  String _selectedCrop = 'भात (तांदूळ)';
  File? _selectedImage;
  bool _isAnalyzing = false;
  CropScanModel? _diagnosisResult;
  List<CropScanModel> _scanHistory = [];
  bool _isLoadingHistory = true;

  final List<String> _crops = [
    'भात (तांदूळ)',
    'गहू',
    'कापूस',
    'सोयाबीन',
    'ऊस',
    'इतर पिके'
  ];

  DateTime _parseTimestamp(String ts) {
    final parsed = DateTime.tryParse(ts);
    if (parsed != null) return parsed;

    try {
      final clean = ts.replaceAll('_', ' ').trim();
      final parts = clean.split(' ');
      if (parts.length >= 6) {
        final y = parts[0];
        final m = parts[1].padLeft(2, '0');
        final d = parts[2].padLeft(2, '0');
        final hh = parts[3].padLeft(2, '0');
        final mm = parts[4].padLeft(2, '0');
        final ss = parts[5].padLeft(2, '0');
        final reconstructed = '$y-$m-${d}T$hh:$mm:$ss';
        final recParsed = DateTime.tryParse(reconstructed);
        if (recParsed != null) return recParsed;
      }
    } catch (_) {}

    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _dbService.getCropScansHistory(widget.userId);
      setState(() {
        _scanHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('Error loading crop scan history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _diagnosisResult = null; // Clear previous result on new image
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('प्रतिमा निवडताना अडचण आली: $e')),
      );
    }
  }

  Future<void> _runDiagnosis() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया आधी पिकाच्या पानाचा फोटो काढा किंवा निवडा.')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final responseMap = await _geminiService.diagnoseCropDisease(_selectedCrop, imageBytes);

      if (!mounted) return;

      final timestampStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final scanResult = CropScanModel(
        timestamp: timestampStr,
        cropType: _selectedCrop,
        diseaseName: responseMap['disease_name'] ?? 'अज्ञात रोग',
        symptoms: responseMap['symptoms'] ?? 'लक्षणे उपलब्ध नाहीत.',
        remedy: responseMap['remedy'] ?? 'माहिती उपलब्ध नाही.',
        recipe: responseMap['recipe'] ?? 'माहिती उपलब्ध नाही.',
        localImagePath: _selectedImage!.path,
      );

      await _dbService.saveCropScan(widget.userId, scanResult);

      if (!mounted) return;
      
      await AdService.instance.showInterstitialAd(() {
        if (!mounted) return;
        setState(() {
          _diagnosisResult = scanResult;
          _isAnalyzing = false;
        });

        // Reload history to show the new scan
        _loadHistory();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('तपासणी करताना चूक झाली: $e. कृपया पुन्हा प्रयत्न करा.')),
      );
    }
  }

  void _showScanDetailDialog(CropScanModel scan) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _HealthDecoration.lightBackground,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: _HealthDecoration.primaryGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          scan.cropType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scan.localImagePath != null && File(scan.localImagePath!).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(scan.localImagePath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 4),
                      
                      _buildDetailItem('रोग / कीड:', scan.diseaseName, titleColor: _HealthDecoration.dangerRed),
                      const Divider(),
                      _buildDetailItem('लक्षणे:', scan.symptoms),
                      const Divider(),
                      _buildDetailItem('सेंद्रिय उपाय:', scan.remedy, valueColor: _HealthDecoration.primaryGreen),
                      const Divider(),
                      _buildDetailItem('औषध तयार करण्याची पद्धत:', scan.recipe),
                      
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'तपासणी दिनांक: ${DateFormat('dd MMM yyyy, hh:mm a').format(_parseTimestamp(scan.timestamp))}',
                          style: const TextStyle(fontSize: 11, color: _HealthDecoration.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String title, String content, {Color? titleColor, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: titleColor ?? _HealthDecoration.textDark,
              ),
            ),
            TtsButton(text: '$title $content', size: 26, color: titleColor ?? _HealthDecoration.primaryGreen),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: valueColor ?? _HealthDecoration.textDark.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HealthDecoration.lightBackground,
      bottomNavigationBar: AdService.instance.getBannerWidget(context),
      appBar: AppBar(
        backgroundColor: _HealthDecoration.primaryGreen,
        foregroundColor: _HealthDecoration.textLight,
        title: const Text(
          'पीक व रोग सल्ला',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Selection & Image Pick Card
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'तुमचे पीक निवडा आणि पानाचा फोटो काढा',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _HealthDecoration.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Crop Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _HealthDecoration.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _HealthDecoration.primaryGreen.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCrop,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: _HealthDecoration.primaryGreen),
                            style: const TextStyle(
                              color: _HealthDecoration.textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            items: _crops.map((String crop) {
                              return DropdownMenuItem<String>(
                                value: crop,
                                child: Text(crop),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCrop = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Photo Area
                      GestureDetector(
                        onTap: () => _showImageSourceOptions(),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: _HealthDecoration.lightBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _HealthDecoration.primaryGreen.withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(_selectedImage!, fit: BoxFit.cover),
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black.withOpacity(0.5),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white),
                                            onPressed: () => _showImageSourceOptions(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 48,
                                      color: _HealthDecoration.primaryGreen.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'फोटो काढण्यासाठी किंवा निवडण्यासाठी येथे क्लिक करा',
                                      style: TextStyle(
                                        color: _HealthDecoration.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Analyze Button
                      ElevatedButton(
                        onPressed: _isAnalyzing ? null : _runDiagnosis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _HealthDecoration.accentGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isAnalyzing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'तपासणी सुरू आहे...',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : const Text(
                                'रोग तपासा (AI)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Diagnosis Results Section
            if (_diagnosisResult != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'तपासणी अहवाल',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _HealthDecoration.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Card 1: Disease Name
                    _buildResultCard(
                      'रोग / कीटक',
                      _diagnosisResult!.diseaseName,
                      icon: Icons.bug_report,
                      accentColor: _HealthDecoration.dangerRed,
                    ),
                    const SizedBox(height: 4),
                    
                    // Card 2: Symptoms
                    _buildResultCard(
                      'लक्षणे',
                      _diagnosisResult!.symptoms,
                      icon: Icons.list_alt,
                      accentColor: _HealthDecoration.accentGold,
                    ),
                    const SizedBox(height: 4),
                    
                    // Card 3: Organic Remedy
                    _buildResultCard(
                      'सेंद्रिय उपाय',
                      _diagnosisResult!.remedy,
                      icon: Icons.spa,
                      accentColor: _HealthDecoration.primaryGreen,
                    ),
                    const SizedBox(height: 4),
                    
                    // Card 4: Recipe
                    _buildResultCard(
                      'कृती आणि फवारणी पद्धत',
                      _diagnosisResult!.recipe,
                      icon: Icons.menu_book,
                      accentColor: Colors.blue[800]!,
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
            
            // History Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'मागील तपासण्यांचा इतिहास',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _HealthDecoration.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  if (_isLoadingHistory)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: _HealthDecoration.primaryGreen),
                      ),
                    )
                  else if (_scanHistory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: _HealthDecoration.textMuted),
                            SizedBox(height: 4),
                            Text(
                              'अजून एकही तपासणी केलेली नाही.',
                              style: TextStyle(color: _HealthDecoration.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _scanHistory.length,
                      itemBuilder: (context, index) {
                        final scan = _scanHistory[index];
                        final date = _parseTimestamp(scan.timestamp);
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: ListTile(
                            onTap: () => _showScanDetailDialog(scan),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _HealthDecoration.lightBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: scan.localImagePath != null && File(scan.localImagePath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(scan.localImagePath!), fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.spa, color: _HealthDecoration.primaryGreen),
                            ),
                            title: Text(
                              scan.diseaseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _HealthDecoration.textDark,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.grass, size: 12, color: _HealthDecoration.primaryGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      scan.cropType,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(fontSize: 10, color: _HealthDecoration.textMuted),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: _HealthDecoration.primaryGreen),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'फोटो कुठून घ्यायचा?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _HealthDecoration.primaryGreen,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _HealthDecoration.primaryGreen),
                title: const Text('कॅमेरा (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _HealthDecoration.primaryGreen),
                title: const Text('गॅलरी (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultCard(String title, String content, {required IconData icon, required Color accentColor}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                TtsButton(text: '$title: $content', color: accentColor, size: 28),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: _HealthDecoration.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
