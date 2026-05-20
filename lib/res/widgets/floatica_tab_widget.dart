import 'package:floatica/res/models/floatica_glass_effect.dart';
import 'package:floatica/res/models/floatica_tab.dart';
import 'package:floatica/res/utils/context_extension.dart';
import 'package:floatica/res/widgets/liquid_glass_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that represents a single tab in the floating navigation bar.
///
/// The [FloaticaTabWidget] displays an icon and a title, and visually indicates
/// whether it is selected. The widget supports animations for smooth transitions
/// between states.
class FloaticaTabWidget extends StatelessWidget {
  /// Creates a [FloaticaTabWidget].
  ///
  /// The [floaticaTab] parameter is required and provides the data for the tab,
  /// including its icon, title, and selection state.
  ///
  /// The [borderRadius] parameter defines the border radius of the tab's decoration.
  const FloaticaTabWidget({
    super.key,
    required this.floaticaTab,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    this.glassEffect,
  });

  /// The data model for the tab, containing its properties.
  final FloaticaTab floaticaTab;

  /// The border radius of the tab's decoration.
  final BorderRadius borderRadius;

  /// Glassmorphism effect from the parent FloatyNavBar.
  ///
  /// Individual tab's [glassEffect] takes precedence over this.
  final FloaticaGlassEffect? glassEffect;

  /// Gets the effective glass effect (tab-level overrides nav-bar level).
  FloaticaGlassEffect? get _effectiveGlassEffect {
    return floaticaTab.glassEffect ?? glassEffect;
  }

  /// Gets the current display mode based on selection state.
  FloaticaTabDisplayMode get _currentDisplayMode {
    return floaticaTab.isSelected
        ? floaticaTab.selectedDisplayMode
        : floaticaTab.unselectedDisplayMode;
  }

  /// Determines if the icon should be shown based on the current display mode.
  bool get _shouldShowIcon {
    switch (_currentDisplayMode) {
      case FloaticaTabDisplayMode.iconOnly:
      case FloaticaTabDisplayMode.iconAndTitle:
        return true;
      case FloaticaTabDisplayMode.titleOnly:
        return false;
    }
  }

  /// Determines if the title should be shown based on the current display mode.
  bool get _shouldShowTitle {
    switch (_currentDisplayMode) {
      case FloaticaTabDisplayMode.iconOnly:
        return false;
      case FloaticaTabDisplayMode.titleOnly:
      case FloaticaTabDisplayMode.iconAndTitle:
        return true;
    }
  }

  /// Determines the title opacity based on the current display mode.
  double get _titleOpacity {
    switch (_currentDisplayMode) {
      case FloaticaTabDisplayMode.iconOnly:
        return 0.0;
      case FloaticaTabDisplayMode.titleOnly:
      case FloaticaTabDisplayMode.iconAndTitle:
        return 1.0;
    }
  }

  /// Gets the animation duration (custom or default).
  Duration _getAnimationDuration(BuildContext context) {
    return floaticaTab.animationDuration ?? context.mediumDuration;
  }

  /// Gets the animation curve (custom or default).
  Curve _getAnimationCurve() {
    return floaticaTab.animationCurve ?? Curves.easeInOut;
  }

  /// Gets the current icon size based on selection state.
  double get _currentIconSize {
    return floaticaTab.isSelected
        ? floaticaTab.selectedIconSize
        : floaticaTab.iconSize;
  }

  /// Handles the tap with optional haptic feedback.
  void _handleTap() {
    if (floaticaTab.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    floaticaTab.onTap();
  }

  /// Builds the decoration based on indicator style and glass effect.
  Decoration? _buildDecoration(BuildContext context) {
    final isSelected = floaticaTab.isSelected;
    final indicatorStyle = floaticaTab.indicatorStyle;

    // For non-background indicator styles, use selected color only on selected tab
    if (indicatorStyle != FloaticaIndicatorStyle.background &&
        indicatorStyle != FloaticaIndicatorStyle.none) {
      return ShapeDecoration(
        color: isSelected
            ? (floaticaTab.selectedColor ?? context.primaryColor)
                .withValues(alpha: 0.15) // Subtle highlight for selected state
            : floaticaTab.unselectedColor ?? Colors.transparent,
        shape: _buildShapeBorder(context),
      );
    }

    // Glass effect takes precedence
    if (_effectiveGlassEffect != null) {
      return null; // Glass effect is handled separately with ClipRRect + BackdropFilter
    }

    // Gradient takes precedence over solid color
    final gradient = isSelected
        ? floaticaTab.selectedGradient
        : floaticaTab.unselectedGradient;

    if (gradient != null) {
      return ShapeDecoration(
        gradient: gradient,
        shape: _buildShapeBorder(context),
      );
    }

    // Default solid color
    return ShapeDecoration(
      color: isSelected
          ? floaticaTab.selectedColor ?? context.primaryColor
          : floaticaTab.unselectedColor ?? context.surfaceColor,
      shape: _buildShapeBorder(context),
    );
  }

  /// Builds the shape border with optional border styling.
  ShapeBorder _buildShapeBorder(BuildContext context) {
    if (floaticaTab.borderColor != null && floaticaTab.borderWidth != null) {
      final side = BorderSide(
        color: floaticaTab.borderColor!,
        width: floaticaTab.borderWidth!,
      );
      return RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: side,
      );
    }
    return RoundedRectangleBorder(borderRadius: borderRadius);
  }

