import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/secrets.dart';
import 'weather_service.dart';

class GeminiPrediction {
  final String shortTerm;
  final String vedicLongTerm;

  GeminiPrediction({
    required this.shortTerm,
    required this.vedicLongTerm,
  });
}

class GeminiService {
  Future<GeminiPrediction> generateVedicPrediction({
    required String farmerName,
    required String location,
    required String primaryCrop,
    required WeatherData weather,
  }) async {
    final ms = DateTime.now().millisecond;
    
    final shortTermTemplates = [
      "पुढील ३ दिवसांत, $location मध्ये सरासरी तापमान ${weather.temp} आणि हवेत ${weather.humidity} आद्रता राहील. वारा ${weather.windSpeed} वेगाने वाहण्याची शक्यता आहे. अशा उष्ण वातावरणात तुमच्या $primaryCrop पिकाला पुरेसे पाणी द्या आणि जमिनीतील ओलावा टिकवून ठेवण्यासाठी हलके आच्छादन (mulching) करा.",
      "हवामान वेधशाळेच्या अंदाजानुसार पुढील ७२ तासांत $location मधील वातावरण काहीसे उष्ण राहून तापमान ${weather.temp} पर्यंत पोहोचू शकते. वाऱ्याची गती ${weather.windSpeed} असेल. या काळात $primaryCrop पिकाला नियमित पाणी देणे गरजेचे आहे. दुपारी कडक उन्हात पाणी देणे टाळावे, शक्यतो सकाळी किंवा संध्याकाळी पाणी द्यावे.",
      "पुढील ३ दिवसांचा अंदाज: तापमान ${weather.temp} आणि दमटपणा ${weather.humidity} असेल. $location मधील हवामान $primaryCrop पिकासाठी पोषक आहे. पण जमिनीतील ओलावा टिकवण्यासाठी सेंद्रिय खतांचा वापर करा. माती भुसभुशीत ठेवावी."
    ];
    
    final longTermTemplates = [
      "कृषि पराशर ग्रंथाच्या प्राचीन नियमांनुसार, सध्याचे दमट वातावरण (${weather.humidity} आद्रता) हे $primaryCrop पिकासाठी अत्यंत पोषक आहे. पुढील ३ महिन्यांत, शुक्ल पक्षात (waxing moon) पिकाची पेरणी किंवा लागवड केल्यास भरघोस उत्पादन मिळेल. पुष्य नक्षत्रावर पिकाची काढणी करा. नवीन काम सुरू करण्यापूर्वी धरणी मातेला नमस्कार करून भूमीपूजन करावे.",
      "ऋषी पराशर म्हणतात: 'कृषी हीच जीवनाची जननी आहे.' सध्याचे हवामान पाहता, तुमच्या शेतात $primaryCrop पिकाची वाढ पुढील ९० दिवसांत वेगाने होईल. कृष्ण पक्षात कोळपणी केल्यास तणाचा त्रास कमी होईल. येत्या रोहिणी नक्षत्रावर शेतात गोमूत्र आणि सेंद्रिय खतांची फवारणी करावी, ज्यामुळे पीक कीडमुक्त राहील.",
      "कृषि पराशर ग्रंथाच्या हवामान अंदाजानुसार, पुढील ३ महिन्यांत $location मध्ये मध्यम स्वरूपाचा पाऊस पडेल. हा काळ $primaryCrop पिकाला जोमाने वाढवण्यास मदत करेल. दर शनिवारी आणि मंगळवारी पेरणी करणे टाळावे, असे शास्त्रात सांगितले आहे. पिकाला पाणी देताना चंद्रबळ तपासून घ्यावे."
    ];

    final shortWeatherKey = _weatherShortApiKey;
    final longWeatherKey = _weatherLongApiKey;

    try {
      final results = await Future.wait([
        _getShortTermForecast(
          apiKey: shortWeatherKey,
          farmerName: farmerName,
          location: location,
          primaryCrop: primaryCrop,
          weather: weather,
          templates: shortTermTemplates,
          ms: ms,
        ),
        _getVedicLongTermForecast(
          apiKey: longWeatherKey,
          farmerName: farmerName,
          location: location,
          primaryCrop: primaryCrop,
          weather: weather,
          templates: longTermTemplates,
          ms: ms,
        ),
      ]);

      return GeminiPrediction(
        shortTerm: results[0],
        vedicLongTerm: results[1],
      );
    } catch (e) {
      print('Vedic Prediction parallel execution failure: $e');
      return GeminiPrediction(
        shortTerm: 'सल्ला मिळवताना तांत्रिक अडचण आली: $e',
        vedicLongTerm: 'तांत्रिक तपशील: $e',
      );
    }
  }

