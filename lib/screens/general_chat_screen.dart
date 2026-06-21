import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gemini_service.dart';
import '../services/ad_service.dart';
import 'tts_button.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class GeneralChatScreen extends StatefulWidget {
  const GeneralChatScreen({super.key});

  @override
  State<GeneralChatScreen> createState() => _GeneralChatScreenState();
}

class _HomeDecoration {
  static const Color primaryGreen = Color(0xFF1E5631);
  static const Color accentGold = Color(0xFFE5A93B);
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF2E3D30);
  static const Color textLight = Colors.white;
  static const Color textMuted = Color(0xFF7A8D7C);
}

class _GeneralChatScreenState extends State<GeneralChatScreen> {
  final _geminiService = GeminiService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestionChips = [
    'सेंद्रिय खताचे प्रकार',
    'पेरणीची योग्य वेळ',
    'कीड नियंत्रण कसे करावे',
    'जिवामृत तयार करण्याची पद्धत',
    'पाण्याचे योग्य नियोजन',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message in Marathi
    _messages.add(
      ChatMessage(
        text: 'नमस्कार शेतकरी बंधूंनो! मी आपला कृषी सेंद्रिय सल्लागार आहे. सेंद्रिय शेती, लागवड, खते आणि पिकांच्या संगोपनाबाबत काहीही विचारण्यासाठी मी तयार आहे. खालीलपैकी एखादा पर्याय निवडा किंवा आपला प्रश्न टाईप करा.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final reply = await _geminiService.askGeneralQuestion(text);
      
      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'क्षमस्व, काहीतरी त्रुटी आली. कृपया नंतर प्रयत्न करा.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomeDecoration.lightBackground,
      bottomNavigationBar: AdService.instance.getBannerWidget(context),
      appBar: AppBar(
        backgroundColor: _HomeDecoration.primaryGreen,
        foregroundColor: _HomeDecoration.textLight,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _HomeDecoration.accentGold.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa,
                color: _HomeDecoration.accentGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'कृषी सल्लागार (AI)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit',
                  ),
                ),
                Text(
                  'काहीही विचारा...',
                  style: TextStyle(
                    fontSize: 12,
                    color: _HomeDecoration.accentGold,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildChatBubble(_messages[index]);
                },
              ),
            ),

            // Suggestions section (only shown when no user query is running)
            if (!_isTyping && _messages.length <= 2)
              _buildSuggestionsSection(),

            // Chat Input Box
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestionChips.length,
        itemBuilder: (context, index) {
          final chipText = _suggestionChips[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(
                chipText,
                style: const TextStyle(
                  color: _HomeDecoration.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _HomeDecoration.primaryGreen.withOpacity(0.3),
                width: 1.5,
              ),
              shadowColor: Colors.black.withOpacity(0.05),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _sendMessage(chipText),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? _HomeDecoration.primaryGreen : _HomeDecoration.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? _HomeDecoration.textLight : _HomeDecoration.textDark,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isUser)
                  TtsButton(
                    text: message.text,
                    size: 28,
                    color: _HomeDecoration.primaryGreen,
                  )
                else
                  const SizedBox(),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isUser
                        ? _HomeDecoration.textLight.withOpacity(0.7)
                        : _HomeDecoration.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _HomeDecoration.cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _HomeDecoration.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _HomeDecoration.accentGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _HomeDecoration.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'उत्तर शोधत आहे...',
              style: TextStyle(
                color: _HomeDecoration.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'सेंद्रिय शेतीबद्दल प्रश्न विचारा...',
                hintStyle: const TextStyle(
                  color: _HomeDecoration.textMuted,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: _HomeDecoration.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: _HomeDecoration.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}
