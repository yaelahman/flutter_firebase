import 'dart:convert';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseApi {
  final apiUrl = "https://example.manzcode.com/api";
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

  initNotifications() async {
    await firebaseMessaging.requestPermission();
    final FCMToken = await firebaseMessaging.getToken();
    print('Token: $FCMToken');
    storeToken(FCMToken);
    // FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    initPushNotifications();
    initLocalNotifications();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("FCMToken", FCMToken.toString());

    return FCMToken.toString();
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
      // print("GET NOTIFICATION => " + jsonEncode(message.toMap()).toString());

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
    String deviceName = await _getDeviceName();
    try {
      Response response = await dio.post('${apiUrl}/store-token',
          data: {'token': token.toString(), 'name': deviceName});
      print("Store Token : " + response.toString());
    } catch (e) {
      print("Store Token Error " + e.toString());
    }
  }

  _getDeviceName() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceName;
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';

      if (deviceName.isNotEmpty) return deviceName;

      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.utsname.machine;
      if (deviceName.isNotEmpty) return deviceName;
    } catch (e) {
      return "iPhone";
    }
  }

  sendMessage(token, message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? fromToken = prefs.getString("FCMToken");

    Response response = await dio.post('${apiUrl}/send-message', data: {
      'token': token.toString(),
      'message': message.toString(),
      'from_token': fromToken
    });

    print("Store Token : " + response.toString());
  }

  getChallenge(id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? fromToken = prefs.getString("FCMToken");
    print("ENDPOINT = ${apiUrl}/get-challenge/${id}");

    Response response = await dio
        .post('${apiUrl}/get-challenge/${id}', data: {'token': fromToken});

    // setChallenge(response.data['data']);
    print("GET CHALLENGE : " + response.toString());
  }

  sendChallenge(token, type, number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? fromToken = prefs.getString("FCMToken");

    Response response = await dio.post('${apiUrl}/send-challenge', data: {
      'token': fromToken,
      'selectedToken': token,
      'challeger_number': number,
      'challeger_type': type,
    });
    print("SEND CHALLENGE : " + response.toString());
  }

  answerChallenge(id, number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? fromToken = prefs.getString("FCMToken");

    Response response = await dio.post('${apiUrl}/answer-challenge', data: {
      'token': fromToken,
      'id': id,
      'opponent_number': number,
    });
    return response.data['data'];
  }

  listToken(setTokens, token) async {
    final response =
        await dio.get('${apiUrl}/list-token?token=' + token.toString());
    print("LISTTOKEN => " + response.data.toString());

    setTokens(response.data['data']);
  }
}
