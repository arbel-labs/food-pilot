import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/features/analisis/analisis_data.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';
import 'package:foodpilot/shared/widgets/stat_tile.dart';

/// Simulasi geser: harga jual dan harga bahan digeser, angka laba berubah
/// seketika tanpa memanggil apa pun (PRD F-10).
class SimulasiScreen extends ConsumerStatefulWidget {
  const SimulasiScreen({super.key});

  @override
  ConsumerState<SimulasiScreen> createState() => _SimulasiScreenState();
}

class _SimulasiScreenState extends ConsumerState<SimulasiScreen> {
  String? _productId;
  double? _price;
  double _ingredientChange = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final products =
        ref.watch(activeProductsProvider).value ?? const <Product>[];
    final data = ref.watch(analisisProvider).value;

    if (products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Simulasi harga')),
        body: const EmptyState(
          icon: LucideIcons.sliders,
          title: 'Belum ada menu aktif',
          message: 'Tambahkan menu dulu supaya harganya bisa disimulasikan.',
        ),
      );
    }

    final product = products.firstWhere(
      (item) => item.id == _productId,
      orElse: () => products.first,
    );
    final baseCost = hpp(product.ingredients);
    final price = (_price ?? product.sellPrice.toDouble()).round();
    final cost = (baseCost * (1 + _ingredientChange)).round();
    final profit = profitPerUnit(sellPrice: price, cost: cost);
    final marginValue = margin(sellPrice: price, cost: cost);
    final baseProfit = profitPerUnit(sellPrice: product.sellPrice, cost: baseCost);

    var soldQty = 0;
    for (final sale in data?.sales ?? const <DaySale>[]) {
      for (final line in sale.lines) {
        if (line.productId == product.id) soldQty += line.qty;
      }
    }
    final difference = (profit - baseProfit) * soldQty;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi harga')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s8,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: product.id,
            decoration: const InputDecoration(labelText: 'Menu'),
            items: <DropdownMenuItem<String>>[
              for (final item in products)
                DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() {
              _productId = value;
              _price = null;
              _ingredientChange = 0;
            }),
          ),
          const SizedBox(height: AppSpace.s24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: StatTile(
                    value: formatRupiah(cost),
                    label: 'Modal per porsi',
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: StatTile(
                    value: formatRupiah(profit),
                    label: 'Laba per porsi',
                    valueColor: profit < 0 ? colors.danger : colors.success,
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: StatTile(
                    value: marginValue == null
                        ? '—'
                        : formatPercent(marginValue),
                    label: 'Margin',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s24),
          Text('Harga jual: ${formatRupiah(price)}', style: textTheme.bodyLarge),
          Slider(
            value: (_price ?? product.sellPrice.toDouble()).clamp(
              product.sellPrice * 0.5,
              product.sellPrice * 1.5,
            ),
            min: product.sellPrice * 0.5,
            max: product.sellPrice * 1.5,
            divisions: 20,
            onChanged: (value) => setState(() => _price = value),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Perubahan harga bahan: '
            '${_ingredientChange >= 0 ? '+' : ''}'
            '${(_ingredientChange * 100).round()}%',
            style: textTheme.bodyLarge,
          ),
          Slider(
            value: _ingredientChange,
            min: -0.3,
            max: 0.5,
            divisions: 16,
            onChanged: (value) => setState(() => _ingredientChange = value),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dengan penjualan 30 hari terakhir ($soldQty terjual), '
                  'laba kotor menu ini berubah:',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  '${difference >= 0 ? '+' : '−'}'
                  '${formatRupiah(difference.abs())}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: difference >= 0 ? colors.success : colors.danger,
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Angka ini menganggap jumlah pembeli tidak berubah.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
