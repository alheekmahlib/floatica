import 'package:flutter/foundation.dart';

/// A controller for programmatically opening and closing the [FloatyMenu].
///
/// Attach this to a [FloatyMenu] via the [FloatyMenu.controller] property,
/// then call [open], [close], or [toggle] to control the menu state.
///
/// ```dart
/// final _menuController = FloatyMenuController();
///
/// // Open the menu
/// _menuController.open();
///
/// // Close the menu
/// _menuController.close();
///
/// // Toggle
/// _menuController.toggle();
/// ```
///
/// Remember to call [dispose] when the controller is no longer needed.
class FloatyMenuController extends ChangeNotifier {
  FloatyMenuAction? _pendingAction;

  /// Whether the menu is currently open.
  bool get isOpen => _isOpen;
  bool _isOpen = false;

  /// Opens the menu.
  void open() {
    if (_isOpen) return;
    _pendingAction = FloatyMenuAction.open;
    notifyListeners();
  }

  /// Closes the menu.
  void close() {
    if (!_isOpen) return;
    _pendingAction = FloatyMenuAction.close;
    notifyListeners();
  }

  /// Toggles the menu open/closed.
  void toggle() {
    _pendingAction = FloatyMenuAction.toggle;
    notifyListeners();
  }

  /// Consumes the pending action. Used internally by [FloatyNavBar].
  FloatyMenuAction? consumeAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  /// Updates the internal open state. Used internally by [FloatyNavBar].
  void updateIsOpen(bool value) {
    _isOpen = value;
  }
}

/// Actions that can be performed on a [FloatyMenuController].
///
/// Used internally by the nav bar to process controller commands.
enum FloatyMenuAction { open, close, toggle }
