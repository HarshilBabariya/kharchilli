import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'l10n.dart';

/// Each kind of notification has its own Android channel and its own household sound.
enum Channel {
  nudges('channel_nudges', 'cooker_whistle'),
  bills('channel_bills', 'doorbell'),
  autolog('channel_autolog', 'debit_ting'),
  budgetWarn('channel_budget_warn', 'microwave'),
  budgetOver('channel_budget_over', 'card_declined'),
  badges('channel_badges', 'piggy_bank'),
  levels('channel_levels', 'cash_register'),
  streakRisk('channel_streak_risk', 'clock'),
  streakWin('channel_streak_win', 'stove'),
  festival('channel_group_festivals', 'diwali');

  const Channel(this.labelKey, this.sound);
  final String labelKey;
  final String sound;
}

class NotificationIds {
  static const streakRisk = 900001;
  static const festival = 900010;
  static const comeback = 900020;
  static const weekly = 900030;
  static int _instant = 910000;
  static int nextInstant() => _instant++;
  static int reminder(int reminderId, int slot) => reminderId * 10 + slot;
}

class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String? pendingRoute;
  static final routeTaps = ValueNotifier<int>(0);

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_gharcha'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (response) => open(response.payload),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) pendingRoute = launch!.notificationResponse?.payload;
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  /// Asks the shell to show [route]; used by notification taps and home-screen shortcuts.
  static void open(String? route) {
    if (route == null || route.isEmpty) return;
    pendingRoute = route;
    routeTaps.value++;
  }

  static Future<void> requestPermission() async {
    if (!_ready) return;
    if (Platform.isAndroid) {
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static NotificationDetails _details(Channel channel, String? sound, String body) {
    final name = sound ?? channel.sound;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        sound == null ? channel.name : '${channel.name}_$sound',
        tr(channel.labelKey),
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('sfx_$name'),
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  static Future<void> show(Channel channel, String title, String body, {String route = '', String? sound}) async {
    if (!_ready) return;
    try {
      await _plugin.show(NotificationIds.nextInstant(), title, body, _details(channel, sound, body), payload: route);
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  static Future<void> schedule(int id, Channel channel, DateTime when, String title, String body, {String route = '', String? sound, DateTimeComponents? repeat}) async {
    if (!_ready || (repeat == null && !when.isAfter(DateTime.now()))) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(channel, sound, body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeat,
        payload: route,
      );
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}

class Sfx {
  static bool enabled = true;
  static final _player = AudioPlayer();

  static Future<void> play(String name) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/$name.mp3'));
    } catch (e) {
      debugPrint('Sound failed: $e');
    }
  }
}
