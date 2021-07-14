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
class TimeSeriesScreen extends StatefulWidget { // stateful rendering will change depending on the action you take (like widget with radio button), stateless cannot
  // constructor
  TimeSeriesScreen({Key? key}) : super(key: key); //default constructor

  // state creation method
  @override//override some inherent function from the parent
  _TimeSeriesScreenState createState() => _TimeSeriesScreenState();
}
// stateful widget has widget and state, this defines state class
class _TimeSeriesScreenState extends State<TimeSeriesScreen> {// define State of TimeseriesScreen, extends template
  // using interface rather than class (not important)
  late final IExnatonRepository repository; // data access pattern <- we use it to get date from the HTTP server
// just for returning (doesnt store) measurements / data access layer, can be null at first
// future is run-time, late is compile-time static const
  
  DateTime? chosenDate; // data that is chosen on the right
  TimePeriod timePeriod = TimePeriod.month; // radiobutton value (default to month)
  bool grouped = false; // checkbox value (default to unchecked)
  // grouped is just GROUPED button, timeperiod is the top left, chosendate is right-side
  // read from backend API the list of measurements into repository variable
  @override
  void initState() { // define init state
    super.initState(); // state super class
    // super constructor of parent class
    // data access 
    repository = ExnatonRepository('${Uri.base.scheme}://${Uri.base.host}', port: 5000); // create data access from our HTTP server
  } // calls function and passes paremeters of URL and port
  
