import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_tom/features/providers/openai_response_controller.dart';
import 'package:interacting_tom/features/providers/animation_state_controller.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:collection/collection.dart';

class STTWidget extends ConsumerStatefulWidget {
  const STTWidget({super.key});

  @override
  ConsumerState<STTWidget> createState() => _STTWidgetState();
}

class _STTWidgetState extends ConsumerState<STTWidget>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  List<LocaleName> _localeNames = [];
  late AnimationController _idleAnimationController;
  late Animation<double> _idleAnimation;
  late AnimationController _listeningAnimationController;
  late Animation<double> _listeningAnimation;
  bool _isWaitingForResponse = false;
  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Idle animation (gentle movement when not active)
    _idleAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _idleAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _idleAnimationController,
      curve: Curves.easeInOut,
    ));
    _idleAnimationController.repeat(reverse: true);

    // Listening animation (pulsing when actively listening)
    _listeningAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _listeningAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _listeningAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _idleAnimationController.dispose();
    _listeningAnimationController.dispose();
    super.dispose();
  }

  void errorListener(SpeechRecognitionError error) {
    print(
        'Received error status: $error, listening: ${_speechToText.isListening}');
    ref.read(animationStateControllerProvider.notifier).updateHearing(false);
  }

  void statusListener(String status) {
    if (status == 'done') {
      ref.read(animationStateControllerProvider.notifier).updateHearing(false);
    }
    print(
        'Received listener status: $status, listening: ${_speechToText.isListening}');
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    await _speechToText.initialize(
        onError: errorListener, onStatus: statusListener);
    _localeNames = await _speechToText.locales();
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    if (_speechToText.isListening) {
      print('Already listening');
      return;
    }
    ref.read(animationStateControllerProvider.notifier).updateHearing(true);
    final localeId = _getCurrentLocale();
    await _speechToText.listen(onResult: _onSpeechResult, localeId: localeId);

    // Start listening animation
    _listeningAnimationController.repeat(reverse: true);

    setState(() {});
  }

  String _getCurrentLocale() {
    final String currentLang =
        ref.read(animationStateControllerProvider).language;

    final locale = _localeNames.firstWhereOrNull(
        (locale) => locale.localeId.contains(currentLang.toUpperCase()));
    if (locale == null || _localeNames.isEmpty) {
      return currentLang == 'en' ? 'en-US' : 'ja-JP';
    } else {
      return locale.localeId;
    }
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    ref.read(animationStateControllerProvider.notifier).updateHearing(false);

    // Stop listening animation
    _listeningAnimationController.stop();
    _listeningAnimationController.reset();

    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) async {
    if (result.finalResult) {
      _lastWords = result.recognizedWords;

      // Set waiting state and stop listening animation
      setState(() {
        _isWaitingForResponse = true;
      });
      _listeningAnimationController.stop();

      ref
          .read(openAIResponseControllerProvider.notifier)
          .getResponse(_lastWords);
      _stopListening();
      // setState(() {
      //   _lastWords = result.recognizedWords;

      //   print('Last words: $_lastWords');
      //   print('Confidence: ${result.confidence}');
      // });
    }
  }

  bool get _isListening => _speechToText.isListening;

  @override
  Widget build(BuildContext context) {
    print('Built STT widget');
    print("IS LISTENING: $_isListening");

    // Listen to OpenAI response to reset waiting state
    final asyncValue = ref.watch(openAIResponseControllerProvider);
    asyncValue.when(
      data: (data) {
        if (_isWaitingForResponse && data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _isWaitingForResponse = false);
          });
        }
      },
      error: (error, stackTrace) {
        if (_isWaitingForResponse) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _isWaitingForResponse = false);
          });
        }
      },
      loading: () {
        // Loading state is handled when we start the request
      },
    );

    final bool isIdle = !_isListening && !_isWaitingForResponse;
    final bool isDisabled = _isWaitingForResponse;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleAnimation, _listeningAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, isIdle ? _idleAnimation.value : 0),
          child: Transform.scale(
            scale: _isListening ? _listeningAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: isDisabled
                    ? null
                    : () {
                        print("IS LISTENING: $_isListening");
                        _isListening ? _stopListening() : _startListening();
                      },
                borderRadius: BorderRadius.circular(30),
                child: Semantics(
                  label: _getSemanticLabel(),
                  button: true,
                  enabled: !isDisabled,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconData(),
                        color: _getIconColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getDisplayText(),
                        style: TextStyle(
                          color: _getIconColor(),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconData() {
    if (_isWaitingForResponse) return Icons.hourglass_empty;
    return _isListening ? Icons.mic : Icons.mic_off;
  }

  Color _getIconColor() {
    if (_isWaitingForResponse) return Colors.orange;
    if (_isListening) return Colors.red;
    return Colors.grey[600]!;
  }

  String _getDisplayText() {
    if (_isWaitingForResponse) return 'THINKING...';
    if (_isListening) return 'LISTENING...';
    return 'TAP TO SPEAK';
  }

  String _getSemanticLabel() {
    if (_isWaitingForResponse) return 'Waiting for response, please wait';
    if (_isListening) return 'Currently listening, tap to stop';
    return 'Tap to start speaking';
  }
}
