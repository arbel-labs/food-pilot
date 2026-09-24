import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/app_theme.dart';
import 'package:foodpilot/app/theme/tokens.dart';

class PillTabItem {
  const PillTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Ruang bawah yang perlu disisakan layar tab supaya konten terakhirnya tidak
/// tertutup tab bar dan tombol catat yang melayang.
double bottomChromeClearance(BuildContext context) {
  return MediaQuery.paddingOf(context).bottom +
      AppSpace.s22 +
      AppSize.tabBarHeight +
      AppSize.recordButtonGap +
      AppSize.recordButton +
      AppSpace.s24;
}

/// Tab bar pil melayang (CONTEXT.md bagian 7).
///
/// Tab aktif berupa kapsul berlatar `border` berisi ikon dan label. Tab lain
/// hanya ikon berwarna `textMuted`.
class PillTabBar extends StatelessWidget {
  const PillTabBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  final List<PillTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Label ikut membesar kalau ukuran huruf sistem diperbesar, tapi dibatasi
    // supaya empat tab tetap muat di layar selebar 360 dp.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        height: AppSize.tabBarHeight,
        padding: const EdgeInsets.all(AppSpace.s8),
        decoration: ShapeDecoration(
          color: colors.surface,
          shape: StadiumBorder(side: BorderSide(color: colors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            for (var i = 0; i < items.length; i++)
              _PillTab(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PillTabItem item;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOutCubic,
            height: 48,
            constraints: const BoxConstraints(minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
            decoration: ShapeDecoration(
              // Transparan dari warna yang sama supaya animasinya tidak
              // melewati abu-abu gelap.
              color: selected
                  ? colors.border
                  : colors.border.withValues(alpha: 0),
              shape: const StadiumBorder(),
            ),
            child: AnimatedSize(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    item.icon,
                    size: 22,
                    color: selected ? colors.ink : colors.textMuted,
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      style: AppType.tabLabel.copyWith(color: colors.ink),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
