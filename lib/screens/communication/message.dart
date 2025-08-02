import 'package:flutter/material.dart';
// import 'package:flutter_sms/flutter_sms.dart';

List<String> recipients = ["111", "01787653539"];

class Message extends StatelessWidget {
  const Message({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Savior: Send Message"),
      ),
      body: Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              // color: Theme.of(context).accentColor,
              // padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                "Send SMS",
                // style: Theme.of(context).accentTextTheme.button,
              ),
              onPressed: () {
                _sendSMS("Please Help me! My Current Location:", recipients);
              },
            ),
          ),
        ),
      ),
    );
  }
}

void _sendSMS(String message, List<String> recipients) async {
  // String result = await sendSMS(message: message, recipients: recipients)
  //     .catchError((onError) {
  //   print(onError);
  // });
  print("result");
}
