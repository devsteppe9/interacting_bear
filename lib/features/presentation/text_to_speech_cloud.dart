import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_tom/features/data/google_cloud_repository.dart';
import 'package:interacting_tom/features/providers/animation_state_controller.dart';
import 'package:interacting_tom/features/providers/openai_response_controller.dart';
import 'package:just_audio/just_audio.dart';

class TextToSpeechCloud extends ConsumerStatefulWidget {
  const TextToSpeechCloud({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TextToSpeechState();
}

class _TextToSpeechState extends ConsumerState<TextToSpeechCloud> {
  String? language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Set up the player state listener
    player.playerStateStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        updateTalkingAnimation(false);
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void updateTalkingAnimation(bool isTalking) {
    ref
        .read(animationStateControllerProvider.notifier)
        .updateTalking(isTalking);
  }

  void _speakCloudTTS(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final String currentLang =
          ref.read(animationStateControllerProvider).language;

      final audioBytes = await ref
          .read(synthesizeTextFutureProvider(text, currentLang).future);
      await player.setAudioSource(audioBytes);
      updateTalkingAnimation(true);
      player.play();
    } catch (e) {
      print('Error in TTS: $e');
      updateTalkingAnimation(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Built text to speech');
    ref.listen(openAIResponseControllerProvider, (previous, next) {
      if (previous != next && next != null && next.toString().isNotEmpty) {
        _speakCloudTTS(next.toString());
        print('TTS STATE: $next');
      }
    });

    return widget.child ?? const SizedBox();
  }
}
