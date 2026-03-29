import 'dart:ui';

import 'package:floaty_nav_bar/res/models/floaty_action_button.dart';
import 'package:floaty_nav_bar/res/models/floaty_glass_effect.dart';
import 'package:floaty_nav_bar/res/models/floaty_menu.dart';
import 'package:floaty_nav_bar/res/models/floaty_menu_controller.dart';
import 'package:floaty_nav_bar/res/models/floaty_shape.dart';
import 'package:floaty_nav_bar/res/models/floaty_tab.dart';
import 'package:floaty_nav_bar/res/utils/context_extension.dart';
import 'package:floaty_nav_bar/res/widgets/floaty_tab_widget.dart';
import 'package:floaty_nav_bar/res/widgets/gap_box.dart';
import 'package:floaty_nav_bar/res/widgets/liquid_glass_container.dart';
import 'package:flutter/material.dart';

/// A customizable floating navigation bar that displays tabs and an action button.
///
/// The [FloatyNavBar] widget allows users to navigate between tabs while providing
/// an action button that can perform a specific action related to the selected tab.
/// It supports custom shapes, styles, and animations.
class FloatyNavBar extends StatefulWidget {
  /// Creates a [FloatyNavBar].
  ///
  /// The [tabs] parameter is required and provides the list of tabs to display in
  /// the navigation bar. The [selectedTab] parameter specifies the index of the
  /// currently selected tab.
  ///
  /// The following parameters are optional:
  /// - [margin]: The margin around the navigation bar.
  /// - [height]: The height of the navigation bar. Defaults to 60.
  /// - [gap]: The gap between the tab bar and the action button. Defaults to 16.
  /// - [backgroundColor]: The background color of the navigation bar.
  /// - [boxShadow]: The shadow effect applied to the navigation bar.
  /// - [shape]: The shape of the navigation bar. Defaults to [CircleShape].
  const FloatyNavBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    this.margin = const EdgeInsetsDirectional.symmetric(vertical: 16),
    this.height = 60,
    this.gap = 16,
    this.backgroundColor,
    this.boxShadow,
    this.shape = const CircleShape(),
    this.glassEffect,
    this.menu,
  });

  /// The list of tabs to be displayed in the navigation bar.
  final List<FloatyTab> tabs;

  /// The index of the currently selected tab.
  final int selectedTab;

  /// The height of the navigation bar.
  final double height;

  /// The gap between the tab bar and the action button.
  final double gap;

  /// The margin around the navigation bar.
  final EdgeInsetsGeometry? margin;

  /// The background color of the navigation bar.
  final Color? backgroundColor;

  /// The shadow effect applied to the navigation bar.
  final List<BoxShadow>? boxShadow;

  /// The shape of the navigation bar.
  ///
  /// The default shape is [CircleShape].
  ///
  /// Subclasses include:
  /// - [CircleShape]: A circular shape with rounded corners.
  /// - [RectangleShape]: A rectangular shape with customizable corner radius.
  /// - [SquircleShape]: A squircle shape with a continuous curve for the border.
  ///
  /// You can create custom shapes by extending the [FloatyShape] class.
  final FloatyShape shape;

  /// Glassmorphism effect configuration applied to all tabs.
  ///
  /// If provided, applies a glass-like blur effect to all tab backgrounds.
  /// Individual tabs can override this with their own [glassEffect] property.
  final FloatyGlassEffect? glassEffect;

  /// An optional expandable menu that renders as a tab in the navigation bar.
  ///
  /// When tapped, it opens an animated popup overlay containing a grid of
  /// [FloatyMenuItem]s. The menu auto-closes on tab change, outside tap,
  /// or item tap.
  final FloatyMenu? menu;

  @override
  State<FloatyNavBar> createState() => _FloatyNavBarState();
}

