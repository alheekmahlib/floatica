import 'dart:ui';

import 'package:floatica/res/models/floatica_action_button.dart';
import 'package:floatica/res/models/floatica_glass_effect.dart';
import 'package:floatica/res/models/floatica_menu.dart';
import 'package:floatica/res/models/floatica_menu_controller.dart';
import 'package:floatica/res/models/floatica_tab.dart';
import 'package:floatica/res/utils/context_extension.dart';
import 'package:floatica/res/widgets/floatica_tab_widget.dart';
import 'package:floatica/res/widgets/gap_box.dart';
import 'package:floatica/res/widgets/liquid_glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  /// - [borderRadius]: The border radius of the navigation bar.
  const FloatyNavBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    this.margin = const EdgeInsetsDirectional.symmetric(vertical: 16),
    this.height = 60,
    this.gap = 16,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius = const BorderRadius.all(Radius.circular(100)),
    this.glassEffect,
    this.menu,
  });

  /// The list of tabs to be displayed in the navigation bar.
  final List<FloaticaTab> tabs;

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

  /// The border radius of the navigation bar.
  ///
  /// Defaults to `BorderRadius.all(Radius.circular(100))` for a pill shape.
  final BorderRadius borderRadius;

  /// Glassmorphism effect configuration applied to all tabs.
  ///
  /// If provided, applies a glass-like blur effect to all tab backgrounds.
  /// Individual tabs can override this with their own [glassEffect] property.
  final FloaticaGlassEffect? glassEffect;

  /// An optional expandable menu that renders as a tab in the navigation bar.
  ///
  /// When tapped, it opens an animated popup overlay containing a grid of
  /// [FloatyMenuItem]s. The menu auto-closes on tab change, outside tap,
  /// or item tap.
  final FloaticaMenu? menu;

  @override
  State<FloatyNavBar> createState() => _FloatyNavBarState();
}

class _FloatyNavBarState extends State<FloatyNavBar>
    with SingleTickerProviderStateMixin {
  late FloaticaActionButton? _floatyStyle;

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
    assert(
      widget.selectedTab >= 0 && widget.selectedTab < widget.tabs.length,
      'selectedTab (${widget.selectedTab}) must be a valid index in tabs (length ${widget.tabs.length})',
    );
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

  void _attachMenuController([FloaticaMenuController? controller]) {
    final ctrl = controller ?? widget.menu?.controller;
    ctrl?.addListener(_onMenuControllerAction);
  }

  void _detachMenuController([FloaticaMenuController? controller]) {
    final ctrl = controller ?? widget.menu?.controller;
    ctrl?.removeListener(_onMenuControllerAction);
  }

  void _onMenuControllerAction() {
    final ctrl = widget.menu?.controller;
    if (ctrl == null) return;
    final action = ctrl.consumeAction();
    if (action == null) return;
    switch (action) {
      case FloaticaMenuAction.open:
        _openMenu();
      case FloaticaMenuAction.close:
        _closeMenu();
      case FloaticaMenuAction.toggle:
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
      if (!mounted) return; // ← Fix: guard against unmounted widget
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
    if (menu == null || !mounted) return;

    final renderBox =
        _navBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final navBarTop = renderBox.localToGlobal(Offset.zero).dy;
    final navBarLeft = renderBox.localToGlobal(Offset.zero).dx;
    final navBarWidth = renderBox.size.width;
    final navBarBottom = navBarTop + renderBox.size.height;

    // Transparent overlay just for tap-to-dismiss (no blur/color)
    _barrierOverlay = OverlayEntry(
      builder: (context) => _DismissOverlayWidget(
        animation: _menuController!,
        curve: menu.animationCurve ?? Curves.easeOutCubic,
        navBarTop: navBarTop,
        navBarLeft: navBarLeft,
        navBarWidth: navBarWidth,
        navBarBottom: navBarBottom,
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
    if (_barrierOverlay != null) {
      try {
        _barrierOverlay!.remove();
      } catch (_) {
        // Overlay may have already been removed
      }
      try {
        _barrierOverlay!.dispose();
      } catch (_) {
        // Overlay may have already been disposed
      }
      _barrierOverlay = null;
    }
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
          child: _floatyStyle == null
              ? const SizedBox.shrink()
              : SizedBox(
                  height: _floatyStyle!.size ?? 56,
                  width: _floatyStyle!.size ?? 56,
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
      final screenWidth = MediaQuery.of(context).size.width;
      result = SizedBox(
        width: screenWidth,
        child: Stack(
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
                    final curve =
                        menu.animationCurve ?? Curves.easeOutCubic;
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
                        filter:
                            ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        child: barrier,
                      );
                    }

                    return ClipRect(child: barrier);
                  },
                ),
              ),
            ),
            // Nav bar: second child paints on top → NOT blurred
            Align(
              alignment: Alignment.bottomCenter,
              child: result,
            ),
          ],
        ),
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
      final borderRadius = widget.borderRadius;

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
    final fabSize = _floatyStyle?.size ?? 56.0;
    return SizedBox(
      width: fabSize,
      height: fabSize,
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
        backgroundColor: _floatyStyle?.backgroundColor ?? context.primaryColor,
        foregroundColor:
            _floatyStyle?.foregroundColor ?? context.onPrimaryColor,
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
      ),
    );
  }

  /// Builds the navigation bar container with optional glass effect.
  ///
  /// When a [FloaticaMenu] is configured, the container expands upward to
  /// reveal the menu grid above the tabs row using a [SizeTransition].
  ///
  /// Tabs automatically shrink via [FittedBox] when they exceed available width,
  /// preventing overflow on small screens with many tabs.
  Widget _buildNavBarContainer(BuildContext context) {
    final tabWidgets = widget.tabs.map((tab) {
      // When menu is open, deselect all regular tabs
      final effectiveTab = _isMenuOpen ? tab.copyWith(isSelected: false) : tab;
      return FloaticaTabWidget(
        floaticaTab: effectiveTab,
        borderRadius: widget.borderRadius,
        glassEffect: widget.glassEffect,
      );
    }).toList();

    // Add menu tab if configured
    if (widget.menu != null) {
      final menu = widget.menu!;
      final menuTab = FloaticaTab(
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
        margin: menu.margin,
      );
      tabWidgets.add(
        FloaticaTabWidget(
          floaticaTab: menuTab,
          borderRadius: widget.borderRadius,
          glassEffect: widget.glassEffect,
        ),
      );
    }

    // Use FittedBox to auto-shrink tabs when they exceed available width.
    // This prevents overflow on small screens with many tabs.
    final tabsRow = SizedBox(
      height: widget.height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: tabWidgets,
        ),
      ),
    );

    // Build the content Column: menu grid (animated) + tabs row
    final hasMenu = widget.menu != null && _menuController != null;
    final animCurve = widget.menu?.animationCurve ?? Curves.easeOutCubic;

    // Only include SizeTransition when menu is active (open or animating).
    // When idle at sizeFactor=0, SizeTransition still reports the menu child's
    // full intrinsic width, which defeats IntrinsicWidth sizing on the container.
    final showMenuTransition =
        hasMenu && (_isMenuOpen || _menuController!.isAnimating);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMenuTransition)
          // Wrap in _ZeroIntrinsicWidth so IntrinsicWidth sizing ignores
          // the menu's wide content — the Column width is determined by
          // the tabs row only. CrossAxisAlignment.stretch then forces the
          // menu to that same width so its Wrap items reflow to fit.
          _ZeroIntrinsicWidth(
            child: SizeTransition(
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
          ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: tabsRow,
        ),
      ],
    );

    if (widget.glassEffect != null) {
      final glassEffect = widget.glassEffect!;
      final borderRadius = widget.borderRadius;

      return IntrinsicWidth(
        child: LiquidGlassContainer(
          glassEffect: glassEffect,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    // Default container without glass effect
    final borderRadius = widget.borderRadius;
    return IntrinsicWidth(
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? context.surfaceColor,
          borderRadius: borderRadius,
          boxShadow: widget.boxShadow ?? [context.boxShadow],
        ),
        child: content,
      ),
    );
  }
}

