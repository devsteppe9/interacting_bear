import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:interacting_tom/features/providers/animation_state_controller.dart';
import 'package:interacting_tom/features/providers/openai_response_controller.dart';
import 'package:just_audio/just_audio.dart';

class TextToSpeechLocal extends ConsumerStatefulWidget {
  const TextToSpeechLocal({super.key, this.child});
  final Widget? child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TextToSpeechState();
}

enum TtsState { playing, stopped, paused, continued }

class _TextToSpeechState extends ConsumerState<TextToSpeechLocal> {
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  TtsState ttsState = TtsState.stopped;
  final player = AudioPlayer();

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<dynamic> _getLanguages() async => await flutterTts.getLanguages;

  Future<dynamic> _getEngines() async => await flutterTts.getEngines;

  Future<dynamic> _getVoices() async => await flutterTts.getVoices;

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    _getEngines().then((value) => print("engines: $value"));
    _getLanguages().then((value) => print("languages: $value"));
    _getVoices().then((values) => print("voices: ${values}"));

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    // flutterTts.setStartHandler(() {
    //   setState(() {
    //     print("Playing");
    //     ttsState = TtsState.playing;
    //   });
    // });

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          print("TTS Initialized");
        });
      });
    }

    flutterTts.setCompletionHandler(() {
      print("Complete");
      updateTalkingAnimation(false);
      // setState(() {
      //
      //   ttsState = TtsState.stopped;
      // });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        updateTalkingAnimation(false);
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      updateTalkingAnimation(false);
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      updateTalkingAnimation(false);
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      updateTalkingAnimation(false);
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  void updateTalkingAnimation(bool isTalking) {
    ref
        .read(animationStateControllerProvider.notifier)
        .updateTalking(isTalking);
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future _speak(String textToSpeak) async {
    final String currentLang =
        ref.read(animationStateControllerProvider).language;

    final mapCurLang = currentLang == 'en' ? 'en-US' : 'ja-JP';

    // _getLanguages().then((value) => print("languages: $value"));
    // _getVoices().then((values) => print("voices: ${values}"));

    final languages = await flutterTts.getLanguages;
    final voices = await flutterTts.getVoices;
    final curVoice =
        voices.firstWhere((i) => i['locale'].contains(mapCurLang) as bool);

    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.setLanguage(mapCurLang);
    // await flutterTts.setVoice(curVoice);

    if (textToSpeak.isNotEmpty) {
      updateTalkingAnimation(true);
      await flutterTts.speak(textToSpeak);
    }
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Widget build(BuildContext context) {
    print('Built text to speech');
    ref.listen(openAIResponseControllerProvider, (previous, next) {
      if (previous != next) {
        _speak((next as String?) ?? '');
        print('STATE: $next');
      }
    });

    return widget.child ?? const SizedBox();
  }
}
