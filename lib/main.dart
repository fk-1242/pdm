import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:quiver/iterables.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  MyState createState() => MyState();
}

enum _State {
  FETCHED,
  PERMISSION_DENIED,
  NOT_FETCHED
}

class MyState extends State<MyApp> {
  DateTime now = new DateTime.now();
  DateTime startDate = new DateTime.now();
  DateTime endDate = new DateTime.now();
  int days = 0;
  _State _state = _State.NOT_FETCHED;
  final Map<int, dynamic> stepsData = {};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pedometer'),
        ),
        body: Center(
          child: childContent(),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: fetchHealthData,
            backgroundColor: Colors.pinkAccent,
            child: Icon(Icons.download_sharp)
        ),
      ),
    );
  }

  Widget childContent() {
    if(_state == _State.FETCHED){
      print('fetching completed');
      return ListView.builder(
        reverse: true,
        itemCount: days + 1,
        itemBuilder: (_, index) {
          var p = stepsData[index];
          if(p[1] == 1){
            return ListTile(
              title: Text("${p[1]} step"),
              trailing: Text('${p[0].year}/${p[0].month}/${p[0].day}'),
            );
          }
          return ListTile(
            title: Text("${p[1]} steps"),
            trailing: Text('${p[0].year}/${p[0].month}/${p[0].day}'),
          );
        },
      );
    }else if(_state == _State.PERMISSION_DENIED){
      print('permission denied');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Permission denied'),
          Text('Permit steps-reading and try again'),
        ],
      );
    }

    return Text('Press the button to fetch data');
  }

  Future fetchHealthData() async {
    HealthFactory health = HealthFactory();
    List<HealthDataType> types = [HealthDataType.STEPS];
    List<HealthDataPoint> healthData = [];

    startDate = new DateTime(now.year, now.month - 1, now.day);
    endDate   = new DateTime(now.year, now.month, now.day + 1);
    days = endDate.difference(startDate).inDays;

    await health.requestAuthorization(types);

    try {
      healthData =
      await health.getHealthDataFromTypes(startDate, endDate, types);
    } catch (e) {
      setState(() {_state = _State.PERMISSION_DENIED;});
      _state = _State.PERMISSION_DENIED;
      return;
    }

    if (healthData.length == 0) {
      setState(() {_state = _State.PERMISSION_DENIED;});
      return;
    }

    for (final i in range(days + 1)) {
      stepsData[i.toInt()]
      = [
        new DateTime(
            startDate.year, startDate.month, startDate.day + i.toInt()),
        0
      ];
    }

    healthData.forEach((x) {
      DateTime d
      = new DateTime(x.dateFrom.year, x.dateFrom.month, x.dateFrom.day);
      int i = d
          .difference(startDate)
          .inDays;
      int newSteps = stepsData[i][1] + x.value.round();
      stepsData[i] = [d, newSteps];
    });

    setState(() {_state = _State.FETCHED;});
  }
}
