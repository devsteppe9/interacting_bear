import 'package:interacting_tom/features/data/openai_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'openai_response_controller.g.dart';

@riverpod
class OpenAIResponseController extends _$OpenAIResponseController {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  void getResponse(String prompt) async {
    final openAIRepository = ref.read(openAIRepostitoryProvider);

    // Set loading state
    state = const AsyncValue.loading();

    final responseValue = await AsyncValue.guard(() async {
      return openAIRepository.fetchAnswer(prompt);
    });

    state = responseValue;
  }
}
