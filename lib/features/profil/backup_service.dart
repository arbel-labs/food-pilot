import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/backup_repository.dart';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cadangan data ke Supabase (PRD F-14). Aplikasi tetap jalan penuh tanpa
/// login; ini hanya lapisan pengaman kalau HP hilang atau diganti.
class BackupService {
  BackupService(this._repository);

  final BackupRepository _repository;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp({required String email, required String password}) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<DateTime> backup() async {
    final user = currentUser;
    if (user == null) {
      throw const BackupException('Masuk dulu sebelum mencadangkan.');
    }
    final payload = await _repository.export();
    final updatedAt = DateTime.now().toUtc();
    await _client.from('backups').upsert(<String, Object?>{
      'user_id': user.id,
      'payload': payload,
      'updated_at': updatedAt.toIso8601String(),
    });
    return updatedAt.toLocal();
  }

  Future<void> restore() async {
    final user = currentUser;
    if (user == null) {
      throw const BackupException('Masuk dulu sebelum memulihkan.');
    }
    final row = await _client
        .from('backups')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) {
      throw const BackupException('Belum ada cadangan di server.');
    }
    final payload = row['payload'];
    if (payload is! Map<String, dynamic>) {
      throw const BackupException('Isi cadangan tidak bisa dibaca.');
    }
    await _repository.import(payload);
  }
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(backupRepositoryProvider)),
);
