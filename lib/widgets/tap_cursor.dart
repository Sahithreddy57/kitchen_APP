import 'package:flutter/material.dart';

/// Drop-in replacement for GestureDetector(onTap: ...) that shows the HAND
/// cursor (web / desktop / mouse) over clickable things.
///
/// - onTap given  -> hand cursor
/// - onTap == null (disabled) -> normal arrow, so greyed-out items don't
///   look clickable
/// Phones have no mouse cursor, so nothing changes there.
class TapCursor extends StatelessWidget {
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  final Widget? child;

  const TapCursor({super.key, this.onTap, this.behavior, this.child});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
    );
  }
}