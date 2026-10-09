import 'package:flutter/material.dart';

/// Animated campus mascot shown on the username step.
class OnboardingUsernameIllustration extends StatelessWidget {
  const OnboardingUsernameIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final width =
        (MediaQuery.sizeOf(context).width * 0.56)
            .clamp(196.0, 320.0)
            .toDouble();

    return Semantics(
      image: true,
      label: 'A friendly campus mascot using a laptop',
      child: SizedBox(
        width: width,
        height: width * 0.60,
        child: ClipRect(
          child: OverflowBox(
            alignment: const Alignment(0, -0.3),
            minWidth: width,
            maxWidth: width,
            minHeight: width,
            maxHeight: width,
            child: Image.asset(
              'assets/images/Research_New_Pin_Crop.gif',
              width: width,
              height: width,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
