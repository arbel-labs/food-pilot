import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';

/// Snackbar melayang yang tidak tertutup tab bar dan tombol catat.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  bool aboveChrome = false,
}) {
  showSnackOn(
    ScaffoldMessenger.of(context),
    message,
    action: action,
    duration: duration,
    bottomMargin: aboveChrome
        ? bottomChromeClearance(context) - AppSpace.s24
        : MediaQuery.paddingOf(context).bottom + AppSpace.s12,
  );
}

/// Dipakai kalau layar yang memanggil sudah ditutup, misalnya setelah modal
/// catat penjualan ditutup: messenger diambil dulu sebelum menutup.
void showSnackOn(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  double bottomMargin = AppSpace.s12,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        margin: EdgeInsets.fromLTRB(
          AppSpace.s22,
          0,
          AppSpace.s22,
          bottomMargin,
        ),
      ),
    );
}
