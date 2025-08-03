import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'animation_state_controller.g.dart';

class AnimationState {
  bool isHearing = false;
  bool isTalking = false;
  String language = 'en';

  AnimationState(
      {this.isHearing = false, this.isTalking = false, this.language = 'en'});
}

@riverpod
class AnimationStateController extends _$AnimationStateController {
  @override
  AnimationState build() {
    return AnimationState();
  }

  void updateHearing(bool isHearing) {
    state = AnimationState(isHearing: isHearing, language: state.language);
  }

  void updateTalking(bool isTalking) {
    state = AnimationState(isTalking: isTalking, language: state.language, isHearing: state.isHearing);
  }

  void toggleLanguage() {
    state = AnimationState(language: state.language == 'en' ? 'jp' : 'en');
  }
}
