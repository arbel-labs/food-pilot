import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/business_repository.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/main.dart';

void main() {
  testWidgets('Beranda tampil setelah data usaha ada', (tester) async {
    // closeStreamsSynchronously mencegah timer drift tertinggal di test.
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    await tester.runAsync(
      () => BusinessRepository(
        database,
      ).save(name: 'Warung Uji', type: BusinessType.kuliner),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          databaseProvider.overrideWithValue(database),
          initialLocationProvider.overrideWithValue('/beranda'),
        ],
        child: const FoodPilotApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Laba bersih hari ini'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(database.close);
  });
}