class _FloatyNavBarState extends State<FloatyNavBar>
    with SingleTickerProviderStateMixin {
  late FloatyActionButton? _floatyStyle;

  // Menu state
  bool _isMenuOpen = false;
  AnimationController? _menuController;
  final GlobalKey _navBarKey = GlobalKey();
  final GlobalKey _menuContentKey = GlobalKey();
  OverlayEntry? _barrierOverlay;
  double _measuredMenuHeight = 0;

  @override
  void initState() {
    super.initState();
    _floatyStyle = widget.tabs[widget.selectedTab].floatyActionButton;
    _initMenuController();
    _attachMenuController();
  }

  void _initMenuController() {
    if (widget.menu != null) {
      _menuController = AnimationController(
        vsync: this,
        duration:
            widget.menu!.animationDuration ?? const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _detachMenuController();
    _removeBarrierOverlay();
    _menuController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FloatyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      setState(() {
        _floatyStyle = widget.tabs[widget.selectedTab].floatyActionButton;
      });
      if (_isMenuOpen) {
        _closeMenu();
      }
    }
    if (widget.menu != null && _menuController == null) {
      _initMenuController();
    } else if (widget.menu == null && _menuController != null) {
      _removeBarrierOverlay();
      _menuController?.reset();
      _menuController?.dispose();
      _menuController = null;
      if (_isMenuOpen) setState(() => _isMenuOpen = false);
    }
    // Re-attach controller if it changed
    if (oldWidget.menu?.controller != widget.menu?.controller) {
      _detachMenuController(oldWidget.menu?.controller);
      _attachMenuController();
    }
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _attachMenuController([FloatyMenuController? controller]) {
    final ctrl = controller ?? widget.menu?.controller;
    ctrl?.addListener(_onMenuControllerAction);
  }

  void _detachMenuController([FloatyMenuController? controller]) {
    final ctrl = controller ?? widget.menu?.controller;
    ctrl?.removeListener(_onMenuControllerAction);
  }

  void _onMenuControllerAction() {
    final ctrl = widget.menu?.controller;
    if (ctrl == null) return;
    final action = ctrl.consumeAction();
    if (action == null) return;
    switch (action) {
      case FloatyMenuAction.open:
        _openMenu();
      case FloatyMenuAction.close:
        _closeMenu();
      case FloatyMenuAction.toggle:
        _toggleMenu();
    }
  }

  void _openMenu() {
    if (_menuController == null || widget.menu == null || _isMenuOpen) return;
    _menuController!.forward();
    setState(() => _isMenuOpen = true);
    widget.menu!.controller?.updateIsOpen(true);
    widget.menu!.onMenuToggle?.call(true);
    // Insert barrier after layout so _menuContentKey is measured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureMenuHeight();
      _insertBarrierOverlay();
    });
  }

  void _closeMenu() {
    if (_menuController == null || !_isMenuOpen) return;
    widget.menu!.controller?.updateIsOpen(false);
    widget.menu!.onMenuToggle?.call(false);
    _menuController!.reverse().then((_) {
      _removeBarrierOverlay();
      if (mounted) setState(() => _isMenuOpen = false);
    });
  }

  void _insertBarrierOverlay() {
    final menu = widget.menu;
    if (menu == null) return;

    final renderBox =
        _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final navBarTop = renderBox.localToGlobal(Offset.zero).dy;

    // Transparent overlay just for tap-to-dismiss (no blur/color)
    _barrierOverlay = OverlayEntry(
      builder: (context) => _DismissOverlayWidget(
        animation: _menuController!,
        curve: menu.animationCurve ?? Curves.easeOutCubic,
        navBarTop: navBarTop,
        menuHeight: _measuredMenuHeight,
        onTap: _closeMenu,
      ),
    );

    Overlay.of(context).insert(_barrierOverlay!);
  }

  void _measureMenuHeight() {
    final renderBox =
        _menuContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      _measuredMenuHeight = renderBox.size.height;
    }
  }

  void _removeBarrierOverlay() {
    _barrierOverlay?.remove();
    _barrierOverlay?.dispose();
    _barrierOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final navRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _buildNavBarContainer(context),
          ),
        ),
        AnimatedSize(
          duration: context.fastDuration,
          child:
              _floatyStyle == null ? const GapBox() : GapBox(gap: widget.gap),
        ),
        AnimatedSize(
          duration: context.mediumDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          child: SizedBox(
            height: _floatyStyle?.size ?? 0,
            width: _floatyStyle?.size ?? 0,
            child: _buildFloatingActionButton(context),
          ),
        ),
      ],
    );

    Widget result = SafeArea(
      key: _navBarKey,
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: navRow,
      ),
    );

    // Wrap with a visual barrier that paints BEHIND the nav bar (not on top).
    // Uses Stack overflow to extend the blur upward over the body content.
    final menu = widget.menu;
    final showBarrier = menu != null &&
        _menuController != null &&
        (_isMenuOpen || _menuController!.isAnimating) &&
        (menu.barrierBlur > 0 || menu.barrierColor != Colors.transparent);

    if (showBarrier) {
      final screenHeight = MediaQuery.of(context).size.height;
      result = Stack(
        clipBehavior: Clip.none,
        children: [
          // Barrier: first child paints first → behind the nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: screenHeight,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _menuController!,
                builder: (context, child) {
                  final curve = menu.animationCurve ?? Curves.easeOutCubic;
                  final value = curve.transform(_menuController!.value);
                  if (value == 0) return const SizedBox.shrink();

                  Widget barrier = ColoredBox(
                    color: menu.barrierColor.withValues(
                      alpha: menu.barrierColor.a * value,
                    ),
                  );

                  if (menu.barrierBlur > 0) {
                    final sigma = menu.barrierBlur * value;
                    barrier = BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                      child: barrier,
                    );
                  }

                  return ClipRect(child: barrier);
                },
              ),
            ),
          ),
          // Nav bar: second child paints on top → NOT blurred
          result,
        ],
      );
    }

    return result;
  }

  /// Builds the FloatingActionButton with optional glass effect.
  Widget _buildFloatingActionButton(BuildContext context) {
    if (_floatyStyle == null) return const SizedBox.shrink();

    final fabContent = AnimatedSwitcher(
      duration: context.mediumDuration,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _floatyStyle?.icon != null
          ? KeyedSubtree(
              key: ValueKey(_floatyStyle!.icon.hashCode),
              child: _floatyStyle!.icon,
            )
          : const SizedBox.shrink(),
    );

    // Apply glass effect if configured
    if (widget.glassEffect != null) {
      final glassEffect = widget.glassEffect!;
      final borderRadius = widget.shape.borderRadius;

      return GestureDetector(
        onTap: _floatyStyle?.onTap,
        child: LiquidGlassContainer(
          glassEffect: glassEffect,
          borderRadius: borderRadius,
          blurScale: 0.5,
          child: SizedBox(
            width: _floatyStyle?.size ?? 56,
            height: _floatyStyle?.size ?? 56,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color:
                      _floatyStyle?.foregroundColor ?? context.onPrimaryColor,
                ),
                child: fabContent,
              ),
            ),
          ),
        ),
      );
    }

    // Default FloatingActionButton without glass effect
    return FloatingActionButton(
      shape: widget.shape.shapeBorder,
      backgroundColor: _floatyStyle?.backgroundColor ?? context.primaryColor,
      foregroundColor: _floatyStyle?.foregroundColor ?? context.onPrimaryColor,
      onPressed: _floatyStyle?.onTap,
      heroTag: _floatyStyle?.heroTag,
      autofocus: _floatyStyle?.autofocus ?? false,
      clipBehavior: _floatyStyle?.clipBehavior ?? Clip.none,
      enableFeedback: _floatyStyle?.enableFeedback ?? true,
      focusColor: _floatyStyle?.focusColor ?? context.primaryColor,
      hoverColor: _floatyStyle?.hoverColor ?? context.primaryColor,
      splashColor: _floatyStyle?.splashColor ?? context.primaryColor,
      tooltip: _floatyStyle?.tooltip,
      mini: _floatyStyle?.mini ?? false,
      focusNode: _floatyStyle?.focusNode,
      isExtended: _floatyStyle?.isExtended ?? false,
      key: ValueKey(_floatyStyle?.icon.hashCode),
      materialTapTargetSize: _floatyStyle?.materialTapTargetSize,
      mouseCursor: _floatyStyle?.mouseCursor,
      child: fabContent,
    );
  }

  /// Builds the navigation bar container with optional glass effect.
  ///
  /// When a [FloatyMenu] is configured, the container expands upward to
  /// reveal the menu grid above the tabs row using a [SizeTransition].
  Widget _buildNavBarContainer(BuildContext context) {
    final tabWidgets = widget.tabs.map((tab) {
      // When menu is open, deselect all regular tabs
      final effectiveTab = _isMenuOpen
          ? FloatyTab(
              isSelected: false,
              title: tab.title,
              onTap: tab.onTap,
              icon: tab.icon,
              titleStyle: tab.titleStyle,
              floatyActionButton: tab.floatyActionButton,
              margin: tab.margin,
              selectedColor: tab.selectedColor,
              unselectedColor: tab.unselectedColor,
              selectedDisplayMode: tab.selectedDisplayMode,
              unselectedDisplayMode: tab.unselectedDisplayMode,
              selectedGradient: tab.selectedGradient,
              unselectedGradient: tab.unselectedGradient,
              badge: tab.badge,
              iconSize: tab.iconSize,
              selectedIconSize: tab.selectedIconSize,
              labelPosition: tab.labelPosition,
              indicatorStyle: tab.indicatorStyle,
              indicatorColor: tab.indicatorColor,
              borderColor: tab.borderColor,
              borderWidth: tab.borderWidth,
              animationDuration: tab.animationDuration,
              animationCurve: tab.animationCurve,
              enableHaptics: tab.enableHaptics,
              tooltip: tab.tooltip,
              glassEffect: tab.glassEffect,
              width: tab.width,
              height: tab.height,
            )
          : tab;
      return FloatyTabWidget(
        floatyTab: effectiveTab,
        shape: widget.shape,
        glassEffect: widget.glassEffect,
      );
    }).toList();

    // Add menu tab if configured
    if (widget.menu != null) {
      final menu = widget.menu!;
      final menuTab = FloatyTab(
        isSelected: _isMenuOpen,
        title: menu.title,
        titleStyle: menu.titleStyle,
        onTap: _toggleMenu,
        icon: menu.icon,
        selectedColor: menu.selectedColor,
        unselectedColor: menu.unselectedColor,
        selectedDisplayMode: menu.selectedDisplayMode,
        unselectedDisplayMode: menu.unselectedDisplayMode,
        iconSize: menu.iconSize,
        selectedIconSize: menu.selectedIconSize,
        labelPosition: menu.labelPosition,
      );
      tabWidgets.add(
        FloatyTabWidget(
          floatyTab: menuTab,
          shape: widget.shape,
          glassEffect: widget.glassEffect,
        ),
      );
    }

    final tabsRow = SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: tabWidgets,
      ),
    );

    // Build the content Column: menu grid (animated) + tabs row
    final hasMenu = widget.menu != null && _menuController != null;
    final animCurve = widget.menu?.animationCurve ?? Curves.easeOutCubic;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasMenu)
          SizeTransition(
            sizeFactor: CurvedAnimation(
              parent: _menuController!,
              curve: animCurve,
              reverseCurve: animCurve.flipped,
            ),
            axisAlignment: 1.0, // Expand upward, bottom stays fixed
            child: KeyedSubtree(
              key: _menuContentKey,
              child: widget.menu!.height != null
                  ? SizedBox(
                      height: widget.menu!.height,
                      child: widget.menu!.child,
                    )
                  : widget.menu!.child,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: tabsRow,
        ),
      ],
    );

    // Apply glass effect if configured
    if (widget.glassEffect != null) {
      final glassEffect = widget.glassEffect!;
      final borderRadius =
          widget.menu?.borderRadius ?? widget.shape.borderRadius;

      return LiquidGlassContainer(
        glassEffect: glassEffect,
        borderRadius: borderRadius,
        child: content,
      );
    }

    // Default container without glass effect
    final borderRadius = widget.menu?.borderRadius ?? widget.shape.borderRadius;
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? context.surfaceColor,
        borderRadius: borderRadius,
        boxShadow: widget.boxShadow ?? [context.boxShadow],
      ),
      child: content,
    );
  }
}

/// Transparent full-screen overlay for tap-to-dismiss.
///
/// Contains no blur or color — visual effects are handled by the [Stack]
/// overflow barrier inside [_FloatyNavBarState.build].
/// Tapping anywhere outside the nav bar closes the menu.
class _DismissOverlayWidget extends StatelessWidget {
  const _DismissOverlayWidget({
    required this.animation,
    required this.curve,
    required this.navBarTop,
    required this.menuHeight,
    required this.onTap,
  });

  final Animation<double> animation;
  final Curve curve;
  final double navBarTop;
  final double menuHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = curve.transform(animation.value);
        if (value == 0) return const SizedBox.shrink();

        // Full-screen dismiss area above the expanded nav bar
        final expandedNavBarTop = navBarTop - (menuHeight * value);

        return Stack(
          children: [
            // Area above the nav bar (including expanded menu)
            if (expandedNavBarTop > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: expandedNavBarTop,
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            // Area beside/below the nav bar (left, right, below)
            Positioned(
              top: expandedNavBarTop > 0 ? expandedNavBarTop : 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.translucent,
              ),
            ),
          ],
        );
      },
    );
  }
}
