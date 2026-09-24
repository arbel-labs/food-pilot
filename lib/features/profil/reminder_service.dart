import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pengingat harian mencatat penjualan (PRD F-11).
///
/// Dijadwalkan dengan mode inexact supaya tidak perlu izin alarm presisi.
/// Telat beberapa menit tidak masalah untuk pengingat sore.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const int _notificationId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_zoneName()));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (_) {
      // Notifikasi gagal disiapkan bukan alasan aplikasi tidak boleh jalan.
      _ready = false;
    }
  }

  /// `false` berarti izin notifikasi ditolak atau plugin tidak siap.
  Future<bool> enable({required int hour, required int minute}) async {
    await init();
    if (!_ready) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return false;

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Sudah catat penjualan hari ini?',
      body: 'Butuh kurang dari 10 detik.',
      scheduledDate: _nextOccurrence(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pengingat_harian',
          'Pengingat harian',
          channelDescription: 'Pengingat mencatat penjualan tiap sore',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> disable() async {
    await init();
    if (!_ready) return;
    await _plugin.cancel(id: _notificationId);
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Indonesia tidak memakai DST, jadi zona bisa ditebak dari selisih jam.
  String _zoneName() {
    final offset = DateTime.now().timeZoneOffset.inHours;
    return switch (offset) {
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'Asia/Jakarta',
    };
  }
}