  /// Builds the icon widget with badge support.
  Widget _buildIconWidget(BuildContext context) {
    final iconWidget = Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(
          size: _currentIconSize,
          color: floaticaTab.isSelected
              ? context.onPrimaryColor
              : context.onSurfaceColor,
        ),
      ),
      child: floaticaTab.icon,
    );

    // Add badge if provided
    if (floaticaTab.badge != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4,
            top: -4,
            child: floaticaTab.badge!,
          ),
        ],
      );
    }

    return iconWidget;
  }

  /// Builds the title widget.
  Widget _buildTitleWidget(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        floaticaTab.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: floaticaTab.titleStyle ??
            TextStyle(
              color: floaticaTab.isSelected
                  ? context.onPrimaryColor
                  : context.onSurfaceColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// Builds the indicator widget (dot or underline).
  Widget _buildIndicator(BuildContext context) {
    final indicatorColor = floaticaTab.indicatorColor ??
        floaticaTab.selectedColor ??
        context.primaryColor;

    switch (floaticaTab.indicatorStyle) {
      case FloaticaIndicatorStyle.dot:
        return AnimatedContainer(
          duration: _getAnimationDuration(context),
          curve: _getAnimationCurve(),
          margin: const EdgeInsets.only(top: 4),
          width: floaticaTab.isSelected ? 6 : 0,
          height: floaticaTab.isSelected ? 6 : 0,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        );
      case FloaticaIndicatorStyle.underline:
        return AnimatedContainer(
          duration: _getAnimationDuration(context),
          curve: _getAnimationCurve(),
          margin: const EdgeInsets.only(top: 4),
          width: floaticaTab.isSelected ? 20 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case FloaticaIndicatorStyle.background:
      case FloaticaIndicatorStyle.none:
        return const SizedBox.shrink();
    }
  }

  /// Builds the content layout based on label position.
  Widget _buildContent(BuildContext context) {
    final iconWidget = _shouldShowIcon
        ? AnimatedContainer(
            duration: _getAnimationDuration(context),
            curve: _getAnimationCurve(),
            child: _buildIconWidget(context),
          )
        : const SizedBox.shrink();

    final titleWidget = AnimatedOpacity(
      opacity: _titleOpacity,
      duration:
          _getAnimationDuration(context) + const Duration(milliseconds: 200),
      child: AnimatedSize(
        duration:
            _getAnimationDuration(context) + const Duration(milliseconds: 200),
        curve: _getAnimationCurve(),
        child: !_shouldShowTitle
            ? const SizedBox.shrink()
            : Padding(
                padding: floaticaTab.labelPosition ==
                        FloaticaLabelPosition.right
                    ? EdgeInsetsDirectional.only(start: _shouldShowIcon ? 6 : 0)
                    : const EdgeInsets.only(top: 4),
                child: _buildTitleWidget(context),
              ),
      ),
    );

    final indicator = _buildIndicator(context);

    if (floaticaTab.labelPosition == FloaticaLabelPosition.bottom) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget, // ← Fix: removed Expanded to avoid layout issues
          titleWidget,
          indicator,
        ],
      );
    }

    // Default: right position
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              titleWidget,
            ],
          ),
        ),
        indicator,
      ],
    );
  }

  /// Wraps the content with glassmorphism effect if configured.
  Widget _wrapWithGlassEffect(BuildContext context, Widget child) {
    if (_effectiveGlassEffect == null) return child;

    final glassEffect = _effectiveGlassEffect!;
    final isSelected = floaticaTab.isSelected;

    // When not selected, show transparent background (no glass effect)
    if (!isSelected) {
      return Container(
        decoration: BoxDecoration(
          color: floaticaTab.unselectedColor ?? Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: child,
      );
    }

    // When selected, apply Liquid Glass effect
    return LiquidGlassContainer(
      glassEffect: glassEffect,
      borderRadius: borderRadius,
      blurScale: 0.5,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build content once — reuse for both glass and non-glass paths
    final content = _buildContent(context);

    // Wrap content with FittedBox if width or height is specified
    final hasFixedSize =
        floaticaTab.width != null || floaticaTab.height != null;
    final wrappedContent = hasFixedSize
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: content,
          )
        : content;

    final tabPadding = EdgeInsets.symmetric(
      horizontal: floaticaTab.isSelected ? 14 : 18,
      vertical:
          floaticaTab.labelPosition == FloaticaLabelPosition.bottom ? 2 : 10,
    );

    // Apply glass effect if configured
    if (_effectiveGlassEffect != null) {
      Widget tabContent = _wrapWithGlassEffect(
        context,
        Container(
          width: floaticaTab.width,
          height: floaticaTab.height,
          padding: tabPadding,
          child: wrappedContent, // ← Fix: reuse same content, not built twice
        ),
      );

      if (floaticaTab.tooltip != null) {
        tabContent = Tooltip(
          message: floaticaTab.tooltip!,
          child: tabContent,
        );
      }

      return Padding(
        padding: floaticaTab.margin,
        child: CupertinoButton(
          onPressed: _handleTap,
          padding: EdgeInsets.zero,
          focusColor: floaticaTab.selectedColor ?? context.primaryColor,
          child: tabContent,
        ),
      );
    }

    // Default path: no glass effect
    Widget tabContent = AnimatedContainer(
      duration: _getAnimationDuration(context),
      curve: _getAnimationCurve(),
      width: floaticaTab.width,
      height: floaticaTab.height,
      padding: tabPadding,
      decoration: _buildDecoration(context),
      child: wrappedContent,
    );

    // Wrap with tooltip if provided
    if (floaticaTab.tooltip != null) {
      tabContent = Tooltip(
        message: floaticaTab.tooltip!,
        child: tabContent,
      );
    }

    return Padding(
      padding: floaticaTab.margin,
      child: CupertinoButton(
        onPressed: _handleTap,
        padding: EdgeInsets.zero,
        focusColor: floaticaTab.selectedColor ?? context.primaryColor,
        child: tabContent,
      ),
    );
  }
}
