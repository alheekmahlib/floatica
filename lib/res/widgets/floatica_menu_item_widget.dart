import 'package:floatica/res/models/floatica_menu_item.dart';
import 'package:flutter/material.dart';

/// A widget that renders a single [FloaticaMenuItem] in the menu grid.
///
/// Displays a rounded-rectangle icon container with a title label below it.
/// Includes a tap scale animation for tactile feedback.
class FloaticaMenuItemWidget extends StatefulWidget {
  const FloaticaMenuItemWidget({
    super.key,
    required this.item,
    this.onTapDismiss,
  });

  /// The menu item data.
  final FloaticaMenuItem item;

  /// Optional callback to dismiss the menu after the item's [onTap] fires.
  final VoidCallback? onTapDismiss;

  @override
  State<FloaticaMenuItemWidget> createState() => _FloaticaMenuItemWidgetState();
}

class _FloaticaMenuItemWidgetState extends State<FloaticaMenuItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.item.onTap();
    widget.onTapDismiss?.call();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: widget.item.iconPadding ?? const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.item.backgroundColor ??
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.item.icon,
            ),
            const SizedBox(height: 6),
            Text(
              widget.item.title,
              style: widget.item.titleStyle ??
                  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
