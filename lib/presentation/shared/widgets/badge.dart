import 'package:flutter/material.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// The three color schemes a status pill can use, matching the three
/// badge classes in every mockup (badge-olive, badge-amber, badge-ink).
enum BadgeTone { positive, warning, neutral }

/// A small colored status pill, e.g. "Active", "Pending", "Priced".
///
/// The caller decides the tone, this widget only knows how to paint
/// one of the three tones consistently. Keeping tone a plain enum,
/// rather than letting each screen pick its own color, is what keeps
/// every status pill in the app looking the same.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      BadgeTone.positive => (AppColors.oliveBg, AppColors.olive),
      BadgeTone.warning => (AppColors.amberBg, AppColors.amber),
      BadgeTone.neutral => (AppColors.hairline, AppColors.ink),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: foreground, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PublicSans',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: foreground,
        ),
      ),
    );
  }
}