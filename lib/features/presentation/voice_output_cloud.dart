import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_bear/features/data/google_cloud_repository.dart';
import 'package:interacting_bear/features/providers/animation_state_controller.dart';
import 'package:interacting_bear/features/providers/openai_response_controller.dart';
import 'package:just_audio/just_audio.dart';

/// A widget that provides cloud-based text-to-speech functionality.
/// Uses Google Cloud Text-to-Speech API for high-quality voice synthesis.
class VoiceOutputCloud extends ConsumerStatefulWidget {
  const VoiceOutputCloud({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<VoiceOutputCloud> createState() => _VoiceOutputCloudState();
}

class _VoiceOutputCloudState extends ConsumerState<VoiceOutputCloud> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeAudioPlayer() {
    // Set up the player state listener
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (processingState == ProcessingState.completed ||
          processingState == ProcessingState.idle) {
        _updateTalkingAnimation(false);
      } else if (isPlaying && processingState == ProcessingState.ready) {
        _updateTalkingAnimation(true);
      }
    });

    // Listen for errors
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('Audio playback error: $e');
        _updateTalkingAnimation(false);
      },
    );

    setState(() {
      _isInitialized = true;
    });
  }

  void _updateTalkingAnimation(bool isTalking) {
    if (mounted) {
      ref
          .read(animationStateControllerProvider.notifier)
          .updateTalking(isTalking);
    }
  }

  Future<void> _speakCloudTTS(String text) async {
    if (text.trim().isEmpty) return;

    try {
      // Stop any current playback
      await _audioPlayer.stop();

      final String currentLang =
          ref.read(animationStateControllerProvider).language;

      // Get audio bytes from Google Cloud TTS
      final audioBytes = await ref.read(
        synthesizeTextFutureProvider(text, currentLang).future,
      );

      // Set the audio source and play
      await _audioPlayer.setAudioSource(audioBytes);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error in cloud TTS: $e');
      _updateTalkingAnimation(false);

      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play voice response: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.child ?? const SizedBox();
    }

    // Listen to OpenAI response and trigger TTS
    ref.listen(openAIResponseControllerProvider, (previous, next) {
      next.when(
        data: (data) {
          if (data != null && data.isNotEmpty) {
            _speakCloudTTS(data);
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
