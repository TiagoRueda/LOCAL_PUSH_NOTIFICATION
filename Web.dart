import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:isolate';
import 'dart:html' as web;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> configNotificationWeb(
    BuildContext context, List<String> uID) async {
  if (isWeb) {
    Map<String, bool> firstQueryMap = {};
    for (String id in uID) {
      firstQueryMap[id] = false;
      FirebaseFirestore.instance
          .collection('principal')
          .doc(id)
          .collection('evento_web')
          .doc('ultimo')
          .snapshots()
          .listen((DocumentSnapshot document) {
        if (document.exists) {
          final data = document.data() as Map<String, dynamic>;
          if (firstQueryMap[id] == true) {
            ElegantNotification.info(
              title: Text('${data['title'] ?? 'Sem Título'}'),
              description: Text('${data['body'] ?? 'Sem Corpo'}'),
              onDismiss: () {
                print('Fechar notificacao');
              },
              toastDuration: const Duration(milliseconds: 6000)
            ).show(context);
            showNotification('${data['title'] ?? 'Sem Título'}',
                '${data['body'] ?? 'Sem Corpo'}');  
            AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
            _assetsAudioPlayer.open(
              Audio.network(
                  'https://firebasestorage.googleapis.com/v0/b/?/o/soundnotification%2Fnotification_sound.mp3?'),
            );
          } else {
            firstQueryMap[id] = true;
          }
        }
      });
    }
  }
}

Future<void> showNotification(String title, String body) async {
  var permission = web.Notification.permission;
  if (permission != 'granted') {
    permission = await web.Notification.requestPermission();
  }
  if (permission == 'granted') {
    web.Notification(title, body: body);
  }
}
