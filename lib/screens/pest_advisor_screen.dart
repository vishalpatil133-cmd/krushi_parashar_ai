import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../config/secrets.dart';
import 'disease_detail_screen.dart';

class DiseaseModel {
  final String name;
  final String crop;
  final String symptoms;
  final String organicRemedy;
  final String recipe;
  final String vedicQuote;
  final String photoUrl;
  final String chemicalRemedy;

  DiseaseModel({
    required this.name,
    required this.crop,
    required this.symptoms,
    required this.organicRemedy,
    required this.recipe,
    required this.vedicQuote,
    required this.photoUrl,
    this.chemicalRemedy = 'माहिती उपलब्ध नाही.',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'crop': crop,
      'symptoms': symptoms,
      'organicRemedy': organicRemedy,
      'recipe': recipe,
      'vedicQuote': vedicQuote,
      'photoUrl': photoUrl,
      'chemicalRemedy': chemicalRemedy,
    };
  }

  factory DiseaseModel.fromMap(Map<dynamic, dynamic> map) {
    return DiseaseModel(
      name: map['name'] as String? ?? 'अज्ञात रोग',
      crop: map['crop'] as String? ?? 'सर्व पिके',
      symptoms: map['symptoms'] as String? ?? '',
      organicRemedy: map['organicRemedy'] as String? ?? '',
      recipe: map['recipe'] as String? ?? '',
      vedicQuote: map['vedicQuote'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      chemicalRemedy: map['chemicalRemedy'] as String? ?? 'माहिती उपलब्ध नाही.',
    );
  }
}

class PestAdvisorScreen extends StatefulWidget {
  const PestAdvisorScreen({super.key});

  @override
  State<PestAdvisorScreen> createState() => _PestAdvisorScreenState();
}

class _PestAdvisorScreenState extends State<PestAdvisorScreen> {
  String _selectedCrop = 'सर्व पिके';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _cropCategories = [
    'सर्व पिके',
    'भात (तांदूळ)',
    'गहू',
    'कापूस',
    'सोयाबीन',
    'ऊस',
    'इतर पिके'
  ];

  List<DiseaseModel> _diseases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDiseases();
  }

