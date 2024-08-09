import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

late AndroidNotificationChannel channel;
bool isFlutterLocalNotificationsInitialized = false;
const String isolateName = 'isolate';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackground(RemoteMessage message) async {
}

void sendNotification(String? title, String? body) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(
    presentSound: true,
    presentAlert: true,
    presentBadge: true,
  );

  flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    NotificationDetails(
      iOS: iosNotificationDetails,
    ),
  );
}

// only test
void showSimpleNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  if (overlay == null) {
    return;
  }

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60.0,
      left: 0.0,
      right: 0.0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          margin: EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.split('\n')[0], 
                style: TextStyle(color: Colors.black, fontSize: 16.0),
              ),
              SizedBox(height: 4.0),
              Text(
                message.split('\n').length > 1
                    ? message.split('\n')[1]
                    : '',
                style: TextStyle(color: Colors.black, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(Duration(seconds: 5), () {
    overlayEntry.remove();
  });
}

Future<void> configNotificationiOS(BuildContext context) async {
  if (isiOS) {
    requestPhonePermission();
    await ClearAllNotifications.clear();
    await Alarm.init();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensagem recebida: $message");
      showSimpleNotification(context,
          '${message.notification?.title ?? 'Sem Título'}\n
           ${message.notification?.body ?? 'Sem Corpo'}');
      sendNotification(message.notification?.title, message.notification?.body);     
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackground);
  }
}

Future<void> requestPhonePermission() async {
  var status = await Permission.phone.status;
  if (!status.isGranted) {
    status = await Permission.phone.request();
    if (!status.isGranted) {}
  }
}