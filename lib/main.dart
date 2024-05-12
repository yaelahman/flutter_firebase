import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/api/firebase_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final fcmToken = await FirebaseApi().initNotifications();

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
  int _counter = 0;

  final messageController = TextEditingController();
  String? selectedToken;
  String? FCMToken;
  List listToken = [];
  Map<dynamic, dynamic> challenge = {};

  @override
  initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("Notification opened from terminated state or background");
      print("Notification data: ${message.data}");
      Map<String, dynamic> userData = message.data;

      print("GET CHALLENGE NOW " + challenge.length.toString());
      await FirebaseApi()
          .getChallenge(userData['key'].toString(), setChallenge);
      // Handle the notification data
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("FCMToken");
    await FirebaseApi().listToken(setTokens, token);

    setState(() {
      FCMToken = prefs.getString(
        "FCMToken",
      );
    });
  }

  setChallenge(value) {
    // print("SET CHALLENGE " + value.toString());
    setState(() {
      // print("SET CHALLENGE  1" + challenge.toString());
      challenge = value;
      if (value.isNotEmpty) selectedToken = value['token'];
      // print("SET CHALLENGE  2" + challenge.toString());
    });
  }

  setTokens(tokens) {
    setState(() {
      listToken = tokens;
    });
  }

  bool isOdd(int number) {
    return number % 2 != 0;
  }

  bool isEven(int number) {
    return number % 2 == 0;
  }

  void handleOddEven(context, type) {
    bool result = false;
    if (type == "ODD") {
      result = isOdd(int.parse(challenge['number'].toString()));
    } else {
      result = isEven(int.parse(challenge['number'].toString()));
    }

    setChallenge({});
    _showAlertDialogResult(context, type, result);
  }

  void _showAlertDialogResult(BuildContext context, type, result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(type),
          content:
              result ? Text('WOAAA YOU WON THIS GAME') : Text("SORRY YOU LOST"),
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

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Challenge has been sended'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  children: [
                    Text("Device"),
                    DropdownButton(
                      isExpanded: true,
                      value: selectedToken,
                      onChanged: ((newValue) => {
                            setState(() {
                              selectedToken = newValue.toString();
                            })
                          }),
                      items: listToken.map<DropdownMenuItem>((value) {
                        return DropdownMenuItem(
                          value: value ?? '',
                          child:
                              Text((value ?? '').toString().substring(0, 10)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                        "FILL NUMBER TO MAKE A CHALLENGE TO YOUR DEVICE SELECTED"),
                    TextField(
                      controller: messageController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: false), // Allow decimal numbers
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter
                            .digitsOnly // Allow only digits
                      ],
                    ),
                    TextButton(
                      onPressed: (() {
                        FirebaseApi().sendMessage(
                            selectedToken.toString(), messageController.text);
                        _showAlertDialog(context);
                      }),
                      child: Container(
                        color: Colors.blue,
                        padding: EdgeInsets.all(10),
                        child: const Text(
                          "SEND",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    challenge.isNotEmpty
                        ? Column(
                            children: [
                              const Text(
                                  "CHOOSE ODD OR EVEN TO WIN THIS GAME "),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: (() {
                                      handleOddEven(context, "ODD");
                                    }),
                                    child: Container(
                                      color: Colors.red,
                                      padding: EdgeInsets.all(10),
                                      child: const Text(
                                        "ODD",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: (() {
                                      handleOddEven(context, "EVEN");
                                    }),
                                    child: Container(
                                      color: Colors.green,
                                      padding: EdgeInsets.all(10),
                                      child: const Text(
                                        "EVEN",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Container()
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
