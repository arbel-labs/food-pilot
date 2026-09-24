import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/features/analisis/ai_service.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Caption promo untuk satu menu (PRD F-13).
Future<void> showCaptionSheet(
  BuildContext context, {
  required String menuName,
  required int price,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CaptionSheet(menuName: menuName, price: price),
  );
}

class _CaptionSheet extends ConsumerStatefulWidget {
  const _CaptionSheet({required this.menuName, required this.price});

  final String menuName;
  final int price;

  @override
  ConsumerState<_CaptionSheet> createState() => _CaptionSheetState();
}

class _CaptionSheetState extends ConsumerState<_CaptionSheet> {
  String? _caption;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_generate());
    });
  }

  Future<void> _generate() async {
    if (widget.menuName.isEmpty) {
      setState(() => _error = 'Isi nama menu dulu, baru caption bisa dibuat.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final business = ref.read(businessProvider).value;
    try {
      final caption = await ref
          .read(aiServiceProvider)
          .caption(
            businessName: business?.name ?? 'warung',
            menuName: widget.menuName,
            price: widget.price,
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _caption = caption;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Caption gagal dibuat: $error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final caption = _caption;
    final error = _error;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s22,
        AppSpace.s24,
        AppSpace.s22,
        AppSpace.s24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Caption promo', style: textTheme.titleLarge),
          const SizedBox(height: AppSpace.s12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Text(error, style: textTheme.bodyMedium)
          else if (caption != null)
            SectionCard(child: Text(caption, style: textTheme.bodyLarge)),
          const SizedBox(height: AppSpace.s16),
          Row(
            children: <Widget>[
              if (caption != null)
                FilledButton(
                  onPressed: () {
                    unawaited(
                      Clipboard.setData(ClipboardData(text: caption)),
                    );
                    showAppSnack(context, 'Caption disalin');
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s24,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Salin'),
                ),
              const SizedBox(width: AppSpace.s8),
              TextButton(
                onPressed: _loading ? null : () => unawaited(_generate()),
                child: const Text('Buat lagi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
