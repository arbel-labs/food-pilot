import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/brand.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/features/chat/chat_controller.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/icon_box.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Menambah menu lewat kalimat biasa.
///
/// AI hanya menerjemahkan kalimat jadi data. Seluruh angka di kartu
/// konfirmasi dihitung lapisan domain, jadi yang dibaca pemilik dijamin
/// sama dengan yang tersimpan.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _kirim() {
    final teks = _input.text;
    if (teks.trim().isEmpty) return;
    _input.clear();
    ref.read(chatControllerProvider.notifier).kirim(teks);
    _keBawah();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider, (_, _) => _keBawah());

    return Scaffold(
      appBar: AppBar(title: const Text('Tulis saja')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: state.bubbles.isEmpty
                ? const _Pembuka()
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpace.s22),
                    itemCount: state.bubbles.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s12),
                    itemBuilder: (context, index) =>
                        _Bubble(bubble: state.bubbles[index]),
                  ),
          ),
          if (state.busy)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  Text(
                    'Sedang membaca...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s22,
                AppSpace.s8,
                AppSpace.s22,
                AppSpace.s12,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirim(),
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tulis atau ucapkan menunya',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s8),
                  _TombolKirim(enabled: !state.busy, onTap: _kirim),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TombolKirim extends StatelessWidget {
  const _TombolKirim({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: enabled ? colors.ink : colors.border,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            LucideIcons.arrowUp,
            size: 20,
            color: enabled ? colors.onInk : colors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Kondisi kosong berisi contoh kalimat yang bisa langsung ditiru.
class _Pembuka extends StatelessWidget {
  const _Pembuka();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.s22),
      children: <Widget>[
        const SizedBox(height: AppSpace.s24),
        Center(
          child: IconBox(
            icon: LucideIcons.messageCircle,
            background: brand.brandTint,
            foreground: brand.brand,
            size: 52,
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Text(
          'Tulis menunya dengan bahasa sehari-hari',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          'Nanti aku rapikan jadi data menu. Sebelum disimpan, kamu cek '
          'dulu angkanya.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpace.s24),
        Text('Contoh', style: textTheme.bodySmall),
        const SizedBox(height: AppSpace.s8),
        for (final contoh in <String>[
          'tambah jus mangga 10 rb, bahannya air 2 rb sama sirup 4 rb',
          'es teh manis 5000 modalnya teh 500 gula 300 es 200',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s8),
            child: Container(
              padding: const EdgeInsets.all(AppSpace.s12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.border),
              ),
              child: Text(contoh, style: textTheme.bodyMedium),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.bubble});

  final ChatBubble bubble;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    switch (bubble) {
      case ChatUserText(:final text):
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s16,
              vertical: AppSpace.s12,
            ),
            decoration: BoxDecoration(
              color: colors.ink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(color: colors.onInk),
            ),
          ),
        );

      case ChatBotText(:final text, :final isError):
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isError ? colors.danger : colors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (isError) ...<Widget>[
                  Icon(
                    LucideIcons.circleAlert,
                    size: 18,
                    color: colors.danger,
                  ),
                  const SizedBox(width: AppSpace.s8),
                ],
                Flexible(child: Text(text, style: textTheme.bodyMedium)),
              ],
            ),
          ),
        );

      case ChatDraft():
        return _KartuDraf(bubble: bubble as ChatDraft);
    }
  }
}

/// Rekap yang disusun aplikasi, bukan AI. Modal dan margin dihitung di
/// lapisan domain supaya angka di layar dijamin sama dengan yang disimpan.
class _KartuDraf extends ConsumerWidget {
  const _KartuDraf({required this.bubble});

  final ChatDraft bubble;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;
    final draft = bubble.draft;
    final busy = ref.watch(chatControllerProvider).busy;
    final rugi = draft.profit < 0;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bubble.saved ? 'Sudah tersimpan' : 'Sudah benar seperti ini?',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.s12),
          Container(
            padding: const EdgeInsets.all(AppSpace.s12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(draft.name, style: textTheme.titleMedium),
                const SizedBox(height: AppSpace.s8),
                _Baris(
                  label: 'Harga jual',
                  value: formatRupiah(draft.sellPrice),
                  tebal: true,
                ),
                if (draft.ingredients.isNotEmpty) ...<Widget>[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.s8),
                    child: Divider(height: 1),
                  ),
                  for (final item in draft.ingredients)
                    _Baris(
                      label: item.name,
                      value: formatRupiah(item.price),
                    ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.s8),
                  child: Divider(height: 1),
                ),
                _Baris(
                  label: 'Modal per porsi',
                  value: formatRupiah(draft.cost),
                  tebal: true,
                ),
                const SizedBox(height: AppSpace.s4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        rugi ? 'Rugi per porsi' : 'Untung per porsi',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    if (draft.margin != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s8,
                          vertical: 2,
                        ),
                        decoration: ShapeDecoration(
                          color: rugi ? brand.dangerTint : brand.successTint,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          formatPercent(draft.margin!),
                          style: textTheme.bodySmall?.copyWith(
                            color: rugi ? colors.danger : colors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpace.s8),
                    Text(
                      formatRupiah(draft.profit),
                      style: textTheme.bodyMedium?.copyWith(
                        color: rugi ? colors.danger : colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (draft.ingredients.isEmpty) ...<Widget>[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Bahannya belum ada, jadi modalnya masih nol. Bisa dilengkapi '
              'nanti lewat halaman Menu.',
              style: textTheme.bodySmall,
            ),
          ],
          if (rugi) ...<Widget>[
            const SizedBox(height: AppSpace.s8),
            Text(
              'Modalnya lebih besar dari harga jual. Boleh disimpan, tapi '
              'menu ini bakal menggerus laba.',
              style: textTheme.bodySmall?.copyWith(color: colors.danger),
            ),
          ],
          if (!bubble.saved) ...<Widget>[
            const SizedBox(height: AppSpace.s16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () => ref
                              .read(chatControllerProvider.notifier)
                              .simpan(bubble),
                    child: const Text('Benar, simpan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              'Kalau ada yang salah, tulis saja koreksinya di bawah. '
              'Contoh: sirupnya 5 rb.',
              style: textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.value, this.tebal = false});

  final String label;
  final String value;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.text,
              fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}