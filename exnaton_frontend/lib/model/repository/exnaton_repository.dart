import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:exnaton_frontend/model/measurement.dart';
import 'package:exnaton_frontend/model/repository/i_exnaton_repository.dart';

class ExnatonRepository extends IExnatonRepository {
  final String baseUrl;
  final int port;

  ExnatonRepository(this.baseUrl, {this.port = 80});

  @override
  Future<List<Measurement>> getAllMeasurements() async {
    var response = await http.get(
      Uri.parse('$baseUrl:$port/measurements'),
    );
    if (response.statusCode == 200) {
      var languages =
          jsonDecode(response.body)['measurements'] as List<dynamic>;
      return languages.map((e) {
        return Measurement(
            measurement: e['measurement'],
            positiveEnergy: e['positiveEnergy'],
            negativeEnergy: e['negativeEnergy'],
            balanceEnergy: e['balanceEnergy'],
            tags: e['tags'],
            timestamp: e['timestamp']);
      }).toList();
    } else {
      throw HttpException(response.reasonPhrase ?? 'Unknown error',
          uri: response.request?.url);
    }
  }
}
