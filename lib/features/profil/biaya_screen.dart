import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/cost_repository.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';
import 'package:foodpilot/shared/dates.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/money_field.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Biaya operasional bulanan, bisa disalin dari bulan lalu (PRD F-04).
class BiayaScreen extends ConsumerStatefulWidget {
  const BiayaScreen({super.key});

  @override
  ConsumerState<BiayaScreen> createState() => _BiayaScreenState();
}

class _BiayaScreenState extends ConsumerState<BiayaScreen> {
  late String _period = periodKey(today());

  Future<void> _edit({CostItem? item}) async {
    // Diambil sebelum await: context tidak boleh dipakai setelah jeda async.
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<_CostInput>(
      context: context,
      builder: (context) => _CostDialog(item: item),
    );
    if (result == null) return;

    try {
      await ref
          .read(costRepositoryProvider)
          .saveCost(
            id: item?.id,
            period: _period,
            name: result.name,
            amount: result.amount,
          );
    } on DuplicateCostException catch (error) {
      showSnackOn(messenger, error.message);
    }
  }

  Future<void> _copyPrevious() async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = await ref
        .read(costRepositoryProvider)
        .copyFromPreviousPeriod(_period);
    showSnackOn(
      messenger,
      copied == 0
          ? 'Tidak ada biaya baru untuk disalin.'
          : '$copied biaya disalin dari bulan lalu.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final costs = ref.watch(costsProvider(_period)).value ?? const <CostItem>[];
    final business = ref.watch(businessProvider).value;
    final operatingDays = business?.operatingDays ?? 30;

    var total = 0;
    for (final cost in costs) {
      total += cost.amount;
    }
    final perDay = dailyFixedCost(
      monthlyCost: total,
      operatingDays: operatingDays,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Biaya operasional')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s8,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () =>
                    setState(() => _period = previousPeriod(_period)),
                icon: const Icon(LucideIcons.chevronLeft),
                tooltip: 'Bulan sebelumnya',
              ),
              Expanded(
                child: Text(
                  formatBulan(periodStart(_period)),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _period = nextPeriod(_period)),
                icon: const Icon(LucideIcons.chevronRight),
                tooltip: 'Bulan berikutnya',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Total bulan ini', style: textTheme.bodySmall),
                Text(formatRupiah(total), style: textTheme.headlineSmall),
                const SizedBox(height: AppSpace.s8),
                Text(
                  'Dibagi $operatingDays hari buka: '
                  '${formatRupiah(perDay)} per hari.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          if (costs.isEmpty)
            Text(
              'Belum ada biaya di bulan ini.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            )
          else
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < costs.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      title: Text(costs[i].name),
                      subtitle: Text(formatRupiah(costs[i].amount)),
                      onTap: () => unawaited(_edit(item: costs[i])),
                      trailing: IconButton(
                        onPressed: () => unawaited(
                          ref
                              .read(costRepositoryProvider)
                              .deleteCost(costs[i].id),
                        ),
                        tooltip: 'Hapus',
                        icon: Icon(LucideIcons.trash2, color: colors.textMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpace.s16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => unawaited(_copyPrevious()),
              icon: const Icon(LucideIcons.copy, size: 18),
              label: const Text('Salin dari bulan lalu'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ActionPill(
        label: 'Tambah biaya',
        onPressed: () => unawaited(_edit()),
      ),
    );
  }
}

class _CostInput {
  const _CostInput({required this.name, required this.amount});

  final String name;
  final int amount;
}

class _CostDialog extends StatefulWidget {
  const _CostDialog({this.item});

  final CostItem? item;

  @override
  State<_CostDialog> createState() => _CostDialogState();
}

class _CostDialogState extends State<_CostDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.item?.name ?? '',
  );
  late final TextEditingController _amountController = TextEditingController(
    text: widget.item?.amount.toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah biaya' : 'Ubah biaya'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            autofocus: widget.item == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nama biaya',
              hintText: 'Sewa tempat, listrik, gaji',
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          MoneyField(controller: _amountController, label: 'Jumlah per bulan'),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final amount = parseRupiah(_amountController.text) ?? 0;
            if (name.isEmpty || amount <= 0) return;
            Navigator.of(
              context,
            ).pop(_CostInput(name: name, amount: amount));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
