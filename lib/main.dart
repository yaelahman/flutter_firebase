import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/api/firebase_api.dart';
import 'package:flutter_application_2/model/push_notification.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase.initializeApp();
  print("OKE");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final apnsToken = await firebaseMessaging.getAPNSToken();
  await firebaseMessaging.requestPermission();
  final FCMToken = await firebaseMessaging.getToken();

  print('Token: $FCMToken');
  print('APNS: $apnsToken');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FirebaseMessaging _messaging;
  late int _totalNotifications;
  PushNotification? _notificationInfo;
  final messageController = TextEditingController();
  String? token = '';
  String? selectedToken;
  String? choice;
  List listToken = [];
  Map<dynamic, dynamic> challenge = {};
  bool isLoading = false;
  bool isChallenger = false;
  final List<int> numbers = [1, 2, 3, 4, 5];
  var challengeResult = null;
  var answerResult = null;

  setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  checkOddEven(number) {
    if (number % 2 == 0) {
      return "EVEN";
    } else {
      return "ODD";
    }
  }

  void checkResult(message) {
    setState(() {
      if (message.data['type'] == 'send') {
        isLoading = false;
        challengeResult = {
          'id': message.data['key'],
          'message': message.notification?.body,
        };
      }

      if (message.data['type'] == 'answer') {
        isLoading = false;
        var data = jsonDecode(message.data['data']);
        var sumResult = (data['challenger_number']) + (data['opponent_number']);
        answerResult = {
          'id': message.data['key'],
          'data': data,
          'message': message.notification?.body,
          'you': data['challenger_type'],
          'winner': checkOddEven(sumResult) == data['challenger_type'],
          'result':
              "You ${data['challenger_number']} + Opponent ${data['opponent_number']} = ${sumResult.toString()}"
        };
      }

      if (message.data['type'] == 'message') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("INFO"),
              content: Text(message.notification.body),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  void registerNotification() async {
    // await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform);
    _messaging = FirebaseMessaging.instance;

    // await FirebaseApi().initNotifications();
    final FCMToken = await _messaging.getToken();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("FCMToken", FCMToken.toString());
    await FirebaseApi().storeToken(FCMToken);
    print("TOKEN => " + FCMToken.toString());
    setState(() {
      token = FCMToken;
    });
    await FirebaseApi().listToken(setTokens, token);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print(
            'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');

        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );

        checkResult(message);

        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });

        if (_notificationInfo != null) {
          // For displaying the notification as an overlay
          showSimpleNotification(
            Text(_notificationInfo!.title!),
            leading: NotificationBadge(totalNotifications: _totalNotifications),
            subtitle: Text(_notificationInfo!.body!),
            background: Colors.cyan.shade700,
            duration: Duration(seconds: 2),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) async {
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data['title'],
          dataBody: message.data['body'],
        );
        print(
            'Message from out of application title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
        checkResult(message);
        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  setTokens(tokens) {
    setState(() {
      listToken = tokens;
    });
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    // await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
        dataTitle: initialMessage.data['title'],
        dataBody: initialMessage.data['body'],
      );

      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });
    }
  }

  void _showAlertDialog(BuildContext context, value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("INFO"),
          content: Text(value),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  handleChoice(BuildContext context, String? value) {
    print(selectedToken);
    if (selectedToken == null) {
      _showAlertDialog(context, "PLEASE SELECT OPPONENT");
      return;
    }

    setState(() {
      choice = value;
    });
  }

  handleSendChallenge(value) async {
    setIsLoading();
    setState(() {
      isChallenger = true;
    });
    await FirebaseApi().sendChallenge(selectedToken, choice, value);
  }

  handleAnswerChallenge(value) async {
    setIsLoading();

    var data =
        await FirebaseApi().answerChallenge(challengeResult['id'], value);

    var sumResult = data['challenger_number'] + data['opponent_number'];

    setState(() {
      challengeResult['isAnswer'] = true;
      challengeResult['you'] = data['opponent_type'];
      challengeResult['winner'] =
          checkOddEven(sumResult) == data['opponent_type'];
      challengeResult['result'] =
          "Challenger ${data['challenger_number']} + You ${data['opponent_number']} = ${sumResult.toString()}";
    });
  }

  @override
  void initState() {
    _totalNotifications = 0;
    registerNotification();
    checkForInitialMessage();

    // For handling notification when the app is in background
    // but not terminated

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ODD EVEN GAME'),
        // brightness: Brightness.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Text("Choose an Opponent"),
                  DropdownButton(
                    isExpanded: true,
                    value: selectedToken,
                    onChanged: ((newValue) => {
                          setState(() {
                            answerResult = null;
                            isLoading = false;
                            isChallenger = false;
                            selectedToken = newValue.toString();
                            choice = null;
                          })
                        }),
                    items: listToken.map<DropdownMenuItem>((value) {
                      return DropdownMenuItem(
                        value: value['fcm_token'] ?? '',
                        child: Text((value['name'] ?? '').toString()),
                      );
                    }).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: (() {
                          if (!isLoading && answerResult == null)
                            handleChoice(context, "ODD");
                        }),
                        child: Container(
                          color: choice != null
                              ? const Color.fromARGB(255, 233, 148, 142)
                              : Colors.red,
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            "ODD",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: (() {
                          if (!isLoading && answerResult == null)
                            handleChoice(context, "EVEN");
                        }),
                        child: Container(
                          color: choice != null
                              ? const Color.fromARGB(255, 122, 176, 124)
                              : Colors.green,
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            "EVEN",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  choice != null
                      ? Column(
                          children: [
                            const Text("SELECT NUMBER"),
                            ItemList(
                              isLoading: isLoading,
                              onItemSelected: (value) {
                                if (!isLoading && answerResult == null)
                                  handleSendChallenge(value);
                              },
                            ),
                          ],
                        )
                      : Container(),
                  isChallenger
                      ? Column(
                          children: [
                            const Text("Waiting for Opponent"),
                            answerResult != null &&
                                    answerResult['message'] != null
                                ? Text(answerResult['message'])
                                : Container(),
                            answerResult != null &&
                                    answerResult['message'] != null
                                ? const Text("Matching Result")
                                : Container(),
                            answerResult != null &&
                                    answerResult['result'] != null
                                ? Text(answerResult['result'])
                                : Container(),
                            answerResult != null && answerResult['you'] != null
                                ? Text("You're ${answerResult['you']}")
                                : Container(),
                            answerResult != null &&
                                    answerResult['winner'] != null &&
                                    answerResult['winner']
                                ? const Text("You're WINNER")
                                : answerResult != null &&
                                        answerResult['winner'] != null
                                    ? const Text("You're LOSER")
                                    : Container(),
                          ],
                        )
                      : Container(),
                  const SizedBox(
                    height: 20,
                  ),
                  const Divider(
                    height: 2,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text("Waiting for Challenger"),
                  const SizedBox(
                    height: 10,
                  ),
                  challengeResult != null
                      ? Column(
                          children: [
                            Text(challengeResult['message']),
                            const SizedBox(
                              height: 10,
                            ),
                            const Text("SELECT NUMBER"),
                            ItemList(
                              isLoading: isLoading,
                              onItemSelected: (value) {
                                handleAnswerChallenge(value);
                              },
                            ),
                            challengeResult['isAnswer'] != null
                                ? const Text("Matching Result")
                                : Container(),
                            challengeResult != null &&
                                    challengeResult['result'] != null
                                ? Text(challengeResult['result'])
                                : Container(),
                            challengeResult['you'] != null
                                ? Text("You're ${challengeResult['you']}")
                                : Container(),
                            challengeResult != null &&
                                    challengeResult['winner'] != null &&
                                    challengeResult['winner']
                                ? const Text("You're WINNER")
                                : challengeResult != null &&
                                        challengeResult['winner'] != null
                                    ? const Text("You're LOSER")
                                    : Container(),
                          ],
                        )
                      : Container(),
                  const Divider(
                    height: 2,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text("FILL MESSAGE"),
                  TextField(
                    controller: messageController,
                    // keyboardType: const TextInputType.numberWithOptions(
                    //     decimal: false), // Allow decimal numbers
                    // inputFormatters: <TextInputFormatter>[
                    //   FilteringTextInputFormatter.digitsOnly // Allow only digits
                    // ],
                  ),
                  TextButton(
                    onPressed: (() {
                      FirebaseApi().sendMessage(
                          selectedToken.toString(), messageController.text);
                    }),
                    child: Container(
                      color: Colors.blue,
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "SEND",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  final List<int> items = [1, 2, 3, 4, 5];
  final Function(int) onItemSelected;
  final bool isLoading;
  ItemList({required this.isLoading, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((int item) {
          return TextButton(
            onPressed: (() {
              if (!isLoading) onItemSelected(item);
            }),
            child: Container(
              color: isLoading
                  ? const Color.fromARGB(255, 127, 125, 103)
                  : const Color.fromARGB(255, 141, 130, 24),
              padding: const EdgeInsets.all(10),
              child: Text(
                item.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }).toList(), // Convert Iterable to List<Widget>
      ),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  final int totalNotifications;

  const NotificationBadge({required this.totalNotifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: new BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$totalNotifications',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
