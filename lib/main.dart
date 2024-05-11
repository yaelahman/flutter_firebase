import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/api/firebase_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();

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
  List listToken = [];

  @override
  initState() {
    super.initState();

    init();
  }

  Future<void> init() async {
    await FirebaseApi().listToken(setTokens);
  }

  setTokens(tokens) {
    print(tokens.toString());
    setState(() {
      listToken = tokens;
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    Text("Message"),
                    TextField(
                      controller: messageController,
                    ),
                    TextButton(
                      onPressed: (() {
                        print("messageController " + messageController.text);
                        print("Token " + selectedToken.toString());
                        FirebaseApi().sendMessage(
                            selectedToken.toString(), messageController.text);
                      }),
                      child: Container(
                        color: Colors.blue,
                        padding: EdgeInsets.all(10),
                        child: const Text(
                          "SEND",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
