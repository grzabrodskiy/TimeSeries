import 'package:exnaton_frontend/model/measurement.dart';

abstract class IExnatonRepository {
  const IExnatonRepository();

  Future<List<Measurement>> getAllMeasurements();
}
