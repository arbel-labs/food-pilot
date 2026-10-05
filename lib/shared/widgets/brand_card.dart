import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/brand.dart';
import 'package:foodpilot/app/theme/tokens.dart';

/// Kartu berwarna merek. Satu per layar, sebagai jangkar visual.
///
/// Kalau dipakai di banyak tempat, efeknya hilang dan layar jadi ramai.
class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Material(
      color: brand.brand,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s16),
          child: child,
        ),
      ),
    );
  }
}