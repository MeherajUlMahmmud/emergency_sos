import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class Call extends StatelessWidget {
  const Call({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Savior: Call'),
          ),
          body: Center(
              child: Column(children: <Widget>[
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                child: const Text(
                  'Call',
                  style: TextStyle(fontSize: 15.0),
                ),
                onPressed: () async {
                  await FlutterPhoneDirectCaller.callNumber("111");
                },
              ),
            ),
          ]))),
    );
  }
}
