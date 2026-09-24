import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/shared/widgets/link_list_card.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final business = ref.watch(businessProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s8,
          AppSpace.s22,
          bottomChromeClearance(context),
        ),
        children: <Widget>[
          SectionCard(
            onTap: () => context.push('/profil/usaha'),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        business?.name ?? 'Usaha belum diisi',
                        style: textTheme.titleLarge,
                      ),
                      Text(
                        business == null
                            ? 'Ketuk untuk mengisi'
                            : '${business.type.label} · '
                                  '${business.operatingDays} hari buka '
                                  'per bulan',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          LinkListCard(
            items: <LinkItem>[
              LinkItem(
                icon: LucideIcons.wallet,
                title: 'Biaya operasional',
                subtitle: 'Sewa, listrik, gaji, dan lainnya',
                onTap: () => context.push('/profil/biaya'),
              ),
              LinkItem(
                icon: LucideIcons.fileText,
                title: 'Laporan bulanan',
                subtitle: 'Ringkasan bulan berjalan, bisa dibagikan PDF',
                onTap: () => context.push('/profil/laporan'),
              ),
              LinkItem(
                icon: LucideIcons.logIn,
                title: 'Akun dan cadangan',
                subtitle: 'Cadangkan data supaya aman kalau HP hilang',
                onTap: () => context.push('/profil/akun'),
              ),
              LinkItem(
                icon: LucideIcons.settings,
                title: 'Pengaturan',
                subtitle: 'Pengingat harian, mode demo, data contoh',
                onTap: () => context.push('/profil/pengaturan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
