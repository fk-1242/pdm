import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:quiver/iterables.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTH_NOT_GRANTED
}

class _MyAppState extends State<MyApp> {
  List<HealthDataPoint> _healthDataList = [];
  final Map<int, dynamic> dateStepsMapList = {};
  AppState _state = AppState.DATA_NOT_FETCHED;
  int days = 0;

  @override
  void initState() {
    super.initState();
  }

  Future fetchData() async {
    DateTime now = new DateTime.now();
    DateTime startDate = new DateTime(now.year, now.month - 1, now.day);
    DateTime endDate   = now;
    days = endDate.difference(startDate).inDays;

    HealthFactory health = HealthFactory();

    List<HealthDataType> types = [
      HealthDataType.STEPS,
    ];

    setState(() => _state = AppState.FETCHING_DATA);
    bool accessWasGranted = await health.requestAuthorization(types);

    if (accessWasGranted) {
      try {
        List<HealthDataPoint> healthData =
        await health.getHealthDataFromTypes(startDate, endDate, types);
        _healthDataList.addAll(healthData);
      } catch (e) {
        print("[Exception] getHealthDataFromTypes: $e");
      }

      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      for(final i in range(days + 1)) {
        dateStepsMapList[i.toInt()] = [new DateTime(startDate.year, startDate.month, startDate.day + i.toInt()), 0];
      }

      _healthDataList.forEach((x) {
        DateTime d = new DateTime(x.dateFrom.year, x.dateFrom.month, x.dateFrom.day);
        int i = d.difference(startDate).inDays;
        int newSteps = dateStepsMapList[i][1] + x.value.round();
        dateStepsMapList[i] = [d, newSteps];
      });

      setState(() {
        _state =
        _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
      });
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              strokeWidth: 10,
            )),
        Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return ListView.builder(
        reverse: true,
        itemCount: days + 1,
        itemBuilder: (_, index) {
          var p = dateStepsMapList[index];
          return ListTile(
            title: Text("${p[1]} step(s)"),
            trailing: Text('${p[0].year}/${p[0].month}/${p[0].day}'),
          );
        });
  }

  Widget _contentNoData() {
    return Text('No Data');
  }

  Widget _contentNotFetched() {
    return Text('Press the download button to fetch data');
  }

  Widget _authorizationNotGranted() {
    return Text('''Authorization not given.
        For Android please check your OAUTH2 client ID is correct in Google Developer Console.
         For iOS check your permissions in Apple Health.''');
  }

  Widget _content() {
    if (_state == AppState.DATA_READY)
      return _contentDataReady();
    else if (_state == AppState.NO_DATA)
      return _contentNoData();
    else if (_state == AppState.FETCHING_DATA)
      return _contentFetchingData();
    else if (_state == AppState.AUTH_NOT_GRANTED)
      return _authorizationNotGranted();

    return _contentNotFetched();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Pedometer'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () {
                  fetchData();
                },
              )
            ],
          ),
          body: Center(
            child: _content(),
          )),
    );
  }
}