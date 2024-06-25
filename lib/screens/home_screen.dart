import 'package:flutter/material.dart';
import 'getlocation.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
//import 'call.dart';
//import 'message.dart';
//import 'livelocationtracking.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  void get context {}
  void _handleCommand(Map<String, dynamic> command) {
    switch (command["command"]) {
      case "call":
        FlutterPhoneDirectCaller.callNumber("111");
        break;

      case "location":
        break;
      case "current location":
        break;
      case "message":
        break;
      case "live location":
        break;

      default:
        debugPrint("Unknown command");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Savior'),
        ),
        body: Center(
          child: SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                /* Container(
              margin: EdgeInsets.all(15),
              child: FlatButton(
                child: Text(
                  'Message',
                  style: TextStyle(fontSize: 15.0),
                ),
                color: Colors.blueAccent,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Message()),
                  );
                },
              ),
            ),*/
                Container(
                  margin: const EdgeInsets.all(15),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await FlutterPhoneDirectCaller.callNumber("111");
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call),
                        SizedBox(width: 10),
                        Text(
                          'Call',
                          style: TextStyle(fontSize: 15.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(15),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message),
                        SizedBox(width: 10),
                        Text(
                          'Get Location & Send Message',
                          style: TextStyle(fontSize: 15.0),
                        ),
                      ],
                    ),
                    // color: Colors.blueAccent,
                    // textColor: Colors.white,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GetLocation()),
                      );
                    },
                  ),
                ),
                /* Container(
                    margin: EdgeInsets.all(15),
                    child: FlatButton(
                      child: Text(
                        'Live Location Tracking',
                        style: TextStyle(fontSize: 15.0),
                      ),
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LiveLocationTracking()),
                        );
                      },
                    ),
                  ),*/

                /*FloatingActionButton.extended(
              onPressed: () {},
              icon: Icon(Icons.save),
              label: Text("Notifications"),
            ),*/
                /*FloatingActionButton(
                    child: Icon(Icons.notifications),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    onPressed: () => {},
                  ),*/
              ],
            ),
          ),
        ),
      ),
    );
  }
}
