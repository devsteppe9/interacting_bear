import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_bear/utils/text_to_speech_api.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_cloud_repository.g.dart';

class GoogleCloudRepository {
  final TextToSpeechAPI ttsAPI;

  GoogleCloudRepository(this.ttsAPI);

  Future<List<Voice>> getVoices() {
    return ttsAPI.getVoices();
  }

  Future<ByteAudioSource> synthesizeText(String text, String lang) async {
    final audioBytes = await ttsAPI.synthesizeText(text, lang);
    return ByteAudioSource(audioBytes);
  }
}

class ByteAudioSource extends StreamAudioSource {
  final List<int> bytes;
  ByteAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}

@Riverpod(keepAlive: true)
GoogleCloudRepository googleCloudRepository(Ref ref) {
  return GoogleCloudRepository(TextToSpeechAPI());
}

@riverpod
Future<List<Voice>> voicesFuture(Ref ref) {
  final googleCloudRepository = ref.read(googleCloudRepositoryProvider);
  return googleCloudRepository.getVoices();
}

@riverpod
Future<ByteAudioSource> synthesizeTextFuture(
    Ref ref, String text, String lang) {
  final googleCloudRepository = ref.read(googleCloudRepositoryProvider);
  return googleCloudRepository.synthesizeText(text, lang);
}
