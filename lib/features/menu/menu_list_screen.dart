import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/async_view.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';
import 'package:foodpilot/shared/widgets/status_chip.dart';

class MenuListScreen extends ConsumerWidget {
  const MenuListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/menu/baru'),
            tooltip: 'Tambah menu',
            icon: const Icon(LucideIcons.plus),
          ),
          const SizedBox(width: AppSpace.s8),
        ],
      ),
      body: AsyncView<List<Product>>(
        value: products,
        builder: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomChromeClearance(context)),
              child: EmptyState(
                icon: LucideIcons.utensils,
                title: 'Belum ada menu',
                message:
                    'Tambahkan menu pertama supaya modal per porsi dan '
                    'labanya bisa dihitung.',
                actionLabel: 'Tambah menu',
                onAction: () => context.push('/menu/baru'),
              ),
            );
          }

          final active = list.where((product) => product.isActive).toList();
          final inactive = list.where((product) => !product.isActive).toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.s22,
              AppSpace.s8,
              AppSpace.s22,
              bottomChromeClearance(context),
            ),
            children: <Widget>[
              for (final product in active) ...<Widget>[
                _MenuTile(product: product),
                const SizedBox(height: AppSpace.s12),
              ],
              if (inactive.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpace.s12),
                _SectionLabel(label: 'Nonaktif (${inactive.length})'),
                const SizedBox(height: AppSpace.s12),
                for (final product in inactive) ...<Widget>[
                  _MenuTile(product: product, dimmed: true),
                  const SizedBox(height: AppSpace.s12),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.product, this.dimmed = false});

  final Product product;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final cost = hpp(product.ingredients);
    final value = margin(sellPrice: product.sellPrice, cost: cost);

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: SectionCard(
        onTap: () => context.push('/menu/${product.id}'),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.s4),
                  Text(
                    '${formatRupiah(product.sellPrice)} · modal '
                    '${formatRupiah(cost)}',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.s8),
                  MarginBadge(margin: value),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
