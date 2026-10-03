import 'package:flutter/material.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// Shows a confirm/cancel dialog and returns true if the person
/// confirmed, false or null if they cancelled or dismissed it.
///
/// One shared function rather than a separate dialog per screen,
/// since close batch, logout, deactivate, and reactivate all follow
/// the exact same shape in every mockup: a title, an explanation of
/// what this action affects, and two buttons.
Future<bool?> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String body,
      String confirmLabel = 'Confirm',
      String cancelLabel = 'Cancel',
    }) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 13,
            color: AppColors.inkMuted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelLabel,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}