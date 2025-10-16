import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_tom/features/providers/animation_state_controller.dart';
import 'package:rive/rive.dart';

class BearAnimationScreen extends ConsumerStatefulWidget {
  const BearAnimationScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BearAnimationScreenState();
}

class _BearAnimationScreenState extends ConsumerState<BearAnimationScreen> {
  Artboard? riveArtboard;
  SMIBool? isHearing;
  SMIBool? talk;

  @override
  void initState() {
    print('animation screen init state');
    super.initState();

    rootBundle.load('assets/bear_character.riv').then(
      (data) async {
        try {
          final file = RiveFile.import(data);
          final artboard = file.mainArtboard;
          final controller =
              StateMachineController.fromArtboard(artboard, 'State Machine 1');
          if (controller != null) {
            artboard.addController(controller);
            isHearing = controller.findSMI('Hear');
            talk = controller.findSMI('Talk');
            setState(
              () {
                riveArtboard = artboard;
              },
            );
          }
        } catch (e) {
          print(e);
        }
      },
    );
  }

  void _toggleAnimation(AnimationState newValue) {
    print('toggle animation, is hearing: ${newValue.isHearing}');
    isHearing?.value = newValue.isHearing;
    talk?.value = newValue.isTalking;
  }

  bool get isHearingValue => isHearing?.value ?? false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final animState = ref.watch(animationStateControllerProvider);
    print('Built animation screen');
    _toggleAnimation(animState);
    return Center(
        child: riveArtboard == null
            ? const SizedBox()
            : Rive(
                artboard: riveArtboard!,
                alignment: Alignment.bottomCenter,
              ));
  }
}
