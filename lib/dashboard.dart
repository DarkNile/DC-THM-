import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'circle_progress.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  bool isLoading = false;
  double temp;
  double humidity;
  String restart = 'restart';
  FirebaseDatabase database = new FirebaseDatabase();
  AnimationController progressController;
  Animation<double> tempAnimation;
  Animation<double> humidityAnimation;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  //Timer timer;

  Future<void> showNotification(String payload) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description', icon: '@mipmap/ic_launcher',
        importance: Importance.Max, priority: Priority.High, ticker: 'Data Center Warning');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Data Center Warning',
        'Temperature = ${temp.toStringAsFixed(2)}, Humidity = ${humidity.toStringAsFixed(2)}',
        platformChannelSpecifics,
        payload: 'Data Center Warning'
    );
  }

  // Show a notification every minute with the first appearance happening a minute after invoking the method
//  Future<void> repeatNotification(String payload) async {
//    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
//        'repeating channel id',
//        'repeating channel name',
//        'repeating description',
//        icon: '@mipmap/ic_launcher',
//        importance: Importance.Max,
//        priority: Priority.High,
//        ticker: 'Data Center Warning');
//    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
//    var platformChannelSpecifics = NotificationDetails(
//        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
//    await flutterLocalNotificationsPlugin.periodicallyShow(
//        0,
//        'Data Center Warning',
//        'Temperature = ${temp.toStringAsFixed(2)}, Humidity = ${humidity.toStringAsFixed(2)}',
//        RepeatInterval.EveryMinute,
//        platformChannelSpecifics,
//        payload: payload);
//  }

  @override
  void initState() {
    super.initState();
    //Getting Temperature & Humidity Values from Firebase
    database.reference().child('DTC').onValue.listen((Event event) {
      setState(() {
        temp = event.snapshot.value['Temperature'];
        humidity = event.snapshot.value['Humidity'];
      });
      if (temp != null && humidity != null)
        _dashboardInit(temp, humidity);
      else
        print('No Connection with Firebase');
    });

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSettings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onSelectNotification: showNotification
    );
  }

  _dashboardInit(double temp, double humidity) {
    isLoading = true;
    progressController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 5000)); //5s
    tempAnimation =
        Tween<double>(begin: temp, end: temp).animate(progressController)
          ..addListener(() {
            setState(() {});
          });
    humidityAnimation = Tween<double>(begin: humidity, end: humidity)
        .animate(progressController)
          ..addListener(() {
            setState(() {});
          });
    progressController.forward();

    if (temp >= 25 || humidity >= 50) {
      showNotification('Data Center Warning');
      //timer = Timer.periodic(Duration(seconds: 30), (Timer t) => showNotification('Data Center Warning'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DC Room Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
//        leading: Builder(
//          builder: (BuildContext context) {
//            return IconButton(
//                icon: Icon(Icons.refresh),
//                onPressed: () async {
//                  database
//                      .reference()
//                      .child('DTC/Restart')
//                      .set({'Restart': '$restart'});
//                  final snackBar = SnackBar(
//                    content: Text('Restarting...',
//                        textAlign: TextAlign.center,
//                        style: TextStyle(
//                          fontSize: 16,
//                        )),
//                  );
//                  Scaffold.of(context).showSnackBar(snackBar);
//                  await new Future.delayed(const Duration(seconds: 10));
//                  database.reference().child('DTC/Restart').remove();
//                });
//          },
//        ),
      ),
      body: Center(
        child: isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CustomPaint(
                    foregroundPainter:
                        CircleProgress(tempAnimation.value, true),
                    child: Container(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Temperature'),
                            Text(
                              '${tempAnimation.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 45, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '°C',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    foregroundPainter:
                        CircleProgress(humidityAnimation.value, false),
                    child: Container(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Humidity'),
                            Text(
                              '${humidityAnimation.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 45, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '%',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : CircularProgressIndicator(
                backgroundColor: Colors.deepPurple,
              ),
      ),
    );
  }
}
