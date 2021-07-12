import 'package:exnaton_frontend/model/measurement.dart';
import 'package:flutter/material.dart';

import 'dart:math';

class StatsWidget extends StatelessWidget {
  late num mean;
  late num deviation;
  late num minimum;
  late num maximum;

  static const TextStyle textStyle = TextStyle(fontSize: 18);

  StatsWidget({Key? key, required List<Measurement> data}) : super(key: key) {
    num minimum = double.infinity;
    num maximum = double.negativeInfinity;
    num sum = 0;
    for (Measurement m in data) {
      minimum = min(minimum, m.balanceEnergy);
      maximum = max(maximum, m.balanceEnergy);
      sum += m.balanceEnergy;
    }
    this.minimum = minimum;
    this.maximum = maximum;
    this.mean = sum / data.length;
    this.deviation = sqrt(data.fold<num>(0, (prevValue, e) => prevValue + pow(e.balanceEnergy - this.mean, 2)) / (data.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('μ = ${this.mean}', style: textStyle),
                SizedBox(height: 16),
                Text('σ = ${this.deviation}', style: textStyle),
              ],
            ),
            SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('min = ${this.minimum}', style: textStyle),
                SizedBox(height: 16),
                Text('max = ${this.maximum}', style: textStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
