import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';

class LinkItem {
  const LinkItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// Kartu berisi daftar tautan ke layar lain, dipisah garis tipis.
class LinkListCard extends StatelessWidget {
  const LinkListCard({required this.items, super.key});

  final List<LinkItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: <Widget>[
            for (var i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0)
                const Divider(indent: AppSpace.s16, endIndent: AppSpace.s16),
              _LinkTile(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.item});

  final LinkItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = item.subtitle;

    return ListTile(
      leading: Icon(item.icon, color: colors.text),
      title: Text(item.title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 20,
        color: colors.textMuted,
      ),
      onTap: item.onTap,
    );
  }
}