  Future<void> _fetchDiseases() async {
    setState(() => _isLoading = true);
    final dbUrl = Secrets.firebaseDatabaseUrl;
    final isFirebaseEnabled = dbUrl.startsWith('http') && !dbUrl.contains('YOUR_FIREBASE_DATABASE_URL_HERE');

    if (isFirebaseEnabled) {
      try {
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: dbUrl,
        );
        final ref = db.ref('diseases');
        final snapshot = await ref.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final List<DiseaseModel> fetchedDiseases = [];
          data.forEach((key, value) {
            if (value is Map) {
              fetchedDiseases.add(DiseaseModel.fromMap(value));
            }
          });
          if (fetchedDiseases.isNotEmpty) {
            setState(() {
              _diseases = fetchedDiseases;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        print('Error fetching diseases: $e');
      }
    }

    // Fallback to static list
    setState(() {
      _diseases = List.from(_staticDiseases);
      _isLoading = false;
    });
  }

  final List<DiseaseModel> _staticDiseases = [
    DiseaseModel(
      name: 'खोडकिडा (Stem Borer)',
      crop: 'भात (तांदूळ)',
      symptoms: 'पिकाचे सुकलेले शेंडे (Dead Hearts) आणि लोंब्या पांढऱ्या पडणे (Whiteheads). शेंड्याला हलके ओढल्यास तो सहज हातात येतो.',
      organicRemedy: '५% निंबोळी अर्क (Neem seed kernel extract) किंवा कामगंध सापळे (Pheromone Traps).',
      recipe: '१. ५ किलो निंबोळी पावडर बारीक करून १० लिटर पाण्यात रात्रभर भिजत घाला.\n२. सकाळी द्रावण कापडाने गाळून घ्या आणि त्यात ९० लिटर पाणी मिसळा.\n३. द्रावणात १०० ग्रॅम साबणाचा चुरा (चिकटण्यासाठी) टाकून पिकावर फवारणी करा.',
      vedicQuote: 'शालिधान्ये तु कीटकाः नश्यन्ति निम्बतोयेन... (भात पिकावरील कीड कडुनिंबाच्या पाण्याने नष्ट होते - प्राचीन कृषी शास्त्र)',
      photoUrl: 'https://images.unsplash.com/photo-1551085254-e96b210db58a?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'कार्ताप हायड्रोक्लोराइड ४% जी (Cartap Hydrochloride 4G) - १८ ते २५ किलो प्रति हेक्टरी किंवा फिप्रोनील ०.३% जीआर (Fipronil 0.3% GR) - १५ ते २० किलो प्रति हेक्टरी जमिनीतून द्यावे, किंवा कोराजेन (Chlorantraniliprole 18.5% SC) - ६० मिली प्रति एकर पाण्यात मिसळून फवारावे.',
    ),
    DiseaseModel(
      name: 'करपा रोग (Blast Disease)',
      crop: 'भात (तांदूळ)',
      symptoms: 'पानांवर डोळ्याच्या आकाराचे, मधोमध राखाडी व कडेने तपकिरी रंगाचे ठिपके दिसतात. रोगाचे प्रमाण वाढल्यास पूर्ण पान करपून जाते.',
      organicRemedy: 'ट्रायकोडर्मा विरिडी (Trichoderma viridi) आणि आंबट ताक फवारणी.',
      recipe: '१. ५ लिटर जुने ताक घ्या (जे ७-१० दिवस आंबवलेले असेल).\n२. हे ताक १०० लिटर पाण्यात मिसळून संपूर्ण भाताच्या पिकावर फवारणी करा.\n३. यामुळे बुरशीजन्य रोगांचा प्रादुर्भाव लगेच कमी होतो.',
      vedicQuote: 'शुद्ध गोमूत्र आणि ताक एकत्र करून फवारल्यास पिकाची प्रतिकारशक्ती वाढते व कीड दूर राहते.',
      photoUrl: 'https://images.unsplash.com/photo-1628352081506-83c43123ed6d?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'ट्रायसायक्लाझोल ७५% डब्ल्यूपी (Tricyclazole 75% WP) - १२ मिली प्रति १० लिटर पाण्यात मिसळून फवारणी करावी, किंवा हेक्झाकोनॅझोल ५% ईसी (Hexaconazole 5% EC) - २० मिली प्रति १० लिटर पाण्यात मिसळून फवारावे.',
    ),
    DiseaseModel(
      name: 'तांबेरा रोग (Rust)',
      crop: 'गहू',
      symptoms: 'पानांवर आणि खोडावर तांबूस-पिवळ्या किंवा तपकिरी रंगाचे लहान ठिपके (पुळ्या) दिसतात. बोटाने पुसल्यास हाताला तांबूस पावडर लागते.',
      organicRemedy: 'दशपर्णी अर्क किंवा आंबट ताक व हिंग द्रावण.',
      recipe: '१. २ लिटर आंबट ताक + ५० ग्रॅम हिंग पावडर १०० लिटर पाण्यात चांगल्या प्रकारे मिसळा.\n२. गव्हाच्या पिकावर तांबेरा दिसू लागताच पहिली फवारणी करा.\n३. १० दिवसांच्या अंतराने दुसरी फवारणी केल्याने तांबेरा पूर्ण नियंत्रणात येतो.',
      vedicQuote: 'ऋषी पराशर म्हणतात: हिवाळ्यातील दमट हवामानात पिकांची विशेष काळजी घ्यावी, जेणेकरून बुरशीचा प्रादुर्भाव टळेल.',
      photoUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'प्रोपीकोनॅझोल २५% ईसी (Propiconazole 25% EC - उदा. टिल्ट) - २० मिली किंवा टेबुकॉनॅझोल ५०% ईसी - १५ मिली प्रति १० लिटर पाण्यात मिसळून फवारणी करावी.',
    ),
    DiseaseModel(
      name: 'मावा कीड (Aphids)',
      crop: 'गहू',
      symptoms: 'बारीक हिरवे-काळे किडे पानांच्या मागे व लोंब्यांवर रस शोषतात. पाने पिवळी पडतात आणि चिकट द्रव तयार झाल्याने बुरशी वाढते.',
      organicRemedy: 'अग्निअस्त्र किंवा कडुनिंब तेल फवारणी.',
      recipe: '१. गोमूत्र ५ लिटरमध्ये कडुनिंब पाने २ किलो, लसूण ५०० ग्रॅम आणि तंबाखू ५०० ग्रॅम एकत्र उकळवा.\n२. हे द्रावण थंड करून गाळून घ्या. याला "अग्निअस्त्र" म्हणतात.\n३. २ ते ३ लिटर अग्निअस्त्र १०० लिटर पाण्यात मिसळून फवारा.',
      vedicQuote: 'तीव्र तिखट आणि उग्र वनस्पतींचे अर्क बारीक रसाळ किड्यांचा नायनाट करतात.',
      photoUrl: 'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'इमिडाक्लोप्रिड १७.८% एसएल (Imidacloprid 17.8% SL) - ४ ते ५ मिली किंवा थायामेथोक्साम २५% डब्लूजी (Thiamethoxam 25% WG) - ३ ग्रॅम प्रति १० लिटर पाण्यात मिसळून फवारावे.',
    ),
    DiseaseModel(
      name: 'मावा व तुडतुडे (Sucking Pests)',
      crop: 'कापूस',
      symptoms: 'पाने कडेने पिवळी किंवा लालसर होऊन खालच्या बाजूला वाकतात व गोळा होतात. झाडाची वाढ खुंटते.',
      organicRemedy: 'लसूण-मिरची-आले अर्क किंवा पिवळे चिकट सापळे.',
      recipe: '१. ५०० ग्रॅम हिरवी मिरची, ५०० ग्रॅम लसूण आणि २५० ग्रॅम आले बारीक वाटून पेस्ट बनवा.\n२. हे मिश्रण १५ लिटर पाण्यात मिसळून गाळून घ्या.\n३. कापसावर सकाळच्या वेळी फवारणी करा. उग्र वासामुळे रस शोषणाऱ्या किडी पळून जातात.',
      vedicQuote: 'कटु-तीक्ष्ण रसाने बनवलेले औषध कपाशीवरील सुप्त रस शोषणाऱ्या किडींना शेतातून हाकलून लावते.',
      photoUrl: 'https://images.unsplash.com/photo-1516253593875-bd7ba052fbc5?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'अॅसिटामिप्रीड २०% एसपी (Acetamiprid 20% SP) - ४ ग्रॅम किंवा डायफेंटीयुरॉन ५०% डब्ल्यूपी (Diafenthiuron 50% WP - उदा. पेगासस) - १२ ग्रॅम प्रति १० लिटर पाण्यात मिसळून फवारावे.',
    ),
    DiseaseModel(
      name: 'बोंडअळी (Bollworm)',
      crop: 'कापूस',
      symptoms: 'कापसाच्या बोंडांना छिद्र पडते, त्यातून विष्ठा बाहेर येते. बोंड अकाली उमलते आणि आतील कापूस काळा पडतो.',
      organicRemedy: 'दशपर्णी अर्क आणि कामगंध सापळे.',
      recipe: '१. दशपर्णी अर्क बनवण्यासाठी गोमूत्र, शेण, कडुनिंब, घाणेरी, पपई, करंज, रुई, एरंड इत्यादी १० प्रकारच्या पानांचे द्रावण ३० दिवस आंबवावे.\n२. कपाशीच्या फुलोऱ्याच्या वेळी २ ते ३ लिटर दशपर्णी अर्क १०० लिटर पाण्यातून प्रति एकर फवारावा.',
      vedicQuote: 'दशपर्णीनां कषायेन कीटकाः समूळ विनाशं यान्ति... (दशपर्णी अर्कामुळे किडींचा समूळ नाश होतो - प्राचीन कृषी तंत्रज्ञान)',
      photoUrl: 'https://images.unsplash.com/photo-1605333396915-47ed6b68a00e?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'क्लोरांट्रानिलीप्रोल १८.५% एससी (Chlorantraniliprole 18.5% SC - कोराजेन) - ६ मिली किंवा स्पिनोसॅड ४५% एससी (Spinosad 45% SC) - ५ मिली प्रति १० लिटर पाण्यात मिसळून फवारावे.',
    ),
    DiseaseModel(
      name: 'तांबेरा रोग (Rust)',
      crop: 'सोयाबीन',
      symptoms: 'पानांच्या खालच्या बाजूस बारीक तांबूस आणि पिवळे ठिपके येतात. नंतर पाने सुकतात व गळून पडतात, ज्यामुळे शेंगा पोसत नाहीत.',
      organicRemedy: '५% निंबोळी अर्क आणि ट्रायकोडर्मा.',
      recipe: '१. पेरणीपूर्वी बियाण्याला ट्रायकोडर्मा पावडर चोळावी (५ ग्रॅम प्रति kilo).\n२. उभे पीक ३०-३५ दिवसांचे असताना निंबोळी अर्काची फवारणी प्रतिबंधात्मक उपाय म्हणून करावी.',
      vedicQuote: 'पेरणीपूर्वी बियाण्यावर योग्य संस्कार केल्यास पिकावर भविष्यात रोगांचे प्रमाण अल्प राहते.',
      photoUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'टेबुकॉनॅझोल १०% + सल्फर ६५% डब्लूजी - २५ ग्रॅम किंवा प्रोपीकोनॅझोल २५% ईसी (Propiconazole 25% EC) - १० मिली प्रति १० लिटर पाण्यात फवारणी करावी.',
    ),
    DiseaseModel(
      name: 'खोडमाशी (Stem Fly)',
      crop: 'सोयाबीन',
      symptoms: 'सोयाबीनचे शेंडे सुकून वाळतात. झाडाचे खोड उभे कापल्यास आतमध्ये लालसर भुसा आणि अळी खोड पोखरताना दिसते.',
      organicRemedy: 'पिवळे चिकट सापळे आणि गोमूत्र फवारणी.',
      recipe: '१. एकरी २० पिवळे चिकट सापळे शेतात लावावेत, जेणेकरून उडणाऱ्या माशा त्याला चिकटून मरतात.\n२. गोमूत्र १०% (१० लिटर पाण्यात १ लिटर गोमूत्र) दर १५ दिवसांनी फवारल्यास अळ्यांचा प्रादुर्भाव रोखता येतो.',
      vedicQuote: 'चिकट वनस्पती आणि गोमूत्र हे पिकाला बाह्य कीटक आणि माशांपासून अभेद्य कवच प्रदान करतात.',
      photoUrl: 'https://images.unsplash.com/photo-1615655096345-61a54750068d?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'थायामेथोक्साम ३०% एफएस (Thiamethoxam 30% FS) - १० मिली प्रति किलो बियाण्यास बीजप्रक्रिया करावी, किंवा उभे पीक असताना क्लोरांट्रानिलीप्रोल १८.५% एससी - ६ मिली प्रति १० लिटर पाण्यात फवारावे.',
    ),
    DiseaseModel(
      name: 'हुमणी अळी (White Grub)',
      crop: 'ऊस',
      symptoms: 'उसाची पाने पिवळी पडतात आणि संपूर्ण ऊस सुकतो. ऊस जमिनीतून सहज उपटला जातो, कारण जमिनीतील अळ्या उसाची मुळे कुरतडून खातात.',
      organicRemedy: 'गोमूत्र आणि हिंगाची आळवणी (Drenching) आणि एरंड केक.',
      recipe: '१. ५ लिटर गोमूत्र + १०० ग्रॅम हिंग पावडर २०० लिटर पाण्यात मिसळा.\n२. हे द्रावण उसाच्या मुळाशी थेट ओतावे (आळवणी करावी).\n३. हुमणी नियंत्रणासाठी शेतात एरंडीची पेंड खत म्हणून वापरावी, यामुळे हुमणीचे नियंत्रण होते.',
      vedicQuote: 'भूमीच्या उदरातील शत्रूंना दूर करण्यासाठी हिंग आणि गोमूत्राची आळवणी हा सर्वोत्तम मार्ग आहे.',
      photoUrl: 'https://images.unsplash.com/photo-1601662528567-526cd06f6582?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'फिप्रोनील ४०% + इमिडाक्लोप्रिड ४०% डब्लूजी (Fipronil + Imidacloprid - उदा. लेसेन्टा) - १५० ग्रॅम प्रति एकर पाण्यात मिसळून उसाच्या मुळापाशी आळवणी (Drenching) करावी, किंवा क्लोरपायरीफॉस २०% ईसी (Chlorpyriphos 20% EC) - १ लिटर प्रति एकर मुळापाशी द्यावे.',
    ),
    DiseaseModel(
      name: 'मर रोग (Wilt)',
      crop: 'इतर पिके',
      symptoms: 'झाड अचानक कोमेजून सुकून जाते. झाड उपटून पाहिल्यास मूळ काळे पडलेले दिसते आणि मुळांवर बुरशी आढळते.',
      organicRemedy: 'ट्रायकोडर्मा खत आणि जिवामृत खत.',
      recipe: '१. २ किलो ट्रायकोडर्मा १०० किलो चांगल्या कुजलेल्या शेणखतात मिसळून एक आठवडा झाकून ठेवावे.\n२. हे खत पिकाच्या ओळींमध्ये जमिनीतून द्यावे आणि हलके पाणी द्यावे.\n३. जिवामृताची नियमित आळवणी मुळांचे रक्षण करते.',
      vedicQuote: 'मृदा संस्काराशिवाय झाडांचे रक्षण अशक्य आहे. शेणखत आणि सेंद्रिय जिवाणू माती जिवंत ठेवतात.',
      photoUrl: 'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'कार्बेंडाझिम ५०% डब्ल्यूपी (Carbendazim 50% WP) - २० ग्रॅम किंवा कॉपर ऑक्सिक्लोराईड ५०% डब्ल्यूपी (Copper Oxychloride 50% WP) - ३० ग्रॅम प्रति १० लिटर पाण्यात मिसळून झाडांच्या मुळाशी आळवणी करावी.',
    ),
    DiseaseModel(
      name: 'पांढरी माशी (Whitefly)',
      crop: 'इतर पिके',
      symptoms: 'पानांच्या खाली पांढऱ्या लहान माश्या उडताना दिसतात. त्या पानांतील रस शोषतात आणि चिकट द्राव निर्माण करतात, ज्यामुळे झाडावर काळी बुरशी येते.',
      organicRemedy: '५% निंबोळी अर्क आणि पिवळे चिकट सापळे.',
      recipe: '१. पिवळ्या रंगाच्या कार्डबोर्डवर एरंडेल तेल लावून सापळा तयार करा व शेतात उंचावर लावा.\n२. तीव्र प्रादुर्भाव असल्यास २५० ग्रॅम निंबोळी तेल प्रति १०० लिटर पाण्यात मिसळून (साबणाच्या द्रावणासह) फवारा.',
      vedicQuote: 'कडू रसाचा लेप झाडांवर राहिल्याने पांढऱ्या माशा रस शोषण्यास असमर्थ ठरतात.',
      photoUrl: 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=600&auto=format&fit=crop&q=80',
      chemicalRemedy: 'डायफेंटीयुरॉन ५०% डब्ल्यूपी (Diafenthiuron 50% WP) - १२ ग्रॅम किंवा पायरीप्रॉक्सीफेन १०% ईसी (Pyriproxyfen 10% EC) - २० मिली प्रति १० लिटर पाण्यात फवारणी करावी.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1E5631);
    const accentGold = Color(0xFFE5A93B);

    // Filter logic
    final filteredDiseases = _diseases.where((disease) {
      final matchesCrop = _selectedCrop == 'सर्व पिके' || disease.crop == _selectedCrop;
      final matchesSearch = disease.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          disease.symptoms.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          disease.organicRemedy.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          disease.chemicalRemedy.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCrop && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: const Text(
          'कीड व रोग सल्लागार',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Header Container
          Container(
            width: double.infinity,
            color: primaryGreen,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: primaryGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      hintText: 'रोग, कीड किंवा उपाय शोधा...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Crop Categories Custom Chips
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
                          onTap: () {
                            setState(() {
                              _selectedCrop = category;
                            });
                          },
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
          const SizedBox(height: 4),

          // Total Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
            child: Text(
              'एकूण आढळलेले रोग: ${filteredDiseases.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),

          // Diseases List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryGreen),
                  )
                : filteredDiseases.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bug_report_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            'कोणतेही रोग किंवा कीड सापडली नाही.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'दुसऱ्या पिकाची निवड करा किंवा वेगळा शब्द शोधून पहा.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredDiseases.length,
                    itemBuilder: (context, index) {
                      final disease = filteredDiseases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiseaseDetailScreen(disease: disease),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Left Disease Photo Thumbnail
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryGreen.withOpacity(0.2), width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: disease.photoUrl.isNotEmpty
                                        ? Image.network(
                                            disease.photoUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: primaryGreen.withOpacity(0.08),
                                                child: const Icon(
                                                  Icons.bug_report,
                                                  color: primaryGreen,
                                                  size: 24,
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: primaryGreen.withOpacity(0.04),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      valueColor: AlwaysStoppedAnimation<Color>(accentGold),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: primaryGreen.withOpacity(0.08),
                                            child: const Icon(
                                              Icons.bug_report,
                                              color: primaryGreen,
                                              size: 24,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Disease Info (Name, Crop)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        disease.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'पीक: ${disease.crop}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Arrow Icon
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: primaryGreen,
                                  size: 28,
                                ),
                              ],
                            ),
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
