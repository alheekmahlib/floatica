import 'package:flutter/material.dart';

/// A model class representing a single item in the [FloatyMenu] grid.
///
/// Each menu item displays an icon inside a rounded container with an
/// optional title below it.
class FloaticaMenuItem {
  /// Creates a [FloaticaMenuItem].
  const FloaticaMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.backgroundColor,
    this.titleStyle,
    this.iconPadding,
  });

  /// The widget displayed inside the menu item's container.
  ///
  /// Typically an [Icon], [Image], or [SvgPicture].
  final Widget icon;

  /// The label displayed below the icon container.
  final String title;

  /// The callback invoked when this menu item is tapped.
  final VoidCallback onTap;

  /// The background color of the icon container.
  ///
  /// If not provided, defaults to a light grey.
  final Color? backgroundColor;

  /// Custom text style for the title label.
  final TextStyle? titleStyle;

  /// Padding around the icon inside its container.
  ///
  /// Defaults to `EdgeInsets.all(12)` if not provided.
  final EdgeInsets? iconPadding;
}
