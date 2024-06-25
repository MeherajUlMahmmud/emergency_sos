import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:flutter_sms/flutter_sms.dart';

List<String> recipients = ["111", "555"];

class GetLocation extends StatefulWidget {
  const GetLocation({super.key});

  @override
  Location createState() => Location();
}

class Location extends State<GetLocation> {
  var locationMessage = "";

  // void getCurrentLocation() async {
  //   var position = await Geolocator.getCurrentPosition(
  //     desiredAccuracy: LocationAccuracy.high,
  //   );
  //   var lastPosition = await Geolocator.getLastKnownPosition();
  //   print(lastPosition);
  //   var lat = position.latitude;
  //   var long = position.longitude;
  //   print("$lat , $long");

  //   setState(() {
  //     locationMessage = "Latitude : $lat , Longitude : $long";
  //   });
  // }

  void getCurrentLocation() async {
    LocationPermission permission;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      // Request the user to enable location services
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try to ask for permissions again
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // When we reach here, permissions are granted and we can fetch the location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    var lastPosition = await Geolocator.getLastKnownPosition();
    print(lastPosition);
    var lat = position.latitude;
    var long = position.longitude;
    print("$lat , $long");

    setState(() {
      locationMessage = "Latitude : $lat , Longitude : $long";
    });
  }

  @override
  void initState() {
    getCurrentLocation();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savior - GetLocation & Message'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 46.0,
              color: Colors.blue,
            ),
            const SizedBox(
              height: 10.0,
            ),
            const Text(
              "User Location",
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text("Position : $locationMessage"),
            TextButton(
              onPressed: () {
                getCurrentLocation();
              },

              // color: Colors.blue[800],
              child: const Text("Get Current Location",
                  style: TextStyle(
                    color: Colors.white,
                  )),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                child: const Text(
                  'Message',
                  style: TextStyle(fontSize: 15.0),
                ),
                // color: Colors.blueAccent,
                // textColor: Colors.white,
                onPressed: () {
                  _sendSMS(
                    "Please Help me! My Current Location: $locationMessage",
                    recipients,
                  );
                },
              ),
            ),
          ],
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
