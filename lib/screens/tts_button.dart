import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsButton extends StatefulWidget {
  final String text;
  final Color? color;
  final double? size;

  const TtsButton({
    super.key,
    required this.text,
    this.color,
    this.size,
  });

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  static final FlutterTts _flutterTts = FlutterTts();
  static String? _currentlySpeakingText;
  static _TtsButtonState? _activeState;

  bool get _isSpeaking => _currentlySpeakingText == widget.text && _activeState == this;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {});
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (_currentlySpeakingText == widget.text) {
        _currentlySpeakingText = null;
        _activeState = null;
        if (mounted) {
          setState(() {});
        }
      }
    });

    _flutterTts.setCancelHandler(() {
      if (_currentlySpeakingText == widget.text) {
        _currentlySpeakingText = null;
        _activeState = null;
        if (mounted) {
          setState(() {});
        }
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (_currentlySpeakingText == widget.text) {
        _currentlySpeakingText = null;
        _activeState = null;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _speak() async {
    // If something else is speaking, stop it first
    if (_currentlySpeakingText != null) {
      await _flutterTts.stop();
      if (_activeState != null && _activeState!.mounted) {
        _activeState!.setState(() {});
      }
    }

    if (_isSpeaking) {
      // Toggle off if clicking the currently speaking button
      _currentlySpeakingText = null;
      _activeState = null;
      setState(() {});
      return;
    }

    // Clean markdown bold/italic tags and formatting characters to make speech clean
    String cleanText = widget.text
        .replaceAll(RegExp(r'\*\*|__|\*|_|#|`'), '') // Remove markdown formatting
        .replaceAll(RegExp(r'[\r\n]+'), ' ') // Replace newlines with spaces
        .trim();

    if (cleanText.isEmpty) return;

    _currentlySpeakingText = widget.text;
    _activeState = this;
    setState(() {});

    try {
      await _flutterTts.setLanguage("mr-IN");
      await _flutterTts.setSpeechRate(0.85); // slightly slower for local farmers
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      final result = await _flutterTts.speak(cleanText);
      if (result == 0) {
        // failed
        _currentlySpeakingText = null;
        _activeState = null;
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('मराठी आवाज सुरू करता आला नाही!')),
          );
        }
      }
    } catch (e) {
      _currentlySpeakingText = null;
      _activeState = null;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('टीटीएस त्रुटी: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_isSpeaking) {
      _flutterTts.stop();
      _currentlySpeakingText = null;
      _activeState = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = widget.color ?? const Color(0xFF1E5631);
    final size = widget.size ?? 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _isSpeaking ? const Color(0xFFE5A93B).withOpacity(0.15) : primaryGreen.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isSpeaking ? const Color(0xFFE5A93B) : primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: size * 0.55,
        icon: Icon(
          _isSpeaking ? Icons.volume_off : Icons.volume_up,
          color: _isSpeaking ? const Color(0xFFE5A93B) : primaryGreen,
        ),
        tooltip: _isSpeaking ? 'आवाज बंद करा' : 'वाचून दाखवा (AI)',
        onPressed: _speak,
      ),
    );
  }
}
