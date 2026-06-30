import 'package:flutter/material.dart';

/// Bottom spacing so content stays above the phone navigation bar.
class SafeBottom {
  static double inset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// Full-screen pages (login, register, pushed routes).
  static double forScroll(BuildContext context, {double extra = 16}) =>
      inset(context) + extra;

  static EdgeInsets scrollPadding(BuildContext context, {double extra = 16}) =>
      EdgeInsets.only(bottom: forScroll(context, extra: extra));

  static Widget spacer(BuildContext context, {double extra = 16}) =>
      SizedBox(height: forScroll(context, extra: extra));

  /// Tab pages inside [MainShell] (already above app bottom nav).
  static Widget tabSpacer({double extra = 20}) => SizedBox(height: extra);

  static EdgeInsets inputBarPadding(
    BuildContext context, {
    double left = 12,
    double top = 8,
    double right = 12,
    double extra = 12,
  }) {
    final bottom =
        inset(context) + extra + MediaQuery.viewInsetsOf(context).bottom;
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
}
