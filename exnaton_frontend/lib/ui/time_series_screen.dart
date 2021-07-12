import 'package:charts_flutter/flutter.dart' as charts;
import "package:collection/collection.dart";
import 'package:exnaton_frontend/model/measurement.dart';
import 'package:exnaton_frontend/model/repository/exnaton_repository.dart';
import 'package:exnaton_frontend/model/repository/i_exnaton_repository.dart';
import 'package:exnaton_frontend/ui/stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:exnaton_frontend/utility/date_time_extension.dart';
import 'package:intl/intl.dart';

class TimeSeriesScreen extends StatefulWidget {
  TimeSeriesScreen({Key? key}) : super(key: key);

  @override
  _TimeSeriesScreenState createState() => _TimeSeriesScreenState();
}

class _TimeSeriesScreenState extends State<TimeSeriesScreen> {
  late final IExnatonRepository repository;

  DateTime? chosenDate;
  TimePeriod? timePeriod = TimePeriod.month;
  bool grouped = false;

  @override
  void initState() {
    super.initState();
    repository =
        ExnatonRepository('${Uri.base.scheme}://${Uri.base.host}', port: 5000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exnaton Measurements"),
      ),
      body: FutureBuilder<List<Measurement>>(
        future: repository.getAllMeasurements(),
        builder:
            (BuildContext context, AsyncSnapshot<List<Measurement>> snapshot) {
          if (snapshot.hasData) {
            final filteredData = !this.grouped
                ? filteredMeasurements(
                    snapshot.data!,
                    this.timePeriod!,
                    this.chosenDate ??
                        DateTime.parse(snapshot.data!.last.timestamp))
                : snapshot.data!;
            return Row(
              children: [
                Expanded(
                  flex: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodsWidget(context),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatsWidget(data: filteredData),
                        ],
                      ),
                      Container(
                        height:
                            (MediaQuery.of(context).size.width * 0.7) * 9 / 16,
                        child: charts.TimeSeriesChart(
                          [
                            getSeries(
                                filteredData,
                                this.timePeriod ?? TimePeriod.month,
                                this.chosenDate ??
                                    DateTime.parse(
                                        snapshot.data![0].timestamp)),
                          ],
                          defaultRenderer:
                              new charts.BarRendererConfig<DateTime>(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: _buildMeasurementsList(context, snapshot.data!),
                  ),
                ),
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

  Widget _buildPeriodsWidget(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...TimePeriod.values.map((period) {
              return Row(
                children: [
                  Radio<TimePeriod>(
                    value: period,
                    groupValue: this.timePeriod,
                    onChanged: (newPeriod) => setState(() {
                      this.timePeriod = newPeriod;
                    }),
                  ),
                  Text(period.title)
                ],
              );
            }),
            Row(
              children: [
                Checkbox(
                  value: this.grouped,
                  onChanged: (newValue) => setState(() {
                    this.grouped = newValue!;
                    this.chosenDate = null;
                  }),
                ),
                Text("Grouped"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsList(BuildContext context, List<Measurement> data) {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey),
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Date",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey),
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Value",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        ...data.map((m) {
          return InkWell(
            onTap: () => setState(() {
              this.chosenDate = DateTime.parse(m.timestamp);
              this.grouped = false;
            }),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      DateFormat("dd/MM/yyyy hh:mm")
                          .format(DateTime.parse(m.timestamp)),
                      style: TextStyle(
                        fontWeight:
                            m.timestamp == this.chosenDate?.toIso8601String()
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      m.balanceEnergy.toStringAsFixed(4),
                      style: TextStyle(
                        fontWeight:
                            m.timestamp == this.chosenDate?.toIso8601String()
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        })
      ],
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

  charts.Series<dynamic, DateTime> getSeries(
    List<Measurement> data,
    TimePeriod period,
    DateTime dateTime,
  ) {
    int Function(Measurement) keyFunction;
    switch (period) {
      case TimePeriod.hour:
        keyFunction = (e) => DateTime.parse(e.timestamp).minute;
        break;
      case TimePeriod.day:
        keyFunction = (e) => DateTime.parse(e.timestamp).hour;
        break;
      case TimePeriod.week:
        keyFunction = (e) => DateTime.parse(e.timestamp).weekday;
        break;
      case TimePeriod.month:
        keyFunction = (e) => DateTime.parse(e.timestamp).day;
        break;
    }
    return charts.Series<List<Measurement>, DateTime>(
      id: 'Measurements',
      data: groupBy<Measurement, int>(data, keyFunction).values.toList(),
      domainFn: (measurements, _) => DateTime.parse(measurements[0].timestamp),
      measureFn: (measurements, _) =>
          measurements.fold<double>(
              0.0, (prevVal, element) => prevVal + element.balanceEnergy) /
          measurements.length,
    );
  }

  List<Measurement> filteredMeasurements(
      List<Measurement> data, TimePeriod period, DateTime dateTime) {
    switch (period) {
      case TimePeriod.hour:
        return data
            .where((e) =>
                DateTime.parse(e.timestamp).withoutMinutes ==
                dateTime.withoutMinutes)
            .toList();
      case TimePeriod.day:
        return data
            .where((e) =>
                DateTime.parse(e.timestamp).withoutTime == dateTime.withoutTime)
            .toList();
      case TimePeriod.week:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year &&
              edate.weekNumber == dateTime.weekNumber;
        }).toList();
      case TimePeriod.month:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year && edate.month == dateTime.month;
        }).toList();
    }
  }
}

enum TimePeriod { hour, day, week, month }

extension TimePeriodExtension on TimePeriod {
  String get title {
    switch (this) {
      case TimePeriod.hour:
        return "Hour";
      case TimePeriod.day:
        return "Day";
      case TimePeriod.week:
        return "Week";
      case TimePeriod.month:
        return "Month";
    }
  }
}
