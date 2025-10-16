import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interacting_bear/features/providers/animation_state_controller.dart';

/// A button widget that toggles between English and Japanese languages.
/// Displays the appropriate flag for the current language selection.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(animationStateControllerProvider);
    final isEnglish = animationState.language == 'en';

    return Semantics(
      label: isEnglish
          ? 'Switch to Japanese language'
          : 'Switch to English language',
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _toggleLanguage(ref),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Flag.fromCode(
                isEnglish ? FlagsCode.US : FlagsCode.JP,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLanguage(WidgetRef ref) {
    ref.read(animationStateControllerProvider.notifier).toggleLanguage();
  }
}
