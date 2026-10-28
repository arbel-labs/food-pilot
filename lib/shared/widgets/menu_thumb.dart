import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';


/// Gambar menu berbentuk kotak membulat.
///
/// Gambar diunduh sekali lalu disimpan di HP, jadi setelah pertama kali
/// tampil, daftar menu tetap bergambar walau aplikasi dibuka tanpa
/// internet (CONTEXT.md bagian 2: offline-first).
///
/// Tiga kondisi: gambar tampil, sedang dimuat, dan cadangan berupa huruf
/// pertama nama menu saat tautan kosong atau gambarnya gagal dimuat.
class MenuThumb extends StatelessWidget {
  const MenuThumb({
    required this.imageUrl,
    required this.initial,
    required this.background,
    required this.foreground,
    this.size = 44,
    super.key,
  });

  final String? imageUrl;
  final String initial;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _Huruf(
        initial: initial,
        background: background,
        foreground: foreground,
        size: size,
        radius: radius,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => _Kosong(size: size, radius: radius),
        errorWidget: (context, _, _) => _Huruf(
          initial: initial,
          background: background,
          foreground: foreground,
          size: size,
          radius: radius,
        ),
      ),
    );
  }
}

class _Huruf extends StatelessWidget {
  const _Huruf({
    required this.initial,
    required this.background,
    required this.foreground,
    required this.size,
    required this.radius,
  });

  final String initial;
  final Color background;
  final Color foreground;
  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: radius),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.size, required this.radius});

  final double size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: radius,
      ),
    );
  }
}