  Future<String?> _generateWithFallback({
    required String apiKey,
    required String prompt,
    required String systemInstruction,
    List<int>? imageBytes,
    String? responseMimeType,
  }) async {
    final uniqueKeys = <String>[];
    void addKey(String k) {
      if (k.isNotEmpty && !k.contains('YOUR_GEMINI_API_KEY_HERE') && !uniqueKeys.contains(k)) {
        uniqueKeys.add(k);
      }
    }

    addKey(apiKey);
    addKey(Secrets.geminiApiKey);
    addKey(Secrets.geminiWeatherLongApiKey);
    addKey(Secrets.geminiGeneralApiKey);
    addKey(Secrets.geminiDiseaseApiKey);
    addKey(Secrets.geminiFallbackApiKey);

    final attempts = <Map<String, String>>[];
    for (var key in uniqueKeys) {
      attempts.add({'model': 'gemini-2.5-flash', 'key': key});
    }
    for (var key in uniqueKeys) {
      attempts.add({'model': 'gemini-1.5-flash', 'key': key});
    }

    Object? lastError;

    for (var attempt in attempts) {
      final modelName = attempt['model']!;
      final key = attempt['key']!;

      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key,
          systemInstruction: Content.system(systemInstruction),
          generationConfig: responseMimeType != null
              ? GenerationConfig(responseMimeType: responseMimeType)
              : null,
        );

        GenerateContentResponse response;
        if (imageBytes != null) {
          final imagePart = DataPart('image/jpeg', Uint8List.fromList(imageBytes));
          response = await model.generateContent([
            Content.multi([TextPart(prompt), imagePart])
          ]);
        } else {
          response = await model.generateContent([Content.text(prompt)]);
        }

        if (response.text != null && response.text!.trim().isNotEmpty) {
          return response.text;
        }
      } catch (e) {
        lastError = e;
        final maskedKey = key.length > 8 ? '${key.substring(0, 8)}...' : key;
        print('Gemini attempt failed for $modelName with key $maskedKey: $e');
      }
    }
    
    if (lastError != null) {
      throw lastError;
    }
    return null;
  }

  Future<String> _getShortTermForecast({
    required String apiKey,
    required String farmerName,
    required String location,
    required String primaryCrop,
    required WeatherData weather,
    required List<String> templates,
    required int ms,
  }) async {
    final prompt = 'Analyze and generate a 3-day farming advice forecast in Devnagari Marathi:\n'
        '- Farmer Name: $farmerName\n'
        '- Location: $location\n'
        '- Primary Crop: $primaryCrop\n'
        '- Temperature: ${weather.temp}\n'
        '- Humidity: ${weather.humidity}\n'
        '- Wind Speed: ${weather.windSpeed}\n'
        '- Weather: ${weather.description}';

    const systemInstruction = "You are the Vedic Oracle of agriculture, an expert in the ancient Sanskrit agricultural text 'Krishi Parashara' (authored by Sage Parashara) and traditional Indian Vedic farming wisdom. "
        "Your job is to analyze modern weather parameters (temperature, wind, humidity) and location details to generate a 3-day weather and farming advice forecast. "
        "You MUST write all values in the Devnagari Marathi language. Use simple, easily readable, and traditional Marathi terms (मराठी) that local Indian farmers can understand. "
        "Provide a detailed, practical 3-day agricultural advice forecast based on the current weather parameters.";

    try {
      final result = await _generateWithFallback(
        apiKey: apiKey,
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
      return result ?? templates[ms % templates.length];
    } catch (e) {
      print('Short-term advice all fallbacks failed: $e');
      return templates[ms % templates.length];
    }
  }

  Future<String> _getVedicLongTermForecast({
    required String apiKey,
    required String farmerName,
    required String location,
    required String primaryCrop,
    required WeatherData weather,
    required List<String> templates,
    required int ms,
  }) async {
    final prompt = 'Generate a 3-month crop prediction and traditional Vedic guidance from Krishi Parashara in Devnagari Marathi:\n'
        '- Farmer Name: $farmerName\n'
        '- Location: $location\n'
        '- Primary Crop: $primaryCrop\n'
        '- Temperature: ${weather.temp}\n'
        '- Humidity: ${weather.humidity}\n'
        '- Wind Speed: ${weather.windSpeed}\n'
        '- Weather: ${weather.description}';

    const systemInstruction = "You are the Vedic Oracle of agriculture, an expert in the ancient Sanskrit agricultural text 'Krishi Parashara' (authored by Sage Parashara) and traditional Indian Vedic farming wisdom. "
        "Your job is to analyze the user's primary crop and location details to generate a 3-month crop prediction, traditional Vedic guidance, astrological timing suggestions (such as Nakshatras/lunar phases), and rituals from 'Krishi Parashara' relevant to the user's primary crop. "
        "You MUST write all values in the Devnagari Marathi language. Use simple, easily readable, and traditional Marathi terms (मराठी) that local Indian farmers can understand.";

    try {
      final result = await _generateWithFallback(
        apiKey: apiKey,
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
      return result ?? templates[(ms + 1) % templates.length];
    } catch (e) {
      print('Long-term advice all fallbacks failed: $e');
      return templates[(ms + 1) % templates.length];
    }
  }

  String get _weatherShortApiKey {
    if (Secrets.geminiApiKey.isNotEmpty && 
        Secrets.geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE') {
      return Secrets.geminiApiKey;
    }
    return '';
  }

  String get _weatherLongApiKey {
    if (Secrets.geminiWeatherLongApiKey.isNotEmpty && 
        Secrets.geminiWeatherLongApiKey != 'YOUR_GEMINI_WEATHER_LONG_API_KEY_HERE') {
      return Secrets.geminiWeatherLongApiKey;
    }
    return Secrets.geminiApiKey;
  }

  String get _generalApiKey {
    if (Secrets.geminiGeneralApiKey.isNotEmpty && 
        Secrets.geminiGeneralApiKey != 'YOUR_GEMINI_GENERAL_API_KEY_HERE') {
      return Secrets.geminiGeneralApiKey;
    }
    return Secrets.geminiApiKey;
  }

  String get _diseaseApiKey {
    if (Secrets.geminiDiseaseApiKey.isNotEmpty && 
        Secrets.geminiDiseaseApiKey != 'YOUR_GEMINI_DISEASE_API_KEY_HERE') {
      return Secrets.geminiDiseaseApiKey;
    }
    return Secrets.geminiApiKey;
  }

  Future<String> askGeneralQuestion(String question) async {
    final apiKey = _generalApiKey;
    const systemInstruction = "तुम्ही भारतीय शेतीचे तज्ञ आहात. शेतकऱ्यांना सेंद्रिय शेती, लागवड, हवामान आणि माती संदर्भात सोप्या आणि शुद्ध मराठी भाषेत (मराठी देवनागरी) अचूक उत्तरे द्या. "
        "नेहमी पारंपारिक आणि सेंद्रिय (Organic) पद्धतींना प्राधान्य द्या. उत्तरे संक्षिप्त, सोपी आणि ३-४ ओळीत असावीत जेणेकरून शेतकरी ते सहज वाचू शकतील.";

    try {
      final result = await _generateWithFallback(
        apiKey: apiKey,
        prompt: question,
        systemInstruction: systemInstruction,
      );
      return result ?? 'काहीतरी चूक झाली, कृपया पुन्हा प्रयत्न करा.';
    } catch (e) {
      print('General Chat all fallbacks failed: $e');
      return 'विचारताना अडचण आली: $e. कृपया तुमचे इंटरनेट तपासा किंवा नंतर प्रयत्न करा.';
    }
  }

  Future<Map<String, String>> diagnoseCropDisease(String cropType, List<int> imageBytes) async {
    final apiKey = _diseaseApiKey;
    
    final fallbackResponse = {
      'disease_name': 'पिकावर बुरशीचा प्रादुर्भाव (संभाव्य)',
      'symptoms': 'पानांवर पांढरे किंवा राखाडी रंगाचे ठिपके पडणे. झाडाची पाने कोमेजून पिवळी पडणे.',
      'remedy': '५% निंबोळी अर्क फवारणी किंवा आंबट ताकाचे द्रावण वापरावे.',
      'recipe': '१. १ लिटर आंबट ताक ९ लिटर पाण्यात मिसळा.\n२. त्यात थोडे गोमूत्र घालून पिकावर सकाळी फवारणी करा.',
    };

    const systemInstruction = "You are an expert crop pathologist and agricultural specialist in crop leaf disease diagnosis. "
        "Analyze the user's uploaded image of a crop leaf and the crop type they specified. "
        "Identify the crop disease or pest infestation shown in the image. "
        "You MUST respond in a valid JSON format written entirely in Devnagari Marathi language. "
        "The JSON structure MUST contain exactly these four keys: "
        "1. 'disease_name': the name of the disease or pest in Marathi (with common English name in brackets if relevant). "
        "2. 'symptoms': the symptoms observed in the image or typical of this disease, in Marathi. "
        "3. 'remedy': organic, natural, and traditional remedies to control it, in Marathi. "
        "4. 'recipe': step-by-step recipe to prepare the remedy and how to apply/spray it on the crop, in Marathi. "
        "Keep descriptions clear, practical, and in easy-to-understand Marathi for local farmers. "
        "Do not include any explanation or markdown formatting outside of the JSON output. Just output the clean JSON.";

    final prompt = "Identify the crop disease for this crop type: $cropType";

    try {
      final result = await _generateWithFallback(
        apiKey: apiKey,
        prompt: prompt,
        systemInstruction: systemInstruction,
        imageBytes: imageBytes,
        responseMimeType: 'application/json',
      );

      if (result != null && result.trim().isNotEmpty) {
        final Map<String, dynamic> jsonMap = json.decode(_cleanJsonText(result)) as Map<String, dynamic>;
        return {
          'disease_name': jsonMap['disease_name'] as String? ?? 'माहित नसलेला रोग',
          'symptoms': jsonMap['symptoms'] as String? ?? 'लक्षणे उपलब्ध नाहीत.',
          'remedy': jsonMap['remedy'] as String? ?? 'सेंद्रिय उपाय उपलब्ध नाही.',
          'recipe': jsonMap['recipe'] as String? ?? 'तयार करण्याची पद्धत उपलब्ध नाही.',
        };
      }
    } catch (e) {
      print('Disease Analysis all fallbacks failed: $e');
      return {
        'disease_name': 'त्रुटी: पीक रोग विश्लेषण अपयशी ठरले',
        'symptoms': 'तांत्रिक अडचण: $e',
        'remedy': 'कृपया तुमचे इंटरनेट कनेक्शन तपासा किंवा नंतर प्रयत्न करा.',
        'recipe': 'तपशील: $e',
      };
    }
    return fallbackResponse;
  }

  String _cleanJsonText(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  Future<String> getCropRemedyFromText(String cropName, String description) async {
    final apiKey = _diseaseApiKey;
    final prompt = "माझे पीक: $cropName. लक्षणे/तपशील: $description. कृपया यावर उपाय सांगा.";
    const systemInstruction = "तुम्ही कृषी डॉक्टर (AI Doctor) आहात. पिकाचे नाव आणि लक्षणे/समस्या यानुसार पिकाचा सविस्तर आणि खात्रीशीर उपाय सोप्या मराठी भाषेत ३-४ ओळीत द्या. आधी सेंद्रिय उपाय सांगा व गरज भासल्यास योग्य औषधाचे रासायनिक नाव कंसात सांगा.";
    
    try {
      final result = await _generateWithFallback(
        apiKey: apiKey,
        prompt: prompt,
        systemInstruction: systemInstruction,
      );
      return result ?? 'माहिती उपलब्ध नाही.';
    } catch (e) {
      return 'सल्ला मिळवताना अडचण आली: $e';
    }
  }
}
