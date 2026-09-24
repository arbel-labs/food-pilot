import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/features/catat/catat_sheet.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';

/// Kerangka layar tab: isi tab, tab bar pil melayang, dan tombol catat.
///
/// Tab bar dan tombol catat ditaruh di Stack di atas isi tab, bukan di slot
/// `bottomNavigationBar`, karena keduanya melayang dengan inset 22 dan isi tab
/// boleh terlihat di belakangnya.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<PillTabItem> _tabs = <PillTabItem>[
    PillTabItem(icon: LucideIcons.house, label: 'Beranda'),
    PillTabItem(icon: LucideIcons.utensils, label: 'Menu'),
    PillTabItem(icon: LucideIcons.chartColumn, label: 'Analisis'),
    PillTabItem(icon: LucideIcons.user, label: 'Profil'),
  ];

  void _selectTab(int index) {
    // Mengetuk tab yang sedang aktif kembali ke halaman awal tab itu.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: navigationShell),
          Positioned(
            left: AppSpace.s22,
            right: AppSpace.s22,
            bottom: AppSpace.s22 + bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _RecordButton(onPressed: () => showCatatSheet(context)),
                const SizedBox(height: AppSize.recordButtonGap),
                PillTabBar(
                  items: _tabs,
                  currentIndex: navigationShell.currentIndex,
                  onSelected: _selectTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol tengah: lingkaran tinta 46 yang mengambang di atas pil.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Catat penjualan',
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox.square(
        dimension: AppSize.recordButton,
        child: Material(
          color: colors.ink,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(LucideIcons.plus, size: 22, color: colors.onInk),
          ),
        ),
      ),
    );
  }
}
