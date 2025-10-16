import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_bear/features/providers/animation_state_controller.dart';
import 'package:rive/rive.dart';

/// A widget that displays and controls the bear character animation.
/// This widget handles loading the Rive animation file and responds to
/// state changes for hearing and talking animations.
class BearAnimationWidget extends ConsumerStatefulWidget {
  const BearAnimationWidget({super.key});

  @override
  ConsumerState<BearAnimationWidget> createState() =>
      _BearAnimationWidgetState();
}

class _BearAnimationWidgetState extends ConsumerState<BearAnimationWidget> {
  Artboard? _riveArtboard;
  SMIBool? _isHearing;
  SMIBool? _talk;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRiveAnimation();
  }

  @override
  void dispose() {
    // Animation resources are automatically cleaned up by Rive
    super.dispose();
  }

  Future<void> _loadRiveAnimation() async {
    try {
      final data = await rootBundle.load('assets/bear_character.riv');
      final file = RiveFile.import(data);
      final artboard = file.mainArtboard;
      final controller =
          StateMachineController.fromArtboard(artboard, 'State Machine 1');

      if (controller != null) {
        artboard.addController(controller);
        _isHearing = controller.findSMI('Hear');
        _talk = controller.findSMI('Talk');

        if (mounted) {
          setState(() {
            _riveArtboard = artboard;
            _isInitialized = true;
          });
        }
      } else {
        throw Exception('State Machine Controller not found');
      }
    } catch (e) {
      debugPrint('Error loading Rive animation: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load bear animation';
        });
      }
    }
  }

  void _updateAnimation(AnimationState animationState) {
    if (!_isInitialized) return;

    _isHearing?.value = animationState.isHearing;
    _talk?.value = animationState.isTalking;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final animationState = ref.watch(animationStateControllerProvider);
    _updateAnimation(animationState);

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isInitialized = false;
                });
                _loadRiveAnimation();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Loading state
    if (!_isInitialized || _riveArtboard == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading bear animation...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Animation loaded and ready
    return Center(
      child: Rive(
        artboard: _riveArtboard!,
        alignment: Alignment.bottomCenter,
        fit: BoxFit.contain,
      ),
    );
  }
}
