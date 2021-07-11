import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {

  DateTime get withoutTime => DateTime(this.year, this.month, this.day);

  DateTime get withoutMinutes => DateTime(this.year, this.month, this.day, this.hour);

  /// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
  int numOfWeeks(int year) {
    DateTime dec28 = DateTime(year, 12, 28);
    int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }

  /// Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
  int get weekNumber {
    int dayOfYear = int.parse(DateFormat("D").format(this));
    int woy =  ((dayOfYear - this.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = numOfWeeks(this.year - 1);
    } else if (woy > numOfWeeks(this.year)) {
      woy = 1;
    }
    return woy;
  }
}