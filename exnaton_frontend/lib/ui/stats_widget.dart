import 'package:exnaton_frontend/model/measurement.dart';
import 'package:flutter/material.dart';

import 'dart:math';

// stateless widget to display TimeSeries statistcs (mean, STD, max, min)

class StatsWidget extends StatelessWidget {
  // values to be displayed
  late num mean;
  late num deviation;
  late num minimum;
  late num maximum;

  static const TextStyle textStyle = TextStyle(fontSize: 18);
  // constructor - taking list of measurements that make the graph
  StatsWidget({Key? key, required List<Measurement> data}) : super(key: key) {
    // initialize to unrealistic values
    num minimum = double.infinity;
    num maximum = double.negativeInfinity;
    num sum = 0;
    // only using balanceEnergy as negativeEnergy always = 0 
    // computing the stats
    for (Measurement m in data) { // just go through collection and compute min, max, sum
      minimum = min(minimum, m.balanceEnergy);
      maximum = max(maximum, m.balanceEnergy);
      sum += m.balanceEnergy;
    }
    // store in member variables
    this.minimum = minimum;
    this.maximum = maximum;
    this.mean = sum / data.length;
    //compute std
    this.deviation = sqrt(data.fold<num>(0, (prevValue, e) => prevValue + pow(e.balanceEnergy - this.mean, 2)) / (data.length - 1));
  }
  // describes UI for the widget
  // the widget is stateless - no options/states available
  @override
  Widget build(BuildContext context) {
    return Card(
      // padded 
      child: Padding(
        padding: EdgeInsets.all(16.0),
        // row (horizontal element)
        child: Row(
          children: [
            // two columns 1.(mean, std) and 2.(min, max)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // fortmatted to 4 decimal places
                Text('μ = ${this.mean.toStringAsFixed(4)}', style: textStyle),
                SizedBox(height: 16),
                Text('σ = ${this.deviation.toStringAsFixed(4)}', style: textStyle),
              ],
            ),
            SizedBox(width: 16.0),
            // second column starts here
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('min = ${this.minimum.toStringAsFixed(4)}', style: textStyle),
                SizedBox(height: 16),
                Text('max = ${this.maximum.toStringAsFixed(4)}', style: textStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
