// Measurement data structure

class Measurement {
  final String measurement;
  final double positiveEnergy;
  final double negativeEnergy;
  final double balanceEnergy;
  final dynamic tags;
  final String timestamp;

  Measurement({
    required this.measurement,
    required this.positiveEnergy,
    required this.negativeEnergy,
    required this.balanceEnergy,
    required this.tags,
    required this.timestamp,
  });
}
