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

Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }

  channel = const AndroidNotificationChannel(
    'pushNotification',
    'onMessage',
    description: 'Notificacoes com app ativo',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  isFlutterLocalNotificationsInitialized = true;
}

void sendNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_launcher_background', //mipmap
          color: Color.fromARGB(255, 11, 82, 151),
        ),
      ),
    );
  }
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

Future<void> configNotificationAndroid(BuildContext context) async {
  if (isAndroid) {
    requestPhonePermission();
    setupFlutterNotifications();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Mensagem recebida: $message");
      showSimpleNotification(context,
          '${message.notification?.title ?? 'Sem Título'}\n
           ${message.notification?.body ?? 'Sem Corpo'}');
      sendNotification(message);
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