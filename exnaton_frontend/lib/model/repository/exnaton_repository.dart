import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:exnaton_frontend/model/measurement.dart';
import 'package:exnaton_frontend/model/repository/i_exnaton_repository.dart';

class ExnatonRepository extends IExnatonRepository {// create repository, obstruction data access layer
  final String baseUrl;
  final int port;

  ExnatonRepository(this.baseUrl, {this.port = 80});
  // overriding from the interface
  // reading the measurements into the list of Measurement structures
  @override
  Future<List<Measurement>> getAllMeasurements() async {// basically takes all backend stuff and moves to List called Measurement
    var response = await http.get(
      Uri.parse('$baseUrl:$port/measurements'),
    );
    // success
    if (response.statusCode == 200) {
      // read from JSON to Measurement structure
      var languages =
          jsonDecode(response.body)['measurements'] as List<dynamic>;
      return languages.map((e) { // maps JSON to the structure that we wanted
        return Measurement(// Constructor of Measurement, Capital Measurement is a structure, convert JSON to it
            measurement: e['measurement'],
            positiveEnergy: e['positiveEnergy'],
            negativeEnergy: e['negativeEnergy'],
            balanceEnergy: e['balanceEnergy'],
            tags: e['tags'],// e for element in the JSON, lower case "measurement" is attribute of structure
            timestamp: e['timestamp']); // we've converted list of JSON strings to list of Measurement Objects
      }).toList(); // returns Future of <List> of Measurements
    } else {
      throw HttpException(response.reasonPhrase ?? 'Unknown error',
          uri: response.request?.url);
    }
  }
}


// balanced=positive, negative=0
// we only use timestamp and balanced(which is technically positive)
// balanced = positive - negative

// thought of doing stack chart but saw that always 0, bar chart

// show 7 day running average
