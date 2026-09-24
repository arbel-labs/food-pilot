import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/menu_repository.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/money_field.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Tiga langkah: sambutan, data usaha, menu pertama. Semua bisa dilewati
/// (PRD F-01). Target: sampai menu pertama tersimpan di bawah 3 menit.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _businessNameController = TextEditingController(
    text: '',
  );
  final TextEditingController _menuNameController = TextEditingController();
  final TextEditingController _menuPriceController = TextEditingController();
  final TextEditingController _ingredientNameController =
      TextEditingController();
  final TextEditingController _ingredientQtyController =
      TextEditingController();
  final TextEditingController _ingredientPriceController =
      TextEditingController();

  BusinessType _type = BusinessType.kuliner;
  IngredientUnit _unit = IngredientUnit.gram;
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pageController.dispose();
    _businessNameController.dispose();
    _menuNameController.dispose();
    _menuPriceController.dispose();
    _ingredientNameController.dispose();
    _ingredientQtyController.dispose();
    _ingredientPriceController.dispose();
    super.dispose();
  }

  Future<Business> _saveBusiness() {
    final name = _businessNameController.text.trim();
    return ref
        .read(businessRepositoryProvider)
        .save(name: name.isEmpty ? 'Usahaku' : name, type: _type);
  }

  Future<void> _finish({bool withMenu = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final business = await _saveBusiness();

      if (withMenu) {
        final menuName = _menuNameController.text.trim();
        final price = parseRupiah(_menuPriceController.text) ?? 0;
        final ingredientName = _ingredientNameController.text.trim();
        final qty = parseQty(_ingredientQtyController.text) ?? 0;
        final ingredientPrice =
            parseRupiah(_ingredientPriceController.text) ?? 0;

        if (menuName.isNotEmpty && price > 0) {
          await ref
              .read(menuRepositoryProvider)
              .saveProduct(
                businessId: business.id,
                name: menuName,
                sellPrice: price,
                ingredients: <IngredientInput>[
                  if (ingredientName.isNotEmpty && qty > 0)
                    IngredientInput(
                      name: ingredientName,
                      qty: qty,
                      unit: _unit,
                      unitPrice: ingredientPrice,
                    ),
                ],
              );
        }
      }

      router.go('/beranda');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnackOn(messenger, 'Gagal menyimpan: $error');
    }
  }

  Future<void> _fillWithSampleData() async {
    if (_busy) return;
    setState(() => _busy = true);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(seedServiceProvider).run();
      router.go('/beranda');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnackOn(messenger, 'Gagal mengisi data contoh: $error');
    }
  }

  void _next() {
    if (_page >= 2) {
      unawaited(_finish(withMenu: true));
      return;
    }
    unawaited(
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: _busy ? null : () => unawaited(_finish()),
            child: const Text('Lewati'),
          ),
          const SizedBox(width: AppSpace.s8),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _page = page),
        children: <Widget>[
          _Step(
            title: 'Selamat datang di FoodPilot',
            body:
                'Catat penjualan harian dalam hitungan detik, lalu lihat '
                'menu mana yang benar-benar untung.',
            children: <Widget>[
              SectionCard(
                onTap: _busy ? null : () => unawaited(_fillWithSampleData()),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Isi dengan data contoh',
                            style: textTheme.bodyLarge,
                          ),
                          Text(
                            '30 hari penjualan warung fiktif, untuk mencoba '
                            'semua fitur.',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Step(
            title: 'Data usaha',
            body: 'Dipakai untuk judul laporan dan istilah di dalam aplikasi.',
            children: <Widget>[
              TextField(
                controller: _businessNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama usaha'),
              ),
              const SizedBox(height: AppSpace.s16),
              Wrap(
                spacing: AppSpace.s8,
                children: <Widget>[
                  for (final type in BusinessType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
            ],
          ),
          _Step(
            title: 'Menu pertama',
            body:
                'Satu menu beserta satu bahannya sudah cukup. Bahan lain '
                'bisa ditambahkan nanti.',
            children: <Widget>[
              TextField(
                controller: _menuNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nama menu'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.s12),
              MoneyField(
                controller: _menuPriceController,
                label: 'Harga jual',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.s16),
              Text('Bahan utama', style: textTheme.titleLarge),
              const SizedBox(height: AppSpace.s8),
              TextField(
                controller: _ingredientNameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nama bahan'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.s12),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: QtyField(
                      controller: _ingredientQtyController,
                      label: 'Jumlah',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<IngredientUnit>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Satuan'),
                      items: <DropdownMenuItem<IngredientUnit>>[
                        for (final unit in IngredientUnit.values)
                          DropdownMenuItem<IngredientUnit>(
                            value: unit,
                            child: Text(unit.label),
                          ),
                      ],
                      onChanged: (unit) =>
                          setState(() => _unit = unit ?? _unit),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Expanded(
                    flex: 4,
                    child: MoneyField(
                      controller: _ingredientPriceController,
                      label: 'Harga/satuan',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s16),
              Builder(
                builder: (context) {
                  final qty = parseQty(_ingredientQtyController.text) ?? 0;
                  final unitPrice =
                      parseRupiah(_ingredientPriceController.text) ?? 0;
                  final price = parseRupiah(_menuPriceController.text) ?? 0;
                  final cost = hpp(<Ingredient>[
                    Ingredient(
                      id: '',
                      name: '',
                      qty: qty,
                      unit: _unit,
                      unitPrice: unitPrice,
                    ),
                  ]);
                  final marginValue = margin(sellPrice: price, cost: cost);
                  return Text(
                    'Modal per ${_type.unitWord}: ${formatRupiah(cost)}'
                    '${marginValue == null ? '' : ' · margin ${formatPercent(marginValue)}'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ActionPill(
        label: _page >= 2 ? 'Mulai' : 'Lanjut',
        onPressed: _busy ? null : _next,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.body,
    required this.children,
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s22,
        AppSpace.s32,
        AppSpace.s22,
        AppSpace.s24,
      ),
      children: <Widget>[
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpace.s12),
        Text(
          body,
          style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpace.s24),
        ...children,
      ],
    );
  }
}
