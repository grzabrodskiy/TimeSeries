
// interface for ExnatonRepository
// not really needed, just enforces havinf getAllMeasurements() method that returns the list of measurements

import 'package:exnaton_frontend/model/measurement.dart';

abstract class IExnatonRepository {
  const IExnatonRepository();

  Future<List<Measurement>> getAllMeasurements();
}
