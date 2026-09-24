import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/tokens.dart';

/// Warna semantik aplikasi sebagai `ThemeExtension` (CONTEXT.md bagian 7).
///
/// Padanannya di web: variable CSS tambahan seperti `--success` yang tidak
/// disediakan shadcn. Material tidak punya peran "untung" atau "laku tapi
/// tipis", jadi warnanya disimpan di sini dan ikut berganti di mode gelap.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.onInk,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.accent,
  });

  static const AppColors light = AppColors(
    ink: LightTokens.ink,
    onInk: LightTokens.onInk,
    background: LightTokens.background,
    surface: LightTokens.surface,
    border: LightTokens.border,
    text: LightTokens.text,
    textMuted: LightTokens.textMuted,
    success: LightTokens.success,
    onSuccess: LightTokens.onSuccess,
    warning: LightTokens.warning,
    onWarning: LightTokens.onWarning,
    danger: LightTokens.danger,
    onDanger: LightTokens.onDanger,
    accent: LightTokens.accent,
  );

  static const AppColors dark = AppColors(
    ink: DarkTokens.ink,
    onInk: DarkTokens.onInk,
    background: DarkTokens.background,
    surface: DarkTokens.surface,
    border: DarkTokens.border,
    text: DarkTokens.text,
    textMuted: DarkTokens.textMuted,
    success: DarkTokens.success,
    onSuccess: DarkTokens.onSuccess,
    warning: DarkTokens.warning,
    onWarning: DarkTokens.onWarning,
    danger: DarkTokens.danger,
    onDanger: DarkTokens.onDanger,
    accent: DarkTokens.accent,
  );

  final Color ink;
  final Color onInk;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color accent;

  @override
  AppColors copyWith({
    Color? ink,
    Color? onInk,
    Color? background,
    Color? surface,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? accent,
  }) {
    return AppColors(
      ink: ink ?? this.ink,
      onInk: onInk ?? this.onInk,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      accent: accent ?? this.accent,
    );
  }

  /// Dipakai Flutter untuk menganimasikan pergantian mode terang dan gelap.
  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// `context.colors` sama dengan `Theme.of(context).extension<AppColors>()!`,
/// hanya lebih pendek. Mirip custom hook `useColors()` di React.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
