/// Konfigurasi dari `--dart-define-from-file=env.json`.
///
/// Kalau kosong, aplikasi tetap jalan penuh tanpa internet: konsultan AI
/// memakai mode demo dan fitur akun menampilkan petunjuk setup.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
