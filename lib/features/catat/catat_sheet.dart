import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/features/catat/catat_controller.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';
import 'package:foodpilot/shared/dates.dart';

/// Membuka modal catat penjualan dari bawah (CONTEXT.md bagian 7).
Future<void> showCatatSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const CatatSheet(),
  );
}

/// Tiga zona sesuai DESAIN-catat.md: header, grid kartu menu, bar aksi.
/// Target: mencatat satu hari di bawah 10 detik.
class CatatSheet extends ConsumerStatefulWidget {
  const CatatSheet({super.key});

  @override
  ConsumerState<CatatSheet> createState() => _CatatSheetState();
}

class _CatatSheetState extends ConsumerState<CatatSheet> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(catatControllerProvider.notifier).open(today()));
    });
  }

  Future<void> _pickDate() async {
    final state = ref.read(catatControllerProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(2020),
      lastDate: today(),
      helpText: 'Pilih tanggal penjualan',
    );
    if (picked == null) return;
    await ref
        .read(catatControllerProvider.notifier)
        .open(DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save(List<Product> products) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(salesRepositoryProvider);
    final bottomMargin = bottomChromeClearance(context) - AppSpace.s24;

    try {
      final token = await ref
          .read(catatControllerProvider.notifier)
          .save(products);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnackOn(
        messenger,
        'Tersimpan',
        duration: const Duration(seconds: 5),
        bottomMargin: bottomMargin,
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () => unawaited(repository.undo(token)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnackOn(messenger, 'Gagal menyimpan: $error');
    }
  }

  Future<void> _askQty(Product product, int current) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (context) => _QtyDialog(product: product, initial: current),
    );
    if (qty == null) return;
    ref.read(catatControllerProvider.notifier).setQty(product.id, qty);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(catatControllerProvider);
    final products = ref.watch(catatProductsProvider).value ?? const <Product>[];
    final business = ref.watch(businessProvider).value;
    final unitWord = business?.type.unitWord ?? 'porsi';
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final savedAt = state.savedAt;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s8,
              AppSpace.s12,
              AppSpace.s22,
              AppSpace.s8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                  icon: Icon(LucideIcons.x, color: colors.text),
                ),
                const SizedBox(width: AppSpace.s4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Catat penjualan', style: textTheme.titleLarge),
                        InkWell(
                          onTap: () => unawaited(_pickDate()),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.s4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  formatTanggal(state.date, longMonth: true),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.s4),
                                Icon(
                                  LucideIcons.calendar,
                                  size: 14,
                                  color: colors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (savedAt != null)
                          Text(
                            'Terakhir disimpan ${formatJam(savedAt)}',
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? EmptyState(
                    icon: LucideIcons.utensils,
                    title: 'Belum ada menu aktif',
                    message:
                        'Tambahkan menu dulu supaya penjualannya bisa '
                        'dicatat.',
                    actionLabel: 'Tambah menu',
                    onAction: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.push('/menu/baru');
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.s22,
                      AppSpace.s8,
                      AppSpace.s22,
                      AppSpace.s16,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpace.s12,
                          crossAxisSpacing: AppSpace.s12,
                          childAspectRatio: 1.35,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final qty = state.qtyOf(product.id);
                      return _MenuCard(
                        product: product,
                        qty: qty,
                        onTap: () {
                          unawaited(HapticFeedback.lightImpact());
                          ref
                              .read(catatControllerProvider.notifier)
                              .increment(product.id);
                        },
                        onRemove: () => ref
                            .read(catatControllerProvider.notifier)
                            .decrement(product.id),
                        onLongPress: () => unawaited(_askQty(product, qty)),
                      );
                    },
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.s22,
                AppSpace.s16,
                AppSpace.s22,
                AppSpace.s16 + bottomInset,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${state.totalQty} $unitWord terjual',
                          style: textTheme.bodySmall,
                        ),
                        Text(
                          formatRupiah(state.totalRupiah(products)),
                          style: textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        _saving ||
                            state.loading ||
                            (state.totalQty == 0 && !state.isUpdate)
                        ? null
                        : () => unawaited(_save(products)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 52),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(state.isUpdate ? 'Perbarui' : 'Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu menu. Kartunya sendiri yang jadi tombol tambah, jadi target
/// sentuhnya besar (DESAIN-catat.md).
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.product,
    required this.qty,
    required this.onTap,
    required this.onRemove,
    required this.onLongPress,
  });

  final Product product;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final selected = qty > 0;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: selected ? colors.ink : colors.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutBack,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      height: 28,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s8,
                      ),
                      decoration: ShapeDecoration(
                        color: colors.ink,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '$qty',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      formatRupiah(product.sellPrice),
                      style: textTheme.bodySmall,
                    ),
                  ),
                  if (selected)
                    SizedBox.square(
                      dimension: 32,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onRemove,
                          child: Icon(
                            LucideIcons.minus,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Masukan angka langsung, untuk yang menjual 40 porsi tanpa menekan 40 kali.
class _QtyDialog extends StatefulWidget {
  const _QtyDialog({required this.product, required this.initial});

  final Product product;
  final int initial;

  @override
  State<_QtyDialog> createState() => _QtyDialogState();
}

class _QtyDialogState extends State<_QtyDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == 0 ? '' : widget.initial.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product.name),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(labelText: 'Jumlah terjual'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(int.tryParse(_controller.text.trim()) ?? 0),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
