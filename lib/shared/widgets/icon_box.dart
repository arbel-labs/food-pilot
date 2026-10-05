import 'package:flutter/material.dart';

/// Kotak membulat berisi ikon atau label pendek.
///
/// Dipakai di baris daftar supaya terbaca cepat tanpa perlu garis pemisah.
class IconBox extends StatelessWidget {
  const IconBox({
    super.key,
    this.icon,
    this.label,
    required this.background,
    required this.foreground,
    this.size = 38,
  }) : assert(
         icon != null || label != null,
         'IconBox butuh icon atau label',
       );

  final IconData? icon;
  final String? label;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: foreground)
          : Text(
              label!,
              style: TextStyle(
                fontSize: size * 0.37,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
    );
  }
}