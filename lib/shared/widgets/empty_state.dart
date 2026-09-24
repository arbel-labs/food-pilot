import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';

/// Kondisi kosong: satu ikon, satu kalimat, satu tombol aksi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final label = actionLabel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 32, color: colors.textMuted),
            const SizedBox(height: AppSpace.s16),
            Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
            if (label != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpace.s24),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s24),
                  shape: const StadiumBorder(),
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
