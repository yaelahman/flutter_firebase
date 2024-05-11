import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  final apiUrl = "http://192.168.0.116:8000/api";
  final firebaseMessaging = FirebaseMessaging.instance;

  final androidChannel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.defaultImportance);

  final localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Payload: ${message.data}");
    // return message;
  }

  Future<void> initNotifications() async {
    await firebaseMessaging.requestPermission();
    final FCMToken = await firebaseMessaging.getToken();
    print('Token: $FCMToken');
    storeToken(FCMToken);
    // FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    initPushNotifications();
    initLocalNotifications();
  }

  Future<void> initPushNotifications() async {
    await firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
              androidChannel.id, androidChannel.name,
              channelDescription: androidChannel.description),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android);

    await localNotifications.initialize(settings);
  }

  final dio = new Dio();

  storeToken(token) async {
    Response response = await dio
        .post('${apiUrl}/store-token', data: {'token': token.toString()});

    print("Store Token : " + response.toString());
  }

  sendMessage(token, message) async {
    Response response = await dio.post('${apiUrl}/send-message',
        data: {'token': token.toString(), 'message': message.toString()});

    print("Store Token : " + response.toString());
  }

  listToken(setTokens) async {
    final response = await dio.get('${apiUrl}/list-token');

    setTokens(response.data['data']);
  }
}
