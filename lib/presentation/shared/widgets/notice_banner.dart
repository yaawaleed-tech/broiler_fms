import 'package:flutter/material.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// A full-width informational banner: the AppBadge warning tone
/// (amberBg wash, amber border) scaled up to a message box, with body
/// text in ink for readability. Used for login-screen notices like the
/// forced-logout message — no new visual language, just the existing
/// warning palette at message size.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber, width: 1.5),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 13,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
