import 'package:exnaton_frontend/model/measurement.dart';

abstract class IExnatonRepository {

  Future<List<Measurement>> getAllMeasurements();
}