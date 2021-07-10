import 'package:charts_flutter/flutter.dart';
import 'package:exnaton_frontend/model/measurement.dart';
import 'package:exnaton_frontend/model/repository/exnaton_repository.dart';
import 'package:exnaton_frontend/model/repository/i_exnaton_repository.dart';
import 'package:flutter/material.dart';

class TimeSeriesScreen extends StatefulWidget {
  TimeSeriesScreen({Key? key}) : super(key: key);

  @override
  _TimeSeriesScreenState createState() => _TimeSeriesScreenState();
}

class _TimeSeriesScreenState extends State<TimeSeriesScreen> {
  late final IExnatonRepository repository;

  @override
  void initState() {
    super.initState();
    repository = ExnatonRepository("http://localhost:5000"); //TODO move to env variable
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exnaton Measurements"),
      ),
      body: FutureBuilder<List<Measurement>>(
        future: repository.getAllMeasurements(),
        builder: (BuildContext context, AsyncSnapshot<List<Measurement>> snapshot) {
          if (snapshot.hasData) {
            return TimeSeriesChart(
              [
                new Series<Measurement, DateTime>(
                  id: 'Measurements',
                  data: snapshot.data!,
                  domainFn: (measurement, _) => DateTime.parse(measurement.timestamp),
                  measureFn: (measurement, _) => (measurement.balanceEnergy),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error);
          } else {
            return _buildLoadingIndicator(context);
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object? error) {
    return Center(
      child: Text("Unknown error"),
    );
  }
}
