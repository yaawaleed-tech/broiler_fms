import 'package:flutter/material.dart';

/// What a button shows inside itself: the label, and — while it is
/// working — a small spinner beside the label rather than instead of
/// it.
///
/// Every async button in the app uses this instead of swapping its
/// label for a bare spinner, so a screen never blinks from "Send login
/// code" to a lone circle and back: the button keeps reading as the
/// same button throughout.
///
/// The spinner takes the label's own colour, read from the enclosing
/// [DefaultTextStyle], so it is correct on a filled button (cream on
/// rust), on an outlined button (ink on cream) and on a text button
/// (rust on the page) without any colour being repeated at the call
/// site.
///
/// Pass [labelStyle] to style the label explicitly, exactly as the
/// button did before: whatever is passed renders identically, so a
/// button's idle appearance is untouched by using this.
class ButtonLoadingContent extends StatelessWidget {
  const ButtonLoadingContent({
    super.key,
    required this.label,
    required this.loading,
    this.labelStyle,
    this.semanticsLabel,
  });

  /// The button's text. Always visible, in every state.
  final String label;

  /// True while the button's work is in flight.
  final bool loading;

  /// The label's own style. Null means "whatever this button already
  /// uses", which is the theme's default for that button.
  final TextStyle? labelStyle;

  /// What a screen reader announces. Defaults to [label].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final style = labelStyle ?? DefaultTextStyle.of(context).style;
    final colour = style.color;
    final announced = semanticsLabel ?? label;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (loading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: colour),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: announced,
      // The label and spinner are already described by [announced], so
      // their own nodes are dropped rather than left to be read out a
      // second time. This Flutter SDK exposes no "busy" property on
      // Semantics, so the spinner is carried visually only; the node
      // stays a single button with a stable label either way.
      excludeSemantics: true,
      child: AnimatedSize(
        // The spinner fades in over the same 200 ms the content shifts
        // across; with reduced motion the content appears at once and
        // only the spinner still appears.
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.centerLeft,
        child: row,
      ),
    );
  }
}

/// A no-op press handler for a button that is already busy.
///
/// Keeps [onPressed] non-null so the button does not switch to the
/// greyed-out disabled style and dim the label that is meant to stay
/// readable — taps simply go nowhere, which is what stops a double
/// submit. Buttons whose work is also gated on something else (an empty
/// field, a closed batch) keep their own check and pass this only as
/// the busy half.
VoidCallback busyGuard(VoidCallback onPressed, bool loading) =>
    loading ? () {} : onPressed;
