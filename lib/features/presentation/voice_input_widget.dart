import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_bear/features/providers/openai_response_controller.dart';
import 'package:interacting_bear/features/providers/animation_state_controller.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:collection/collection.dart';
import 'package:permission_handler/permission_handler.dart';

/// A widget that handles voice input from the user.
/// Provides speech-to-text functionality with proper permission handling,
/// visual feedback, and error states.
class VoiceInputWidget extends ConsumerStatefulWidget {
  const VoiceInputWidget({super.key});

  @override
  ConsumerState<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends ConsumerState<VoiceInputWidget>
    with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWords = '';
  List<LocaleName> _localeNames = [];

  // Animation controllers
  late AnimationController _idleAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _idleAnimation;
  late Animation<double> _pulseAnimation;

  // State variables
  bool _isWaitingForResponse = false;
  bool _hasPermission = true;
  Timer? _responseTimeout;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
    _checkInitialPermissionStatus();
  }

  void _initializeAnimations() {
    // Idle animation (gentle movement when not active)
    _idleAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _idleAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _idleAnimationController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation for listening state
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _idleAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleAnimationController.dispose();
    _pulseAnimationController.dispose();
    _responseTimeout?.cancel();
    super.dispose();
  }

  /// Check initial permission status without requesting
  Future<void> _checkInitialPermissionStatus() async {
    final status = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  void _speechErrorListener(SpeechRecognitionError error) {
    debugPrint('Speech recognition error: $error');
    ref.read(animationStateControllerProvider.notifier).updateHearing(false);
    _stopListeningAnimations();

    if (mounted) {
      setState(() {
        _errorMessage = 'Speech recognition failed. Please try again.';
      });
    }
  }

  void _speechStatusListener(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done') {
      ref.read(animationStateControllerProvider.notifier).updateHearing(false);
      _stopListeningAnimations();
    }
  }

  /// Initialize speech recognition
  Future<void> _initializeSpeech() async {
    try {
      final isAvailable = await _speechToText.initialize(
        onError: _speechErrorListener,
        onStatus: _speechStatusListener,
      );

      if (isAvailable) {
        _localeNames = await _speechToText.locales();
      } else {
        setState(() {
          _errorMessage = 'Speech recognition not available on this device.';
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      setState(() {
        _errorMessage = 'Failed to initialize speech recognition.';
      });
    }
  }

  /// Check and request microphone permission
  Future<bool> _checkMicrophonePermission() async {
    var status = await Permission.microphone.status;

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Microphone permission is required to use voice input.';
      });
      await _showPermissionDialog();
      return false;
    }

    final granted = status.isGranted;
    setState(() {
      _hasPermission = granted;
      if (!granted) {
        _errorMessage = 'Microphone permission denied.';
      } else {
        _errorMessage = null;
      }
    });

    return granted;
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: const Text(
            'This app needs microphone access to listen to your voice. '
            'Please enable microphone permission in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Start listening for speech input
  Future<void> _startListening() async {
    if (_speechToText.isListening || _isWaitingForResponse) {
      return;
    }

    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    // Check microphone permission
    final hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) return;

    try {
      ref.read(animationStateControllerProvider.notifier).updateHearing(true);
      _startListeningAnimations();

      final localeId = _getCurrentLocale();
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: localeId,
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() {
        _errorMessage = 'Failed to start listening. Please try again.';
      });
      _stopListeningAnimations();
    }
  }

  String _getCurrentLocale() {
    final currentLang = ref.read(animationStateControllerProvider).language;
    final locale = _localeNames.firstWhereOrNull(
      (locale) => locale.localeId.toLowerCase().contains(currentLang),
    );

    return locale?.localeId ?? (currentLang == 'en' ? 'en-US' : 'ja-JP');
  }

  /// Stop listening and start waiting for AI response
  Future<void> _stopListening() async {
    await _speechToText.stop();
    ref.read(animationStateControllerProvider.notifier).updateHearing(false);
    _stopListeningAnimations();
    _startWaitingForResponse();
  }

  void _startListeningAnimations() {
    _idleAnimationController.stop();
    _pulseAnimationController.repeat(reverse: true);
  }

  void _stopListeningAnimations() {
    _pulseAnimationController.stop();
    _idleAnimationController.repeat(reverse: true);
  }

  void _startWaitingForResponse() {
    setState(() {
      _isWaitingForResponse = true;
    });

    // Start timeout timer (30 seconds)
    _responseTimeout?.cancel();
    _responseTimeout = Timer(const Duration(seconds: 30), () {
      debugPrint('OpenAI response timeout');
      _stopWaitingForResponse();
      setState(() {
        _errorMessage = 'Response timeout. Please try again.';
      });
    });
  }

  void _stopWaitingForResponse() {
    _responseTimeout?.cancel();
    if (mounted && _isWaitingForResponse) {
      setState(() {
        _isWaitingForResponse = false;
      });
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _lastWords = result.recognizedWords;
      _stopListening();

      // Send to AI
      ref
          .read(openAIResponseControllerProvider.notifier)
          .getResponse(_lastWords);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to OpenAI response to stop waiting when response received
    ref.listen(openAIResponseControllerProvider, (previous, next) {
      if (_isWaitingForResponse) {
        next.when(
          data: (data) {
            if (data != null && data.isNotEmpty) {
              _stopWaitingForResponse();
            }
          },
          error: (error, stackTrace) {
            _stopWaitingForResponse();
            setState(() {
              _errorMessage = 'Failed to get response. Please try again.';
            });
          },
          loading: () {}, // Keep waiting during loading
        );
      }
    });

    final isListening = _speechToText.isListening;
    final isIdle = !isListening && !_isWaitingForResponse;
    final isDisabled = _isWaitingForResponse || !_hasPermission;

    return AnimatedBuilder(
      animation: Listenable.merge([_idleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, isIdle ? _idleAnimation.value : 0),
          child: Transform.scale(
            scale: isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: isDisabled ? null : _handleTap,
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayText(),
                            style: TextStyle(
                              color: _getTextColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
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

  void _handleTap() {
    if (_speechToText.isListening) {
      _stopListening();
    } else if (!_hasPermission) {
      _checkMicrophonePermission();
    } else {
      _startListening();
    }
  }

  Color _getBorderColor() {
    if (_errorMessage != null) return Colors.red;
    if (_isWaitingForResponse) return Colors.orange;
    if (_speechToText.isListening) return Colors.red;
    return Colors.grey.shade300;
  }

  IconData _getIconData() {
    if (_isWaitingForResponse) return Icons.hourglass_empty;
    if (!_hasPermission || _errorMessage != null) return Icons.warning;
    return _speechToText.isListening ? Icons.mic : Icons.mic_off;
  }

  Color _getIconColor() {
    if (_errorMessage != null) return Colors.red;
    if (_isWaitingForResponse) return Colors.orange;
    if (!_hasPermission) return Colors.red;
    if (_speechToText.isListening) return Colors.red;
    return Colors.grey[600]!;
  }

  Color _getTextColor() {
    if (_errorMessage != null) return Colors.red;
    if (_isWaitingForResponse) return Colors.orange;
    if (!_hasPermission) return Colors.red;
    if (_speechToText.isListening) return Colors.red;
    return Colors.grey[700]!;
  }

  String _getDisplayText() {
    if (_isWaitingForResponse) return 'THINKING...';
    if (_speechToText.isListening) return 'LISTENING...';
    if (!_hasPermission) return 'NEED PERMISSION';
    return 'TAP TO SPEAK';
  }

  String _getSemanticLabel() {
    if (_isWaitingForResponse) return 'Waiting for response, please wait';
    if (_speechToText.isListening) return 'Currently listening, tap to stop';
    if (!_hasPermission)
      return 'Microphone permission required, tap to grant permission';
    return 'Tap to start speaking';
  }
}
