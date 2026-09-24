import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';

class UsahaScreen extends ConsumerStatefulWidget {
  const UsahaScreen({super.key});

  @override
  ConsumerState<UsahaScreen> createState() => _UsahaScreenState();
}

class _UsahaScreenState extends ConsumerState<UsahaScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  BusinessType _type = BusinessType.kuliner;
  String? _openTime;
  String? _closeTime;
  bool _loaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _loadOnce(Business business) {
    if (_loaded) return;
    _loaded = true;
    _nameController.text = business.name;
    _daysController.text = business.operatingDays.toString();
    _type = business.type;
    _openTime = business.openTime;
    _closeTime = business.closeTime;
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final current = isOpen ? _openTime : _closeTime;
    final parts = current?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: parts == null
          ? const TimeOfDay(hour: 7, minute: 0)
          : TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 7,
              minute: int.tryParse(parts[1]) ?? 0,
            ),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isOpen) {
        _openTime = value;
      } else {
        _closeTime = value;
      }
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final days = int.tryParse(_daysController.text.trim()) ?? 30;

    await ref
        .read(businessRepositoryProvider)
        .save(
          name: name.isEmpty ? 'Usahaku' : name,
          type: _type,
          openTime: _openTime,
          closeTime: _closeTime,
          operatingDays: days.clamp(1, 31),
        );
    if (!mounted) return;
    context.pop();
    showSnackOn(messenger, 'Data usaha tersimpan');
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider).value;
    if (business != null) _loadOnce(business);

    return Scaffold(
      appBar: AppBar(title: const Text('Data usaha')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s16,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          TextField(
            controller: _nameController,
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
          const SizedBox(height: AppSpace.s16),
          TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hari buka per bulan',
              helperText: 'Dipakai membagi biaya bulanan menjadi biaya harian',
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => unawaited(_pickTime(isOpen: true)),
                  child: Text('Buka: ${_openTime ?? '—'}'),
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => unawaited(_pickTime(isOpen: false)),
                  child: Text('Tutup: ${_closeTime ?? '—'}'),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ActionPill(
        label: 'Simpan',
        onPressed: () => unawaited(_save()),
      ),
    );
  }
}
