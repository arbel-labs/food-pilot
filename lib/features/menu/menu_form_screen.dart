import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/menu_repository.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/features/menu/caption_sheet.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/money_field.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';
import 'package:foodpilot/shared/widgets/stat_tile.dart';

/// Form tambah dan ubah menu. Modal per porsi, laba, dan margin berubah
/// saat mengetik, tanpa tombol hitung (PRD F-02).
class MenuFormScreen extends ConsumerStatefulWidget {
  const MenuFormScreen({required this.menuId, super.key});

  /// `baru` untuk menu baru, selain itu id menu yang diubah.
  final String menuId;

  bool get isNew => menuId == 'baru';

  @override
  ConsumerState<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends ConsumerState<MenuFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<_IngredientFields> _ingredients = <_IngredientFields>[];

  bool _loading = true;
  bool _isActive = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    for (final field in _ingredients) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.isNew) {
      setState(() {
        _loading = false;
        _ingredients.add(_IngredientFields());
      });
      return;
    }

    final product = await ref
        .read(menuRepositoryProvider)
        .getProduct(widget.menuId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (product != null) {
        _nameController.text = product.name;
        _priceController.text = product.sellPrice.toString();
        _isActive = product.isActive;
        for (final ingredient in product.ingredients) {
          _ingredients.add(
            _IngredientFields(
              name: ingredient.name,
              qty: formatQty(ingredient.qty),
              price: ingredient.unitPrice.toString(),
              unit: ingredient.unit,
            ),
          );
        }
      }
      if (_ingredients.isEmpty) _ingredients.add(_IngredientFields());
    });
  }

  List<IngredientInput> get _inputs => <IngredientInput>[
    for (final field in _ingredients)
      ?field.toInput(),
  ];

  int get _cost => hpp(<Ingredient>[
    for (final input in _inputs)
      Ingredient(
        id: '',
        name: input.name,
        qty: input.qty,
        unit: input.unit,
        unitPrice: input.unitPrice,
      ),
  ]);

  int get _sellPrice => parseRupiah(_priceController.text) ?? 0;

  void _removeIngredient(int index) {
    final removed = _ingredients[index];
    setState(() => _ingredients.removeAt(index));
    // Controller baru dibuang setelah frame berikutnya, saat TextField yang
    // memakainya sudah benar-benar lepas dari pohon widget.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = _sellPrice;
    final inputs = _inputs;

    final String? error;
    if (name.isEmpty) {
      error = 'Nama menu wajib diisi.';
    } else if (price <= 0) {
      error = 'Harga jual harus lebih dari nol.';
    } else if (inputs.isEmpty) {
      error = 'Tambahkan minimal satu bahan dengan jumlah di atas nol.';
    } else {
      error = null;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final business = ref.read(businessProvider).value;
    if (business == null) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(menuRepositoryProvider)
        .saveProduct(
          id: widget.isNew ? null : widget.menuId,
          businessId: business.id,
          name: name,
          sellPrice: price,
          ingredients: inputs,
          isActive: _isActive,
        );
    if (!mounted) return;
    context.pop();
    showSnackOn(messenger, 'Menu tersimpan');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final business = ref.watch(businessProvider).value;
    final unitWord = business?.type.unitWord ?? 'porsi';
    final cost = _cost;
    final price = _sellPrice;
    final marginValue = margin(sellPrice: price, cost: cost);
    final profit = profitPerUnit(sellPrice: price, cost: cost);
    final error = _error;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Tambah menu' : 'Ubah menu'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s22,
                AppSpace.s8,
                AppSpace.s22,
                AppSpace.s24,
              ),
              children: <Widget>[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: StatTile(
                          value: formatRupiah(cost),
                          label: 'Modal per $unitWord',
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Expanded(
                        child: StatTile(
                          value: formatRupiah(profit),
                          label: 'Laba per $unitWord',
                          valueColor: profit < 0 ? colors.danger : null,
                        ),
                      ),
                      const SizedBox(width: AppSpace.s8),
                      Expanded(
                        child: StatTile(
                          value: marginValue == null
                              ? '—'
                              : formatPercent(marginValue),
                          label: 'Margin',
                          valueColor:
                              marginValue != null && marginValue < 0
                              ? colors.danger
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s24),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nama menu'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.s12),
                MoneyField(
                  controller: _priceController,
                  label: 'Harga jual',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.s24),
                Text('Bahan', style: textTheme.titleLarge),
                const SizedBox(height: AppSpace.s4),
                Text(
                  'Isi jumlah bahan untuk satu $unitWord beserta harga per '
                  'satuannya.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpace.s12),
                for (var index = 0; index < _ingredients.length; index++) ...[
                  _IngredientRow(
                    // Tanpa key, menghapus baris atas membuat dropdown baris
                    // bawah tetap menampilkan satuan milik baris yang dihapus,
                    // karena State dicocokkan berdasarkan posisi.
                    key: ObjectKey(_ingredients[index]),
                    fields: _ingredients[index],
                    onChanged: () => setState(() {}),
                    onRemove: _ingredients.length == 1
                        ? null
                        : () => _removeIngredient(index),
                  ),
                  const SizedBox(height: AppSpace.s12),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _ingredients.add(_IngredientFields())),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Tambah bahan'),
                  ),
                ),
                if (!widget.isNew) ...<Widget>[
                  const SizedBox(height: AppSpace.s12),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      title: const Text('Menu aktif'),
                      subtitle: const Text(
                        'Menu nonaktif tidak muncul saat mencatat penjualan, '
                        'tapi riwayatnya tetap tersimpan.',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.s12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showCaptionSheet(
                        context,
                        menuName: _nameController.text.trim(),
                        price: price,
                      ),
                      icon: const Icon(LucideIcons.sparkles, size: 18),
                      label: const Text('Buat caption promo'),
                    ),
                  ),
                ],
                if (error != null) ...<Widget>[
                  const SizedBox(height: AppSpace.s12),
                  Text(
                    error,
                    style: textTheme.bodyMedium?.copyWith(color: colors.danger),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: ActionPill(
        label: 'Simpan',
        onPressed: _loading ? null : () => unawaited(_save()),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.fields,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _IngredientFields fields;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remove = onRemove;

    return SectionCard(
      padding: const EdgeInsets.all(AppSpace.s12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: fields.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nama bahan'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (remove != null) ...<Widget>[
                const SizedBox(width: AppSpace.s8),
                IconButton(
                  onPressed: remove,
                  tooltip: 'Hapus bahan',
                  icon: Icon(LucideIcons.trash2, color: colors.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: QtyField(
                  controller: fields.qtyController,
                  label: 'Jumlah',
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<IngredientUnit>(
                  initialValue: fields.unit,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  items: <DropdownMenuItem<IngredientUnit>>[
                    for (final unit in IngredientUnit.values)
                      DropdownMenuItem<IngredientUnit>(
                        value: unit,
                        child: Text(unit.label),
                      ),
                  ],
                  onChanged: (unit) {
                    if (unit == null) return;
                    fields.unit = unit;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                flex: 4,
                child: MoneyField(
                  controller: fields.priceController,
                  label: 'Harga/satuan',
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientFields {
  _IngredientFields({
    String name = '',
    String qty = '',
    String price = '',
    this.unit = IngredientUnit.gram,
  }) : nameController = TextEditingController(text: name),
       qtyController = TextEditingController(text: qty),
       priceController = TextEditingController(text: price);

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  IngredientUnit unit;

  IngredientInput? toInput() {
    final name = nameController.text.trim();
    final qty = parseQty(qtyController.text);
    if (name.isEmpty || qty == null || qty <= 0) return null;
    return IngredientInput(
      name: name,
      qty: qty,
      unit: unit,
      unitPrice: parseRupiah(priceController.text) ?? 0,
    );
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}
