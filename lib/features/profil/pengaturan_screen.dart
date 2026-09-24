import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/core/config.dart';
import 'package:foodpilot/core/setting_keys.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/features/profil/reminder_service.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  static const String _defaultReminderTime = '17:00';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final settings =
        ref.watch(settingsProvider).value ?? const <String, String>{};
    final sales = ref.watch(recentSalesProvider).value ?? const <DaySale>[];
    final products = ref.watch(productsProvider).value ?? const <Product>[];

    final reminderOn = settings[SettingKeys.reminderEnabled] == 'true';
    final reminderTime =
        settings[SettingKeys.reminderTime] ?? _defaultReminderTime;
    final demoOn =
        !AppConfig.hasSupabase || settings[SettingKeys.aiDemo] == 'true';
    final dataEmpty = sales.isEmpty && products.isEmpty;

    Future<void> setSetting(String key, String value) =>
        ref.read(settingsRepositoryProvider).set(key, value);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s16,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: reminderOn,
                  title: const Text('Pengingat harian'),
                  subtitle: Text('Tiap hari jam $reminderTime'),
                  onChanged: (value) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final parts = reminderTime.split(':');
                    if (value) {
                      final granted = await ReminderService.instance.enable(
                        hour: int.tryParse(parts[0]) ?? 17,
                        minute: int.tryParse(parts[1]) ?? 0,
                      );
                      if (!granted) {
                        showSnackOn(
                          messenger,
                          'Izin notifikasi belum diberikan.',
                        );
                        return;
                      }
                    } else {
                      await ReminderService.instance.disable();
                    }
                    await setSetting(
                      SettingKeys.reminderEnabled,
                      value.toString(),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Jam pengingat'),
                  subtitle: Text(reminderTime),
                  onTap: () async {
                    final parts = reminderTime.split(':');
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: int.tryParse(parts[0]) ?? 17,
                        minute: int.tryParse(parts[1]) ?? 0,
                      ),
                    );
                    if (picked == null) return;
                    final value =
                        '${picked.hour.toString().padLeft(2, '0')}:'
                        '${picked.minute.toString().padLeft(2, '0')}';
                    await setSetting(SettingKeys.reminderTime, value);
                    if (reminderOn) {
                      await ReminderService.instance.enable(
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              value: demoOn,
              title: const Text('Mode demo konsultan AI'),
              subtitle: Text(
                AppConfig.hasSupabase
                    ? 'Memakai balasan tersimpan, tanpa memanggil server.'
                    : 'Supabase belum dikonfigurasi, jadi mode demo dipakai.',
              ),
              onChanged: AppConfig.hasSupabase
                  ? (value) => unawaited(
                      setSetting(SettingKeys.aiDemo, value.toString()),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Data', style: textTheme.titleLarge),
          const SizedBox(height: AppSpace.s8),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  title: const Text('Isi data contoh 30 hari'),
                  subtitle: Text(
                    dataEmpty
                        ? 'Menambahkan warung fiktif beserta penjualannya.'
                        : 'Hanya bisa saat data masih kosong.',
                  ),
                  enabled: dataEmpty,
                  onTap: dataEmpty
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await ref.read(seedServiceProvider).run();
                          showSnackOn(messenger, 'Data contoh ditambahkan');
                        }
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Hapus semua data'),
                  subtitle: const Text(
                    'Menghapus menu, penjualan, biaya, dan riwayat analisis.',
                  ),
                  onTap: () async {
                    final router = GoRouter.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus semua data?'),
                        content: const Text(
                          'Semua catatan di HP ini akan hilang dan tidak bisa '
                          'dikembalikan, kecuali kamu punya cadangan.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await ref.read(backupRepositoryProvider).deleteAll();
                    router.go('/onboarding');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          SectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: const Text('Lisensi'),
              subtitle: const Text('Termasuk lisensi font Plus Jakarta Sans'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'FoodPilot',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
