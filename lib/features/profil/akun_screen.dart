import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/core/config.dart';
import 'package:foodpilot/core/setting_keys.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/features/profil/backup_service.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Login dan cadangan data. Aplikasi tetap berfungsi penuh tanpa login
/// (PRD F-14).
class AkunScreen extends ConsumerStatefulWidget {
  const AkunScreen({super.key});

  @override
  ConsumerState<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends ConsumerState<AkunScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!mounted) return;
      showSnackOn(messenger, successMessage);
    } catch (error) {
      if (!mounted) return;
      showSnackOn(messenger, 'Gagal: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider).value ?? const <String, String>{};
    final lastBackup = settings[SettingKeys.lastBackupAt];

    if (!AppConfig.hasSupabase) {
      return Scaffold(
        appBar: AppBar(title: const Text('Akun dan cadangan')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpace.s22),
          child: SectionCard(
            child: Text(
              'Supabase belum dikonfigurasi, jadi cadangan online belum '
              'aktif. Langkahnya ada di SETUP.md. Semua fitur lain tetap '
              'jalan tanpa ini.',
              style: textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final service = ref.watch(backupServiceProvider);
    final user = service.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun dan cadangan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s16,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          if (user == null) ...<Widget>[
            Text(
              'Masuk untuk mencadangkan data ke server. Tanpa masuk, semua '
              'data tetap tersimpan di HP ini.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.s16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: AppSpace.s12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
            ),
            const SizedBox(height: AppSpace.s16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            _run(
                              () => service.signIn(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              ),
                              'Berhasil masuk',
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Masuk'),
                  ),
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(
                            _run(
                              () => service.signUp(
                                email: _emailController.text.trim(),
                                password: _passwordController.text,
                              ),
                              'Akun dibuat. Cek email kalau diminta konfirmasi.',
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Daftar'),
                  ),
                ),
              ],
            ),
          ] else ...<Widget>[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Masuk sebagai', style: textTheme.bodySmall),
                  Text(user.email ?? '-', style: textTheme.bodyLarge),
                  if (lastBackup != null) ...<Widget>[
                    const SizedBox(height: AppSpace.s8),
                    Text(
                      'Cadangan terakhir: '
                      '${formatTanggal(DateTime.parse(lastBackup))} '
                      '${formatJam(DateTime.parse(lastBackup))}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => unawaited(
                      _run(() async {
                        final at = await service.backup();
                        await ref
                            .read(settingsRepositoryProvider)
                            .set(
                              SettingKeys.lastBackupAt,
                              at.toIso8601String(),
                            );
                      }, 'Data tercadangkan'),
                    ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: const Text('Cadangkan sekarang'),
            ),
            const SizedBox(height: AppSpace.s12),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => unawaited(
                      _run(
                        service.restore,
                        'Data dipulihkan dari cadangan',
                      ),
                    ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: const Text('Pulihkan dari cadangan'),
            ),
            const SizedBox(height: AppSpace.s12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => unawaited(_run(service.signOut, 'Sudah keluar')),
              child: const Text('Keluar'),
            ),
          ],
        ],
      ),
    );
  }
}
