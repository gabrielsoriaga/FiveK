import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomePage extends StatefulWidget { // Create a stateful widget for the timer and activity feed
  final int streakDays;
  final List<Map<String, dynamic>> activities;
  final bool isStreakActive;
  final String userName;
  const HomePage({super.key, required this.userName, this.streakDays = 0, this.activities = const [], this.isStreakActive = false}); // Constructor

  @override
  State<HomePage> createState() => _HomePageState(); 
}

class _HomePageState extends State<HomePage> { // Set timer


  String time = "";
  String date = "";

  @override
  void initState() {
    super.initState();
    _updateTime();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();

    setState(() {
      time = DateFormat('HH:mm').format(now);
      date = DateFormat('dd/MM/yy').format(now);
    });
}

  @override
  Widget build(BuildContext context) { // Build UI for home page with timer, date, streak notification and activity feed
    print("🏠 Building HomePage"); // Print debugging 
    print("HOME PAGE:");
    print("streakDays: ${widget.streakDays}");
    print("isActive: ${widget.isStreakActive}");
    return SingleChildScrollView( // Allow scrolling for the activity feed
      child: Column ( // You cannot use scaffold as a widget when you already have a scaffold in the main.dart file, so you can use column to format the containers in a column
        children: [ // Children has the argument of Container
          Container( // Container joins both containers, it has arguments margin to give space for both containers, child is the widget that formats the containers into a row
            margin: EdgeInsets.all(10.0), // This line is used to give the container a margin of 10 pixels on all sides. The margin is the space outside the container, which separates it from other widgets. By setting the margin to EdgeInsets.all(10.0), you are specifying that there should be a 10 pixel gap between this container and any other widgets around it. This can help to create a more visually appealing layout by preventing the widgets from being too close together.
            child: Row(
            children: [ // This holds the containers in a row
                Expanded(
                  child: InfoBox( 
                    icon: const Icon(Icons.av_timer),
                    text: "$time",
                    ),
                ), // Change the content in the Main method
                Expanded(
                  child: InfoBox(
                    icon: const Icon(Icons.calendar_month),
                    text: '$date'
                    ),
                ),
                  ]
          ),
        ),
        if (widget.streakDays >= 3) // Show Container if streakdays are above 3
        StreakBoxNotification(streak: widget.streakDays),
        Container ( 
          child: Column (
          children: [
          ...widget.activities.map((activity) {
  
  DateTime convertToDate(dynamic rawDate) { // Convert the date from the database to a DateTime object
  if (rawDate is Timestamp) return rawDate.toDate();
  if (rawDate is DateTime) return rawDate;
  return DateTime.parse(rawDate.toString());
}

  final activityDate = convertToDate(activity["dateAndTime"]);

  return ActivityBox( // Take the activity data from record page and format it into an activity box for the feed
    user: widget.userName,
    dateAndTime: activityDate,
    location: activity["location"] ?? "",
    title: activity["title"] ?? "",
    bio: activity["bio"] ?? "",
    distance: (activity["distance"] as num).toDouble(),
    pace: activity["pace"] ?? "-:--",
    time: Duration(seconds: activity["timeSeconds"] ?? 0),
    path: List<Map<String, double>>.from(
      (activity["path"] as List).map(
        (point) => {
          "lat": (point["lat"] as num).toDouble(),
          "lng": (point["lng"] as num).toDouble(),
        },
      ),
    ),
  );
}).toList(),
          ]
          )
        )
      ],
    ),
    );
  }
}

class InfoBox extends StatelessWidget { // Class: InfoBox for Time and Date widgets

final String text;
final Icon icon;

const InfoBox({super.key, required this.text, required this.icon}); // Return values for time and date

  @override
  Widget build(BuildContext context) { // Build the UI for the time and date boxes, with an icon and text
    return Container(
      height: 100,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 46, 48),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Row (
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
            const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        ],
      ),
      ),
    );
  }
}

class ActivityBox extends StatelessWidget  { // Class: ActivityBox for activity posts for home page feed
 
  // Declare activity box data
  final String user, location, title, bio;
  final double distance; 
  final Duration time; 
  final String pace;
  final DateTime dateAndTime;
  final List<Map<String, double>> path; // lat/lng list

 const ActivityBox({ 
 super.key, 
 required this.user, 
 required this.dateAndTime, 
 required this.location, 
 required this.title, 
 required this.bio,
 required this.distance, 
 required this.pace, 
 required this.time,
 required this.path,
 });

@override
  Widget build(BuildContext context) { // Create UI design for the activity box, with map and polyline for the route taken in the activity
    return Container (
      height: 550,
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 46, 48),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container (
            margin: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 20),
                ),
                SizedBox(width: 10),
                Text (
                user,
                style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                    )
                  ),
                ],  
              ),
              Text(
               DateFormat("MMMM d, y 'at' HH:mm a").format(dateAndTime),
               style: TextStyle(
              fontSize: 15,
            )
           ),
           Text(
               location,
               style: TextStyle(
              fontSize: 15,
            )
           ),
           const SizedBox(height: 20),
           Text(
               title,
               style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
            )
           ),
           Text(
               bio,
               style: TextStyle(
              fontSize: 20,
            )
           ),
          ]
         )
        ),
      Container (
      margin: const EdgeInsets.all(10),
      child: Row (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        _buildStat("Distance", "${distance.toStringAsFixed(2)} km"),
        SizedBox(width: 20),
        _buildStat("Pace", "$pace /km"),
        SizedBox(width: 20),
        _buildStat("Time", "${formatDuration(time)}s"),
        ],
        )
        ),  
             Container(
  height: 200,
  margin: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: GoogleMap( // Create Google Map widget for map route 
      initialCameraPosition: CameraPosition(
        target: getLatLngPath().isNotEmpty
            ? getLatLngPath().first
            : LatLng(0, 0),
        zoom: 15,
      ),
      onMapCreated: (controller) {
    final path = getLatLngPath();

    if (path.length > 1) {
      final bounds = getBounds(path);

      Future.delayed(const Duration(milliseconds: 300), () {
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      });
    }
  },
      polylines: {
        Polyline(
          polylineId: PolylineId("route"),
          points: getLatLngPath(),
          color: Colors.blueAccent,
          width: 5,
        ),
      }, // Allow user to control map
      zoomControlsEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
    ),
  ),
),   
        ],
        )
        );
  }
  Widget _buildStat (String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            ),
        ),
      ],
    );
  }
  String formatDuration(Duration d) { // Format the time taken in activity to string minutes and seconds
  int minutes = d.inMinutes;
  int seconds = d.inSeconds % 60;
  return "$minutes:${seconds.toString().padLeft(2, '0')}";
}
  List<LatLng> getLatLngPath() { // Take the LatLng path and draw the polyline
  return path.map((point) {
    return LatLng(point["lat"]!, point["lng"]!);
  }).toList();
} 

LatLngBounds getBounds(List<LatLng> points) { // Take the positions of the points in the path and create bounds for the map to focus on the center of the route taken in the activity
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;

  for (LatLng point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
}

class StreakBoxNotification extends StatelessWidget { // Class: StreakBoxNotifications for streaks to be displayed in the home page

final int streak;

const StreakBoxNotification({super.key, required this.streak});

@override
  Widget build(BuildContext context) { // Create UI design for the streak notification box, which is shown when the user has a streak of 3 days or more
    return Container (
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 46, 48),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Row (
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "🔥 You have a streak of $streak days.",
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        ],
      ),
      ),
      );
  }
}