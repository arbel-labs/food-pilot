import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// ID dibuat di perangkat (syarat offline-first), bukan oleh server.
String newId() => _uuid.v4();

/// Timestamp epoch milidetik, sesuai aturan tipe di CONTEXT.md bagian 3.
int nowMillis() => DateTime.now().millisecondsSinceEpoch;
