import 'package:charts_flutter/flutter.dart' as charts;
import "package:collection/collection.dart";
import 'package:exnaton_frontend/model/measurement.dart';
import 'package:exnaton_frontend/model/repository/exnaton_repository.dart';
import 'package:exnaton_frontend/model/repository/i_exnaton_repository.dart';
import 'package:exnaton_frontend/ui/stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:exnaton_frontend/utility/date_time_extension.dart';
import 'package:intl/intl.dart';

// TimeSeriesScreen is StatefulWidget
// states are defined by different values of radio buttons and a value of a checkbox
class TimeSeriesScreen extends StatefulWidget {
  // constructor
  TimeSeriesScreen({Key? key}) : super(key: key);

  // state creation method
  @override
  _TimeSeriesScreenState createState() => _TimeSeriesScreenState();
}

class _TimeSeriesScreenState extends State<TimeSeriesScreen> {
  // using interface rather than class (not important)
  late final IExnatonRepository repository;

  DateTime? chosenDate; // data that is chosen on the righ
  TimePeriod timePeriod = TimePeriod.month; // radiobutton value (default to month)
  bool grouped = false; // checkbox value (default to unchecked)

  // read from backend API the list of measurements into repository variable
  @override
  void initState() {
    super.initState();
    repository = ExnatonRepository('${Uri.base.scheme}://${Uri.base.host}', port: 5000);
  }

  // describes widget UI (state-based)
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
            final filteredData = !this.grouped
                ? filteredMeasurements(
                    // ungrouped data - only take data for a specific time period
                    snapshot.data!,
                    this.timePeriod,
                    this.chosenDate ?? DateTime.parse(snapshot.data!.last.timestamp))
                : snapshot.data!; // grouped data - take all the data
            filteredData.sort(
                (m1, m2) => DateTime.parse(m1.timestamp).millisecondsSinceEpoch - DateTime.parse(m2.timestamp).millisecondsSinceEpoch);
            return Row(
              children: [
                Expanded(
                  flex: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // show graph based on periods
                      _buildPeriodsWidget(context),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatsWidget(data: filteredData),
                        ],
                      ),
                      Container(
                        // sizing the graph based on screen size
                        height: (MediaQuery.of(context).size.width * 0.7) * 9 / 16,
                        child: this.grouped
                            ? _buildChartForGroupedData(context, filteredData)
                            : _buildChartForUngroupedData(context, filteredData),
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

  Widget _buildChartForUngroupedData(BuildContext context, List<Measurement> data) {
    int Function(Measurement) keyFunction;
    switch (this.timePeriod) {
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
      case TimePeriod.year:
        keyFunction = (e) => DateTime.parse(e.timestamp).month;
        break;
    }
    final series = charts.Series<List<Measurement>, DateTime>(
      id: 'Measurements',
      data: groupBy<Measurement, int>(data, keyFunction).values.toList(),
      domainFn: (measurements, _) => DateTime.parse(measurements[0].timestamp),
      measureFn: (measurements, _) =>
          measurements.fold<double>(0.0, (prevVal, element) => prevVal + element.balanceEnergy) / measurements.length,
    );
    return charts.TimeSeriesChart(
      [series],
      defaultRenderer: new charts.BarRendererConfig<DateTime>(),
      selectionModels: [
        charts.SelectionModelConfig(
          changedListener: (model) {
            if (model.hasDatumSelection) {
              final measurements = model.selectedDatum[0].datum as List<Measurement>;
              final date = DateTime.parse(measurements[0].timestamp);
              setState(() {
                timePeriod = this.timePeriod.less;
                chosenDate = date;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChartForGroupedData(BuildContext context, List<Measurement> data) {
    int Function(Measurement) keyFunction;
    switch (this.timePeriod) {
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
      case TimePeriod.year:
        keyFunction = (e) => DateTime.parse(e.timestamp).month;
        break;
    }
    DateFormat format;
    switch (this.timePeriod) {
      case TimePeriod.hour:
        format = DateFormat("m");
        break;
      case TimePeriod.day:
        format = DateFormat("H");
        break;
      case TimePeriod.week:
        format = DateFormat.E();
        break;
      case TimePeriod.month:
        format = DateFormat.d();
        break;
      case TimePeriod.year:
        format = DateFormat.MMM();
        break;
    }
    final series = charts.Series<List<Measurement>, String>(
      id: 'Measurements',
      data: groupBy<Measurement, int>(data, keyFunction).values.toList(),
      domainFn: (measurements, _) => format.format(DateTime.parse(measurements[0].timestamp)),
      measureFn: (measurements, _) =>
          measurements.fold<double>(0.0, (prevVal, element) => prevVal + element.balanceEnergy) / measurements.length,
    );
    return charts.BarChart(
      [series],
    );
  }

  // periods graph
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
                    // change state when different option is selected
                    onChanged: (newPeriod) => setState(() {
                      this.timePeriod = newPeriod!;
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
                  // change state when different option is selected
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

  // list of measurements (date and value)
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
            // change state if new date is selected
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
                      DateFormat("dd/MM/yyyy hh:mm").format(DateTime.parse(m.timestamp)),
                      style: TextStyle(
                        fontWeight: m.timestamp == this.chosenDate?.toIso8601String() ? FontWeight.bold : FontWeight.normal,
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
                        fontWeight: m.timestamp == this.chosenDate?.toIso8601String() ? FontWeight.bold : FontWeight.normal,
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

  // progress indicator (never shown - we are moving too fast :)
  Widget _buildLoadingIndicator(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  // error indicator (hopefully never seen :)
  Widget _buildErrorWidget(BuildContext context, Object? error) {
    return Center(
      child: Text("Unknown error"),
    );
  }

  // this method filters measurements based on time perod (day/week/month) and date selected (dateTime)
  List<Measurement> filteredMeasurements(List<Measurement> data, TimePeriod period, DateTime dateTime) {
    switch (period) {
      case TimePeriod.hour:
        return data.where((e) => DateTime.parse(e.timestamp).withoutMinutes == dateTime.withoutMinutes).toList();
      case TimePeriod.day:
        return data.where((e) => DateTime.parse(e.timestamp).withoutTime == dateTime.withoutTime).toList();
      case TimePeriod.week:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year && edate.weekNumber == dateTime.weekNumber;
        }).toList();
      case TimePeriod.month:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year && edate.month == dateTime.month;
        }).toList();
      case TimePeriod.year:
        return data.where((e) => DateTime.parse(e.timestamp).year == dateTime.year).toList();
    }
  }
}

// time period allowed values
enum TimePeriod { hour, day, week, month, year }

// naming of the enum values
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
      case TimePeriod.year:
        return "Year";
    }
  }

  TimePeriod get less {
    switch (this) {
      case TimePeriod.hour:
        return TimePeriod.hour;
      case TimePeriod.day:
        return TimePeriod.hour;
      case TimePeriod.week:
        return TimePeriod.day;
      case TimePeriod.month:
        return TimePeriod.day;
      case TimePeriod.year:
        return TimePeriod.month;
    }
  }
}
