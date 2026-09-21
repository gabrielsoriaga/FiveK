import 'dart:math'; // used for max calculations
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Main widget that shows weekly progress stats + chart
class WeeklyProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activities; // list of user activities

  const WeeklyProgressWidget({
    super.key,
    required this.activities,
  });

  // gets the Sunday of the current week
  DateTime getStartOfWeek(DateTime date) {
    final int daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromSunday));
  }

  // gets the Saturday of the same week
  DateTime getEndOfWeek(DateTime startOfWeek) {
    return startOfWeek.add(const Duration(days: 6));
  }

  // formats week range into readable text
  String formatWeekRange(DateTime start, DateTime end) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    return "${months[start.month - 1]} ${start.day}, ${start.year} - "
        "${months[end.month - 1]} ${end.day}, ${end.year}";
  }

  // converts duration into "xh ym" format
  String formatTotalDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    }
    return "${minutes}m";
  }

  // checks if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // calculate week range
    final startOfWeek = getStartOfWeek(now);
    final endOfWeek = getEndOfWeek(startOfWeek);

    int activityCount = 0;

    // store distance for each day (Sun-Sat)
    final List<double> dailyDistances = List.filled(7, 0.0);

    Duration totalTime = Duration.zero;
    double totalDistance = 0.0;

    // loop through all activities
    for (final activity in activities) {
      final rawDate = activity["dateAndTime"];

      DateTime date;

      // handle different possible date formats
      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is DateTime) {
        date = rawDate;
      } else {
        date = DateTime.parse(rawDate.toString());
      }

      final activityDay = DateTime(date.year, date.month, date.day);

      // check if activity is within this week
      if (!activityDay.isBefore(startOfWeek) &&
          !activityDay.isAfter(endOfWeek)) {

        final int dayIndex = activityDay.difference(startOfWeek).inDays;

        activityCount++;

        // get distance (default 0 if missing)
        final double distance =
            (activity["distance"] as num?)?.toDouble() ?? 0.0;

        // get time and convert to Duration
        final dynamic rawTime = activity["timeSeconds"];
        Duration time = Duration.zero;

        if (rawTime is int) {
          time = Duration(seconds: rawTime);
        } else if (rawTime is String) {
          final parts = rawTime.split(":");
          if (parts.length == 3) {
            time = Duration(
              hours: int.tryParse(parts[0]) ?? 0,
              minutes: int.tryParse(parts[1]) ?? 0,
              seconds: int.tryParse(parts[2]) ?? 0,
            );
          }
        }

        // add values to totals
        dailyDistances[dayIndex] += distance;
        totalDistance += distance;
        totalTime += time;
      }
    }

    // calculate averages
    Duration avgTime = Duration.zero;
    double avgDistance = 0.0;

    if (activityCount > 0) {
      avgTime = Duration(seconds: totalTime.inSeconds ~/ activityCount);
      avgDistance = totalDistance / activityCount;
    }

    // UI container
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 46, 48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progress",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          const Text(
            "This week",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // display week range
          Text(
            formatWeekRange(startOfWeek, endOfWeek),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // show average stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBox(
                value: formatTotalDuration(avgTime),
                label: "Avg. Time",
              ),
              _StatBox(
                value: avgDistance.toStringAsFixed(1),
                label: "Avg. Distance (km)",
              ),
            ],
          ),

          const SizedBox(height: 20),

          // chart displaying daily distances
          SizedBox(
            height: 160,
            child: WeeklyLineChart(
              dailyDistances: dailyDistances,
            ),
          ),
        ],
      ),
    );
  }
}

// small reusable widget for stats (label + value)
class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// wrapper for custom chart painter
class WeeklyLineChart extends StatelessWidget {
  final List<double> dailyDistances;

  const WeeklyLineChart({
    super.key,
    required this.dailyDistances,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WeeklyLineChartPainter(dailyDistances),
      child: Container(),
    );
  }
}

// handles drawing the line chart manually
class WeeklyLineChartPainter extends CustomPainter {
  final List<double> dailyDistances;

  WeeklyLineChartPainter(this.dailyDistances);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 10.0;
    const rightPadding = 35.0;
    const topPadding = 10.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // find max value (at least 5 to keep scale readable)
    final maxValue = max(
      5.0,
      dailyDistances.fold<double>(0.0, (a, b) => max(a, b)),
    );

    // line style
    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // grid line style
    final gridPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;

    final labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

    // draw horizontal guide lines
    final y1 = topPadding + chartHeight * (1 - (2.5 / maxValue));
    final y2 = topPadding + chartHeight * (1 - (5.0 / maxValue));

    canvas.drawLine(
      Offset(leftPadding, y1),
      Offset(leftPadding + chartWidth, y1),
      gridPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, y2),
      Offset(leftPadding + chartWidth, y2),
      gridPaint,
    );

    // draw labels (2.5km and 5km)
    final textPainter25 = TextPainter(
      text: labelStyle.copyWith(fontSize: 11).toTextSpan("2.5 km"),
      textDirection: TextDirection.ltr,
    )..layout();

    final textPainter5 = TextPainter(
      text: labelStyle.copyWith(fontSize: 11).toTextSpan("5 km"),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter25.paint(canvas, Offset(leftPadding + chartWidth + 8, y1 - 8));
    textPainter5.paint(canvas, Offset(leftPadding + chartWidth + 8, y2 - 8));

    // draw line path
    final path = Path();

    for (int i = 0; i < dailyDistances.length; i++) {
      final x = leftPadding + (chartWidth / 6) * i;
      final y = topPadding + chartHeight * (1 - (dailyDistances[i] / maxValue));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // draw day labels at bottom
    for (int i = 0; i < days.length; i++) {
      final x = leftPadding + (chartWidth / 6) * i;

      final textPainter = TextPainter(
        text: labelStyle.toTextSpan(days[i]),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// helper to convert TextStyle into TextSpan
extension on TextStyle {
  TextSpan toTextSpan(String text) {
    return TextSpan(text: text, style: this);
  }
}