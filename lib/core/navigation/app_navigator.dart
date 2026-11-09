import 'package:flutter/material.dart';

/// Global App-Level Navigator Key for dialogs, popups, and top-level navigation.
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Returns the current active BuildContext from the top-level NavigatorState if mounted.
  static BuildContext? get currentContext {
    final context = navigatorKey.currentContext ?? navigatorKey.currentState?.context;
    if (context != null && context.mounted) {
      return context;
    }
    return null;
  }
}
