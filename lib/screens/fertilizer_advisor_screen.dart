import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class FertilizerModel {
  final String cropName;
  final double nPerAcre; // Nitrogen per acre in kg
  final double pPerAcre; // Phosphorus per acre in kg
  final double kPerAcre; // Potassium per acre in kg
  final String description;
  final String applicationSchedule;

  FertilizerModel({
    required this.cropName,
    required this.nPerAcre,
    required this.pPerAcre,
    required this.kPerAcre,
    required this.description,
    required this.applicationSchedule,
  });
}

class FertilizerAdvisorScreen extends StatefulWidget {
  final WeatherData? weather;
  const FertilizerAdvisorScreen({super.key, this.weather});

  @override
  State<FertilizerAdvisorScreen> createState() => _FertilizerAdvisorScreenState();
}

class _FertilizerAdvisorScreenState extends State<FertilizerAdvisorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sizeController = TextEditingController(text: '1');
  String _selectedUnit = 'एकर';
  FertilizerModel? _selectedCrop;

  // Local structured database of recommended fertilizers (NPK in kg/acre)
  final List<FertilizerModel> _cropsDatabase = [
    FertilizerModel(
      cropName: 'भात (तांदूळ)',
      nPerAcre: 40.0,
      pPerAcre: 20.0,
      kPerAcre: 20.0,
      description: 'भाताच्या पिकाला नत्र (N), स्फुरद (P) आणि पालाश (K) ची संतुलित गरज असते. लागवडीच्या वेळी आणि फुटवे येताना खत देणे गरजेचे आहे.',
      applicationSchedule: '१. रोवणीच्या वेळी (Basal Dose): २० किलो नत्र, २० किलो स्फुरद, २० किलो पालाश.\n२. फुटवे येताना (Tillering): १० किलो नत्र.\n३. लोंब्या बाहेर पडताना (Panicle Initiation): १० किलो नत्र.',
    ),
    FertilizerModel(
      cropName: 'गहू',
      nPerAcre: 48.0,
      pPerAcre: 24.0,
      kPerAcre: 16.0,
      description: 'गहू पिकाला पहिल्या सिंचनाच्या वेळी नत्राचा पहिला डोस देणे उत्पादनात वाढ करते.',
      applicationSchedule: '१. पेरणीच्या वेळी (Basal Dose): २४ किलो नत्र, २४ किलो स्फुरद, १६ किलो पालाश.\n२. मुकुटमुळे फुटण्याच्या वेळी (पेरणीनंतर २१ दिवस): १२ किलो नत्र.\n३. कांड्या धरण्याच्या अवस्थेत (पेरणीनंतर ४२ दिवस): १२ किलो नत्र.',
    ),
    FertilizerModel(
      cropName: 'कापूस',
      nPerAcre: 48.0,
      pPerAcre: 24.0,
      kPerAcre: 24.0,
      description: 'कापसाला पालाश (पोटॅश) योग्य प्रमाणात दिल्यास बोंडांचे वजन वाढते आणि दर्जेदार कापूस मिळतो.',
      applicationSchedule: '१. पेरणीच्या वेळी: १० किलो नत्र, २४ किलो स्फुरद, २४ किलो पालाश.\n२. पेरणीनंतर ३० दिवसांनी: १८ किलो नत्र.\n३. पेरणीनंतर ६० दिवसांनी (पात्या धरताना): २० किलो नत्र.',
    ),
    FertilizerModel(
      cropName: 'ऊस',
      nPerAcre: 100.0,
      pPerAcre: 46.0,
      kPerAcre: 46.0,
      description: 'ऊस हे दीर्घ मुदतीचे पीक असल्याने खतांचे नियोजन ४ वेगवेगळ्या हप्त्यांमध्ये केले जाते.',
      applicationSchedule: '१. लागवडीच्या वेळी: १५ किलो नत्र, ४६ किलो स्फुरद, ४६ किलो पालाश.\n२. लागवडीनंतर ६ ते ८ आठवड्यांनी: ३० किलो नत्र.\n३. लागवडीनंतर १२ ते १४ आठवड्यांनी: १५ किलो नत्र.\n४. मोठ्या बांधणीच्या वेळी (सुरुवातीला): ४० किलो नत्र.',
    ),
    FertilizerModel(
      cropName: 'सोयाबीन',
      nPerAcre: 12.0,
      pPerAcre: 30.0,
      kPerAcre: 12.0,
      description: 'सोयाबीन हे द्विदल पीक असल्याने याला कमी प्रमाणात नत्र आणि जास्त प्रमाणात स्फुरद (फॉस्फरस) आवश्यक असते.',
      applicationSchedule: '१. पेरणीच्या वेळी (Basal Dose): संपूर्ण १२ किलो नत्र, ३० किलो स्फुरद आणि १२ किलो पालाश जमिनीतून द्यावे.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Default select first crop
    if (_cropsDatabase.isNotEmpty) {
      _selectedCrop = _cropsDatabase.first;
    }
  }

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  // Weather Sync Logic: Check if it's raining or rain is forecasted
  bool _isRainForecasted() {
    if (widget.weather == null) return false;
    final desc = widget.weather!.description.toLowerCase();
    return desc.contains('rain') ||
        desc.contains('drizzle') ||
        desc.contains('shower') ||
        desc.contains('storm') ||
        desc.contains('पाऊस') ||
        desc.contains('वरुण') ||
        desc.contains('गर्जने');
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);
    const softOffWhite = Color(0xFFFAFAF7);

    // Calculate farm size in Acres
    double farmSizeInAcres = 1.0;
    final sizeText = _sizeController.text.trim();
    if (sizeText.isNotEmpty) {
      final parsed = double.tryParse(sizeText);
      if (parsed != null && parsed > 0) {
        if (_selectedUnit == 'गुंठे') {
          farmSizeInAcres = parsed / 40.0;
        } else {
          farmSizeInAcres = parsed;
        }
      }
    }

    // NPK Requirements
    final requiredN = (_selectedCrop?.nPerAcre ?? 0) * farmSizeInAcres;
    final requiredP = (_selectedCrop?.pPerAcre ?? 0) * farmSizeInAcres;
    final requiredK = (_selectedCrop?.kPerAcre ?? 0) * farmSizeInAcres;

    // Commercial Fertilizer Calculations:
    // Urea (46% N) -> kg needed = N / 0.46
    // Single Super Phosphate (SSP) (16% P) -> kg needed = P / 0.16
    // Muriate of Potash (MOP) (60% K) -> kg needed = K / 0.60
    final ureaKg = requiredN / 0.46;
    final sspKg = requiredP / 0.16;
    final mopKg = requiredK / 0.60;

    final ureaBags = ureaKg / 50.0;
    final sspBags = sspKg / 50.0;
    final mopBags = mopKg / 50.0;

    final hasRain = _isRainForecasted();

    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: AppBar(
        title: const Text(
          'खत सल्लागार व कॅल्क्युलेटर',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. WEATHER INTEGRATION WARNING BANNER
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasRain ? Colors.red[300]! : primaryGreen.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  color: hasRain ? Colors.red[50] : primaryGreen.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          hasRain ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          color: hasRain ? Colors.red[700] : primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasRain ? 'हवामान इशारा: पाऊस!' : 'हवामान अनुकूल आहे',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasRain ? Colors.red[800] : primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasRain
                                    ? 'सध्या तुमच्या जिल्ह्यात पाऊस पडण्याची शक्यता आहे. कृपया आत्ता खतांचा वापर टाळावा. पावसामुळे खते वाहून जाऊन वाया जाण्याची शक्यता जास्त आहे.'
                                    : 'सध्या पाऊस पडण्याची शक्यता नाही. खत टाकण्यासाठी हवामान योग्य आहे. खत दिल्यानंतर हलके पाणी द्यावे.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasRain ? Colors.red[900] : Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 2. CROP SELECTOR
                Text(
                  'पीक निवडा',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<FertilizerModel>(
                  value: _selectedCrop,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.agriculture_rounded, color: primaryGreen),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  hint: const Text('पीक निवडा'),
                  items: _cropsDatabase.map((FertilizerModel crop) {
                    return DropdownMenuItem<FertilizerModel>(
                      value: crop,
                      child: Text(crop.cropName, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCrop = newValue;
                    });
                  },
                ),
                const SizedBox(height: 4),

                if (_selectedCrop != null) ...[
                  // Crop Description Card
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: accentGold, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${_selectedCrop!.cropName} खत माहिती',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCrop!.description,
                            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.4),
                          ),
                          const SizedBox(height: 4),
                          const Divider(height: 1),
                          const SizedBox(height: 4),
                          Text(
                            'शिफारस केलेले प्रति एकर प्रमाण (NPK):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNpkIndicator('नत्र (N)', '${_selectedCrop!.nPerAcre} किलो', Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNpkIndicator('स्फुरद (P)', '${_selectedCrop!.pPerAcre} किलो', Colors.orange),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildNpkIndicator('पालाश (K)', '${_selectedCrop!.kPerAcre} किलो', Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 3. FARM SIZE INPUT & CALCULATOR
                  Text(
                    'क्षेत्रफळ टाका (Farm Size)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _sizeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'उदा. १.५',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {}); // trigger calculation update
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              items: <String>['एकर', 'गुंठे'].map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (newUnit) {
                                if (newUnit != null) {
                                  setState(() {
                                    _selectedUnit = newUnit;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 4. CALCULATOR RESULTS PANEL
                  Text(
                    'आवश्यक खतांचे प्रमाण (युरिया, एसएसपी, एमओपी):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: primaryGreen.withOpacity(0.15), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          _buildCalculatorRow(
                            label: 'युरिया (Urea)',
                            nutrient: 'नत्र डोससाठी',
                            qtyKg: ureaKg,
                            qtyBags: ureaBags,
                            iconColor: Colors.blue[600]!,
                          ),
                          const Divider(height: 20),
                          _buildCalculatorRow(
                            label: 'सिंगल सुपर फॉस्फेट (SSP)',
                            nutrient: 'स्फुरद डोससाठी',
                            qtyKg: sspKg,
                            qtyBags: sspBags,
                            iconColor: Colors.orange[700]!,
                          ),
                          const Divider(height: 20),
                          _buildCalculatorRow(
                            label: 'म्युरेट ऑफ पोटॅश (MOP)',
                            nutrient: 'पालाश डोससाठी',
                            qtyKg: mopKg,
                            qtyBags: mopBags,
                            iconColor: Colors.red[600]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 5. APPLICATION SCHEDULE
                  Card(
                    color: Colors.amber[50]!.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.amber[200]!.withOpacity(0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, color: Colors.amber[800], size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'खते देण्याची वेळापत्रक (Timing):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCrop!.applicationSchedule,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.6,
                              color: Colors.grey[850],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNpkIndicator(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorRow({
    required String label,
    required String nutrient,
    required double qtyKg,
    required double qtyBags,
    required Color iconColor,
  }) {
    final bagsString = qtyBags.toStringAsFixed(1);
    final kgString = qtyKg.toStringAsFixed(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inventory_2_outlined, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E5631)),
              ),
              Text(
                nutrient,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$bagsString पोती (Bags)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: iconColor),
            ),
            Text(
              '$kgString किलो (Kg)',
              style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