  // describes widget UI (state-based)
  // basic structure is Widget hierarchy (Widget within widget within widget ...)
  @override
  Widget build(BuildContext context) { // render
    return Scaffold( // scaffold is a basic material design control, look and feel of your controls (graph, grid, etc)
      appBar: AppBar( // bar with the name 
        title: Text("Exnaton Measurements"),
      ),
      body: FutureBuilder<List<Measurement>>( // returns list of measurements (future of)
        //  new class, FutureBuilder reads latest snapshot of future and turns to actual value
        // future (like server's promise) - an async wrapper on top of measurement date from the server
        future: repository.getAllMeasurements(), // this is what is promised by the server
        // constructor/future and builder are the parameters
        builder: (BuildContext context, AsyncSnapshot<List<Measurement>> snapshot) {
          if (snapshot.hasData) { // if data is already available, snap shot used for getting data / connection status with FutureBuilder
            // filter the data we need for the graph
            final filteredData = !this.grouped // in line if statement, GROUPED is a radio button, IF NOT GROUPED (or else take all)
                ? filteredMeasurements( // will take the correct time values depending on time period selected
                    // ungrouped data - only take data for a specific time period around chosen date
                    // for example if data is 1.1.2001. 5:00 and time period is hour, select all "1.1.2001. 5:xx" records (4 records)
                    snapshot.data!, // return relevant snapshot if NOT grouped
                    this.timePeriod, //hour on the top left
                    this.chosenDate ?? DateTime.parse(snapshot.data!.last.timestamp)) //time on the right, double question mark means if null then executes what's after
                : snapshot.data!; // grouped data - take all the data, ! generates error if null, already checked if have data, TAKES ALL SNAPSHOT DATA IF GROUPED, NO FILTER
            filteredData.sort( // sort the data (need to do it so x-axis looks right
                (m1, m2) => DateTime.parse(m1.timestamp).millisecondsSinceEpoch - DateTime.parse(m2.timestamp).millisecondsSinceEpoch);
            return Row( // builds grid
              children: [
                Expanded( // widget that takes 70% of free space, expands child of a row, column, flex
                  flex: 70, // flex displays children in 1D array
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // show graph based on periods
                      _buildPeriodsWidget(context), // radio buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatsWidget(data: filteredData), // get stats widget displayed - for readability it's in a different file
                        ],
                      ),
                      Container(
                        // sizing graph based on screen size
                        // screen aspect ratio around 9/16, seems to work
                        height: (MediaQuery.of(context).size.width * 0.7) * 9 / 16,
                        child: this.grouped
                            ? _buildChartForGroupedData(context, filteredData) // when grouped, no need to handle click
                            : _buildChartForUngroupedData(context, filteredData), // handle drill down on click
                      ), // 
                    ],
                  ),
                ),
                Expanded(
                  flex: 30, // take up to 30% free space 
                  child: Container( // container is a window/frame, in this case a grid
                    height: MediaQuery.of(context).size.height, // screen height
                    // MediaQuery..size is size of screen, height is height of grid
                    child: _buildMeasurementsList(context, snapshot.data!), // returns grid widget on the right
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error); //just show error
          } else {
            return _buildLoadingIndicator(context); // never happens we are too fast
          }
        },
      ),
    );
  }
  // when data is ungrouped
  Widget _buildChartForUngroupedData(BuildContext context, List<Measurement> data) {
    int Function(Measurement) keyFunction; // reference to the function
    // select a function depending on time period selected
    switch (this.timePeriod) {
      case TimePeriod.hour:
        // lambda (date) => relevant part of datetime
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
    // let's do group by 
    final series = charts.Series<List<Measurement>, DateTime>(
      id: 'Measurements',
      data: groupBy<Measurement, int>(data, keyFunction).values.toList(), // group by measurement based on our group by function
      domainFn: (measurements, _) => DateTime.parse(measurements[0].timestamp), // x-axis (time)
      measureFn: (measurements, _) => 
          
          // groupping measurements by averaging values (like java8 reduce:0 + sum (elements)/size) 
          measurements.fold<double>(0.0, (prevVal, element) => prevVal + element.balanceEnergy) / measurements.length,
    );
    return charts.TimeSeriesChart(
      [series],
      defaultRenderer: new charts.BarRendererConfig<DateTime>(), // bar chart
      selectionModels: [ // drill down 
        charts.SelectionModelConfig( // handle drilldown here
          changedListener: (model) {
            if (model.hasDatumSelection) { // if we selected date
              final measurements = model.selectedDatum[0].datum as List<Measurement>; // just take what we selected
              final date = DateTime.parse(measurements[0].timestamp); // change to new date
              setState(() { // create new state with the new values (re-render)
                timePeriod = this.timePeriod.less; // reduce time period by one (eg year-> month etc.)
                chosenDate = date; // select the date
              });
            }
          },
        ),
      ],
    );
  }
  // when data is grouped
  Widget _buildChartForGroupedData(BuildContext context, List<Measurement> data) {
     // select a function we will use for group by depending on time period selected
    int Function(Measurement) keyFunction;
    switch (this.timePeriod) {
      case TimePeriod.hour:
        // lambda (date) => relevant part of datetime
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
    // select which part of date time we are going to show on x-axis
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
      data: groupBy<Measurement, int>(data, keyFunction).values.toList(), // group by measurement based on our group by function
      domainFn: (measurements, _) => format.format(DateTime.parse(measurements[0].timestamp)), // x-axis (time)
      measureFn: (measurements, _) => // groupping y-result by averaging the values (like java8 reduce) 
          measurements.fold<double>(0.0, (prevVal, element) => prevVal + element.balanceEnergy) / measurements.length,
    );
    return charts.BarChart(
      [series],
    );
  }

  // periods widget
  Widget _buildPeriodsWidget(BuildContext context) {
    return Card(
      child: Padding( // pad 
        padding: EdgeInsets.all(8.0),
        child: Row( 
          mainAxisSize: MainAxisSize.min,
          children: [
            ...TimePeriod.values.map((period) { // create buttons for all possible time periods, enumerator for radio buttons
              return Row(
                children: [
                  Radio<TimePeriod>( // radio buttons, belong to the same parent (so only one value can be selected), add radio button value
                    value: period, // set value of RB (week, month, etc
                    groupValue: this.timePeriod, // whole group has this value
                    // change state when different option is selected
                    onChanged: (newPeriod) => setState(() { // if changed, reset state
                      this.timePeriod = newPeriod!; // read the new value, keep date
                    }), // children of same parent so can only select one RB
                  ),
                  Text(period.title) // name of the radio button
                ],
              );
            }),
            Row(
              children: [
                Checkbox( // Grouped checkbox
                  value: this.grouped, // is checkbox checked or not
                  // change state when different option is selected
                  onChanged: (newValue) => setState(() { // if changed,  reset state
                    // onChanged is event: click on button->call setState->reset State, why its Stateful->call widget to re-render screen), new Period is whatever value been clicked
                    this.grouped = newValue!; // read the new value
                    this.chosenDate = null; // reset the date
                  }),
                ),
                Text("Grouped"), // name of the checkbox
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
        // header
        Row(
          children: [
            Expanded(
              // first column header (Date)
              child: Container(
                decoration: BoxDecoration(color: Colors.grey),
                padding: EdgeInsets.all(8.0), // pad the text
                child: Text(
                  "Date",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              // second column header (Value)
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
        // now write the values of the grid
        ...data.map((m) {
          return InkWell(
            // change state if new date is selected
            onTap: () => setState(() {
              this.chosenDate = DateTime.parse(m.timestamp); // if I select a date, use it to rerender screen
              this.grouped = false; // cannot be grouped 
            }),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8.0), // padding the text
                    // show date...
                    child: Text(
                      DateFormat("dd/MM/yyyy hh:mm").format(DateTime.parse(m.timestamp)), // show nice format
                      style: TextStyle(
                        // bold if we show chosen date
                        fontWeight: m.timestamp == this.chosenDate?.toIso8601String() ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    // and value (with 4 dec.)
                    child: Text(
                      m.balanceEnergy.toStringAsFixed(4), // format to 4 decimal pts
                      style: TextStyle(
                        // bold if we show our choosen chosen date
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

  // filters measurements based on time perod (day/week/month) and date selected (dateTime), selects relevant data
  // e.g. for 1.1.2001 5:00 and time period = hour -> select all records with 1.1.2001 5:xx
  List<Measurement> filteredMeasurements(List<Measurement> data, TimePeriod period, DateTime dateTime) {
    switch (period) {
      case TimePeriod.hour: //if select hour RB
        // where clause for filter and then convert back to list
        // comparison basically "a relevant part of records date  == same part of choosen date
        return data.where((e) => DateTime.parse(e.timestamp).withoutMinutes == dateTime.withoutMinutes).toList();
      case TimePeriod.day:
        return data.where((e) => DateTime.parse(e.timestamp).withoutTime == dateTime.withoutTime).toList();
      case TimePeriod.week:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year && edate.weekNumber == dateTime.weekNumber;
        }).toList();
         // filters/returns 24 hour values by 4
      case TimePeriod.month:
        return data.where((e) {
          final edate = DateTime.parse(e.timestamp);
          return edate.year == dateTime.year && edate.month == dateTime.month;
        }).toList(); 
      case TimePeriod.year:
        return data.where((e) => DateTime.parse(e.timestamp).year == dateTime.year).toList();
    }// returns 31-ish days * 24 * 4
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
  // define next level of drill down for time period (eg year -> month)
  // for hour- nothing to drill down to (return self)
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
        return TimePeriod.month; // extension for calling hour, day, week, month
        
        // converts to string (String get)
    // TimePeriod.hour.title -> "Hour"
    }
  }
}