/// A widget that forces its child to report zero intrinsic width.
///
/// Used inside an [IntrinsicWidth] + [Column] with [CrossAxisAlignment.stretch]
/// to prevent a wide child (like a menu grid) from inflating the column width.
/// The child still renders at whatever width the column gives it via stretch.
class _ZeroIntrinsicWidth extends SingleChildRenderObjectWidget {
  const _ZeroIntrinsicWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderZeroIntrinsicWidth();
  }
}

class _RenderZeroIntrinsicWidth extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = computeDryLayout(constraints);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return child?.getDryLayout(constraints) ?? Size.zero;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return child?.getMinIntrinsicHeight(width) ?? 0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return child?.getMaxIntrinsicHeight(width) ?? 0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }
}

/// Transparent full-screen overlay for tap-to-dismiss.
///
/// Contains no blur or color — visual effects are handled by the [Stack]
/// overflow barrier inside [_FloatyNavBarState.build].
/// Tapping anywhere outside the nav bar / menu closes the menu.
class _DismissOverlayWidget extends StatelessWidget {
  const _DismissOverlayWidget({
    required this.animation,
    required this.curve,
    required this.navBarTop,
    required this.navBarLeft,
    required this.navBarWidth,
    required this.navBarBottom,
    required this.menuHeight,
    required this.onTap,
  });

  final Animation<double> animation;
  final Curve curve;
  final double navBarTop;
  final double navBarLeft;
  final double navBarWidth;
  final double navBarBottom;
  final double menuHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = curve.transform(animation.value);
        if (value == 0) return const SizedBox.shrink();

        // The expanded nav bar area (menu + tabs) to exclude from dismiss
        final expandedTop = navBarTop - (menuHeight * value);
        final navBarRight = navBarLeft + navBarWidth;

        return Stack(
          children: [
            // Top: above the expanded nav bar
            if (expandedTop > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: expandedTop,
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            // Left: beside the nav bar
            if (navBarLeft > 0)
              Positioned(
                top: expandedTop > 0 ? expandedTop : 0,
                left: 0,
                width: navBarLeft,
                bottom: 0,
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            // Right: beside the nav bar
            Positioned(
              top: expandedTop > 0 ? expandedTop : 0,
              left: navBarRight,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            // Bottom: below the nav bar
            if (navBarBottom < MediaQuery.of(context).size.height)
              Positioned(
                top: navBarBottom,
                left: navBarLeft,
                width: navBarWidth,
                bottom: 0,
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                ),
              ),
          ],
        );
      },
    );
  }
}
