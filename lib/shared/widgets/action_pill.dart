import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/tokens.dart';

/// Pil aksi: aksi utama layar level 2 (CONTEXT.md bagian 7).
///
/// Dipasang di slot `bottomNavigationBar` milik Scaffold, jadi posisinya sama
/// dengan tab bar di layar tab, dan SnackBar otomatis muncul di atasnya.
class ActionPill extends StatelessWidget {
  const ActionPill({required this.label, required this.onPressed, super.key});

  final String label;

  /// `null` membuat pil nonaktif.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s22,
        AppSpace.s12,
        AppSpace.s22,
        AppSpace.s22 + bottomInset,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSize.actionPillHeight),
          shape: const StadiumBorder(),
        ),
        child: Text(label),
      ),
    );
  }
}
