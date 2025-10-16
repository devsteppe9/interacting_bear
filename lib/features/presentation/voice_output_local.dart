import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:interacting_bear/features/providers/animation_state_controller.dart';
import 'package:interacting_bear/features/providers/openai_response_controller.dart';

/// A widget that provides local text-to-speech functionality.
/// Uses the device's built-in TTS engine for voice synthesis.
class VoiceOutputLocal extends ConsumerStatefulWidget {
  const VoiceOutputLocal({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<VoiceOutputLocal> createState() => _VoiceOutputLocalState();
}

enum TtsState { playing, stopped, paused, continued }

class _VoiceOutputLocalState extends ConsumerState<VoiceOutputLocal> {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  String? _errorMessage;

  // TTS Configuration
  static const double _volume = 0.7;
  static const double _pitch = 1.0;
  static const double _rate = 0.5;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();
      await _setTTSConfiguration();
      _setupTTSHandlers();

      // Log available engines and voices for debugging
      if (kDebugMode) {
        final engines = await _flutterTts.getEngines;
        final languages = await _flutterTts.getLanguages;
        final voices = await _flutterTts.getVoices;

        debugPrint('TTS Engines: $engines');
        debugPrint('TTS Languages: $languages');
        debugPrint('TTS Voices: $voices');
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      setState(() {
        _errorMessage = 'Failed to initialize text-to-speech';
      });
    }
  }

  Future<void> _setTTSConfiguration() async {
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setSpeechRate(_rate);
    await _flutterTts.setPitch(_pitch);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _setupTTSHandlers() {
    if (_isAndroid) {
      _flutterTts.setInitHandler(() {
        debugPrint('TTS Initialized');
      });
    }

    _flutterTts.setStartHandler(() {
      debugPrint('TTS Started');
      _updateTalkingAnimation(true);
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS Completed');
      _updateTalkingAnimation(false);
    });

    _flutterTts.setCancelHandler(() {
      debugPrint('TTS Cancelled');
      _updateTalkingAnimation(false);
    });

    _flutterTts.setPauseHandler(() {
      debugPrint('TTS Paused');
      _updateTalkingAnimation(false);
    });

    _flutterTts.setContinueHandler(() {
      debugPrint('TTS Continued');
      _updateTalkingAnimation(true);
    });

    _flutterTts.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
      _updateTalkingAnimation(false);
      setState(() {
        _errorMessage = 'Text-to-speech error: $message';
      });
    });
  }

  void _updateTalkingAnimation(bool isTalking) {
    if (mounted) {
      ref
          .read(animationStateControllerProvider.notifier)
          .updateTalking(isTalking);
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty || !_isInitialized) return;

    try {
      // Clear any previous error
      setState(() {
        _errorMessage = null;
      });

      final String currentLang =
          ref.read(animationStateControllerProvider).language;
      final locale = currentLang == 'en' ? 'en-US' : 'ja-JP';

      // Set language
      await _flutterTts.setLanguage(locale);

      // Try to find and set an appropriate voice
      await _setOptimalVoice(locale);

      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error in local TTS: $e');
      _updateTalkingAnimation(false);
      setState(() {
        _errorMessage = 'Failed to speak text: ${e.toString()}';
      });
    }
  }

  Future<void> _setOptimalVoice(String locale) async {
    try {
      final voices = await _flutterTts.getVoices;

      // Find voices that match the current locale
      final matchingVoices = voices.where((voice) {
        final voiceLocale = voice['locale'] as String?;
        return voiceLocale != null &&
            voiceLocale.startsWith(locale.substring(0, 2));
      }).toList();

      if (matchingVoices.isNotEmpty) {
        // Prefer female voices or high-quality voices for children
        final preferredVoice = matchingVoices.firstWhere(
          (voice) {
            final name = (voice['name'] as String? ?? '').toLowerCase();
            return name.contains('female') ||
                name.contains('woman') ||
                name.contains('child') ||
                name.contains('premium');
          },
          orElse: () => matchingVoices.first,
        );

        await _flutterTts.setVoice(preferredVoice);
        debugPrint('Set TTS voice: ${preferredVoice['name']}');
      }
    } catch (e) {
      debugPrint('Error setting TTS voice: $e');
      // Continue without setting specific voice
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_errorMessage != null && !_isInitialized) {
      return Positioned(
        bottom: 100,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return widget.child ?? const SizedBox();
    }

    // Listen to OpenAI response and trigger TTS
    ref.listen(openAIResponseControllerProvider, (previous, next) {
      next.when(
        data: (data) {
          if (data != null && data.isNotEmpty) {
            _speak(data);
          }
        },
        error: (error, stackTrace) {
          debugPrint('OpenAI response error: $error');
          _updateTalkingAnimation(false);
        },
        loading: () {
          // Don't do anything while loading
        },
      );
    });

    return widget.child ?? const SizedBox();
  }
}
