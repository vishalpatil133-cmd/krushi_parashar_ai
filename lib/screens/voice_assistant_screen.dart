import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/gemini_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  final String userId;
  const VoiceAssistantScreen({super.key, required this.userId});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final GeminiService _gemini = GeminiService();
  
  bool _isListening = false;
  bool _isLoading = false;
  String _userSpeechText = 'तुमचा प्रश्न बोलण्यासाठी खालील माईक दाबा...';
  String _assistantResponse = '';
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  void _initTts() {
    _tts = FlutterTts();
    _tts.setLanguage('mr-IN');
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.85);
  }

  @override
  void dispose() {
    _tts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() {
              _isListening = false;
              _pulseController.stop();
            });
            if (_userSpeechText.isNotEmpty && 
                _userSpeechText != 'तुमचा प्रश्न बोलण्यासाठी खालील माईक दाबा...' &&
                !_userSpeechText.startsWith('बोला, मी ऐकत आहे')) {
              _getGeminiResponse(_userSpeechText);
            }
          }
        },
        onError: (val) => print('Speech recognition error: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _userSpeechText = 'बोला, मी ऐकत आहे...';
          _assistantResponse = '';
        });
        _tts.stop();
        _pulseController.repeat(reverse: true);
        _speech.listen(
          localeId: 'mr_IN',
          onResult: (val) => setState(() {
            _userSpeechText = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _pulseController.stop();
      });
      _speech.stop();
    }
  }

  Future<void> _getGeminiResponse(String query) async {
    setState(() {
      _isLoading = true;
      _assistantResponse = 'उत्तर शोधत आहे...';
    });

    try {
      final response = await _gemini.askVoiceAssistant(query);
      setState(() {
        _assistantResponse = response;
        _isLoading = false;
      });
      // Speak response out loud in Marathi
      await _tts.speak(response);
    } catch (e) {
      setState(() {
        _assistantResponse = 'त्रुटी: उत्तर मिळवता आले नाही.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F291C), // Deep forest green
      appBar: AppBar(
        title: const Text(
          'ऋषी पराशर एआय बोलणारा मित्र',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0B1E14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F291C), Color(0xFF05110B)],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header / Intro
            const Text(
              'शेतीविषयक कोणताही प्रश्न विचारण्यासाठी फक्त माईक दाबून बोला. तुमचे उत्तर मराठीत दिले जाईल आणि वाचून दाखवले जाईल.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB8C7B8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Card showing user query
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Color(0xFFE2B43B), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'तुम्ही विचारलेला प्रश्न:',
                            style: TextStyle(
                              color: Color(0xFFE2B43B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userSpeechText,
                        style: TextStyle(
                          color: _userSpeechText.startsWith('बोला') || _userSpeechText.startsWith('तुमचा')
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: Color(0xFF4CAF50), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ऋषी पराशर एआय सल्ला:',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2B43B)),
                            ),
                          ),
                        )
                      else
                        Text(
                          _assistantResponse.isEmpty ? 'सल्ला येथे दिसेल...' : _assistantResponse,
                          style: TextStyle(
                            color: _assistantResponse.isEmpty ? Colors.white30 : Colors.white,
                            fontSize: 17,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Pulsing Mic Button Section
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE2B43B).withOpacity(
                            _isListening ? (0.2 + (0.3 * _pulseController.value)) : 0.0,
                          ),
                          spreadRadius: _isListening ? (10 + (25 * _pulseController.value)) : 0,
                          blurRadius: _isListening ? 15 : 0,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _listen,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFF3C64F), const Color(0xFFD4A220)]
                            : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isListening ? 'ऐकत आहे... बोला' : 'बोलण्यासाठी माईक दाबा',
              style: TextStyle(
                color: _isListening ? const Color(0xFFE2B43B) : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
