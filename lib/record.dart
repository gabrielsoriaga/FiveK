import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc ;
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'constants.dart';
import 'challenge_manager.dart';
import 'challenge_sheet.dart';
import 'dart:math';
import 'activity_service.dart';
import 'user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class RecordPage extends StatefulWidget {

  final VoidCallback onBack;
  final String currentUserTitle;
  const RecordPage({super.key, required this.onBack, required this.currentUserTitle});


  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {

  // Declare variables to be used across the file

  // Declare controller to take textfields as variables to display in homepage
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController(); 

  // Declare stats variables
  double totalDistance = 0.0; // in km 
  Duration elapsedTime = Duration.zero;
  Timer? _timer;

  int pointsEarned = 0;


  final StreakManager streakManager = StreakManager();

  bool isTracking = false; // True when play is pressed
  bool isPaused = false;   // True when paused
  List<LatLng> trackedPath = []; // Stores locations for polyline

  LatLng? startLocation; // Take user current location as the start location of the run
  LatLng? endLocation; // take user current location as the end location of the run, this will be updated as the user moves
  LatLng? _currentLocation; // Take user current location to show on the map and update as the user moves
  late StreamSubscription<loc.LocationData> _locationSubscription; 
  loc.Location _locationController = loc.Location();
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  Map<PolylineId, Polyline> _polylines = {};

  final ChallengeManager challengeManager = ChallengeManager();

  @override
  void initState() {
  super.initState();
  _initStreak();
  getLocationUpdates().then(
  (_) => {
    getPolylinePoints(startLocation, endLocation).then((coordinates) => {
      print(coordinates),
      generatePolylineFromPoints(coordinates)
    }),
  }
);
}

Future<void> _initStreak() async {
  await streakManager.loadStreak();
}

  @override
  Widget build(BuildContext context) { // Build whole UI for the record page
    print("🏠 Building RecordPage"); // Print debug
    print("User Title: ${widget.currentUserTitle}");
    return Scaffold(
      body: Stack( // Create Stack for map layout and back button, Lower items would stack upfront while top items will stack behind
          children: [
            _currentLocation == null ? const Center(child: CircularProgressIndicator()) : // Show loading indicator while waiting for location data
            GoogleMap(
              onMapCreated: (controller) {
             _mapController.complete(controller);
              },
              initialCameraPosition: CameraPosition( // Set Google Map with the current location of the user as the target
              target: _currentLocation!, 
              zoom: 15,
              ),
              markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: _currentLocation!, // Take the current location of the user and place a marker on the map 
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(title: "You are here"),
                  ),
              },
              polylines: Set<Polyline>.of(_polylines.values), // This is for the polyline to show the path of the run

              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              ),
              if (challengeManager.hasSelectedChallenge &&
    challengeManager.selectedChallenge != null) // Only display the challenge if the user has selected a challenge from the challenge menu, this will show the user which challenge they are currently doing and encourage them to complete it
  Positioned(
    top: 70,
    left: 20,
    right: 20,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              challengeManager.selectedChallenge!.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
            Positioned(
            top: 16, // distance from top
            left: 16, // distance from left
            child: FloatingActionButton( // Create button for drop down to navigate back to HomePage
              onPressed: () {
              widget.onBack();
              print("Back Button Pressed");
              },
              child: const Icon(Icons.arrow_back),
              backgroundColor: const Color(0xFF2C2C30),
          )
            ),
            Positioned (
              top: 16, // distance from bottom
              right: 16, // distance from left
              width: 100, // width of the button
              height: 50, // height of the button
              child: FloatingActionButton( // Create challenge button menu
                onPressed: () {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return ChallengeSheet( // Take UI from Challenge Sheet class
            challenges: challengeManager.getVisibleChallenges(widget.currentUserTitle),
            selectedChallenge: challengeManager.selectedChallenge,
            currentTitle: widget.currentUserTitle,
            isUnlocked: (challenge) =>
                challengeManager.isUnlocked(challenge, widget.currentUserTitle),
            onChoose: (challenge) {
              final success =
                  challengeManager.selectChallenge(challenge, widget.currentUserTitle);

              if (success) {
                setState(() {});
                setModalState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text("${challenge.title} selected"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text("Gold tier is locked until you unlock Advanced Runner"),
                  ),
                );
              }
            },
          );
        },
      );
    },
  );

                },
                child: const Text(
                  "Challenge",
                style: TextStyle(
                  color: Colors.white,
                )),
                backgroundColor: const Color(0xFF2C2C30),
              )
            ),
Positioned( // Create the performance statistics widget, which will show the distance, time and pace of the run, this will be shown on the bottom of the screen when the user finishes the run and presses the save button
  left: 16,
  right: 16,
  bottom: 20,
  child: SafeArea(
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 75,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 46, 48),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(getFormattedTime(), "Time"),
              _buildStat(getPace(), "Avg. Pace(/km)"),
              _buildStat(totalDistance.toStringAsFixed(2), "Distance(km)"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActionBar(
          currentLocation: _currentLocation,
          isTracking: isTracking,
          onStart: startTracking,
          onPause: pauseTracking,
          onStop: stopTracking,
          onShowDetails: showRunDetailsSheet,
        ),
      ],
    ),
  ),
)
          ]
      )
    );

  }
   Widget _buildStat(String title, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
     mainAxisSize: MainAxisSize.min, 
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            ),
        ),
      ],
    );
  }

void showRunDetailsSheet() { // Create sheet for saving an activity
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // important
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9, // 👈 opens at 90%
        minChildSize: 0.4,     // 👈 can collapse
        maxChildSize: 0.95,    // 👈 almost full screen
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildSheetContent(scrollController),
          );
        },
      );
    },
  );
}

Widget _buildSheetContent(ScrollController scrollController) {
  return SingleChildScrollView(
    controller: scrollController,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

       
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        
        const Text(
          "New Activity",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Title",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Include title text field
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Give your run a title...",
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 15),

        Text(
          "Bio",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Include bio text field
        TextField(
          controller: _bioController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "How did it feel?",
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 25),

        // Display Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _summaryStat(totalDistance.toStringAsFixed(2), "km"),
            _summaryStat(getFormattedTime(), "time"),
            _summaryStat(getPace(), "pace"),
          ],
        ),
        
        // Display points earned
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 25),
          if (totalDistance >= 1 )
           Text(
          "+100 points: Reached 1km",
            style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (totalDistance >= 2.5)
            Text(
            "+200 points: Reached 2.5km",
             style: TextStyle(color: Colors.white, fontSize: 16),
             ),
             if (totalDistance >= 5 )
               Text(
              "+500 points: Reached 5km",
             style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (totalDistance >= 10)
               Text(
              "+1000 points: Reached 10km",
             style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
),
if (challengeManager.hasSelectedChallenge) // Display if the user has completed a challenge or not
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      challengeManager.hasCompletedChallenge
          ? "✅ Challenge completed! Bonus +${challengeManager.getChallengeBonusPoints()} points"
          : "❌ Challenge not completed",
      style: TextStyle(
        color: challengeManager.hasCompletedChallenge
            ? Colors.greenAccent
            : Colors.redAccent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
        
        if (streakManager.isStreakActive()) // Display if the user has unlocked a streak
        Text(
        "🔥 2x Streak Points Multiplier",
         style: TextStyle(color: Colors.white, fontSize: 16),
        ),

        const SizedBox(height: 20),

        // Display total points earned for the run
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text(
                "You earned a total of $pointsEarned points 🎉",
                style: TextStyle(color: Colors.blueAccent, fontSize: 16),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Save button
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  saveActivity();
                  print("Save Activity Button Pressed");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Save Activity"),
              ),
            ),
            const SizedBox(height: 30),
             // Discard Button
            TextButton(
              onPressed: () {
                discardActivity();
                print("Discard Activity Button Pressed");
              },
              child: const Text(
                "Discard Activity",
                style: TextStyle(color: Colors.blueAccent),
              ),
            )
          ],
        ),
      ],
    ),
  );
}

Widget _summaryStat(String value, String label) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    ],
  );
}

  void startTracking() { // Start tracking the user location when play button is pressed, this will also set the start location of the run to the current location of the user
  if (_currentLocation != null) {
    setState(() {
        // If NOT paused → fresh start
      if (!isPaused) {
        startLocation = _currentLocation;
        trackedPath = [startLocation!];
        totalDistance = 0.0;
        elapsedTime = Duration.zero;
      }
      isTracking = true;
      isPaused = false;
    });
    print("Tracking started at: $startLocation");
    _startTimer(); // Start the timer when tracking starts
  }
}

void pauseTracking() { // Pause tracking the user location when pause button is pressed, this will not update the end location of the run until the user presses the play button again to resume tracking
  setState(() {
    isPaused = true;
    isTracking = false;
  });
  _timer?.cancel(); // Pause the timer when tracking is paused
  print("Tracking paused");
}

Future<void> stopTracking() async { // Stop tracking will stop the timer and update the end location of the run to the current location of the user, this will also calculate the points earned for the run based on the distance and if the user has a streak or not, this will be shown in the statistics widget in the save activity sheet
  if (_currentLocation == null) return;

  // stop UI immediately
  _timer?.cancel();

  setState(() {
    isTracking = false;
    isPaused = false;
    endLocation = _currentLocation;
    trackedPath.add(endLocation!);

    pointsEarned = calculatePoints(totalDistance);

   final completed = challengeManager.evaluateChallenge(
  totalDistance: totalDistance,
  elapsedTime: elapsedTime,
);

if (completed) {
  final bonus = challengeManager.getChallengeBonusPoints();
  pointsEarned += bonus;
}
  });

  generatePolylineFromPoints(trackedPath);

  // do database updates after UI already stopped
  await _finishRunUpdates();
}

Future<void> _finishRunUpdates() async {
  await streakManager.loadStreak();
  await streakManager.updateStreak();
  await UserService().addPoints(pointsEarned);
}

void _startTimer() {  //Declare timer start method
  _timer?.cancel();
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      elapsedTime += Duration(seconds: 1);
    });
  });
}

double calculateDistance(LatLng start, LatLng end) { // Declare Calculate Distance method using haversine Formula
  const double R = 6371; // Earth radius in km

  double dLat = (end.latitude - start.latitude) * (3.141592653589793 / 180); // Convert degrees to radians by pi/ 180
  double dLon = (end.longitude - start.longitude) * (3.141592653589793 / 180);

  double a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(start.latitude * (3.141592653589793 / 180)) *
          cos(end.latitude * (3.141592653589793 / 180)) *
          (sin(dLon / 2) * sin(dLon / 2));

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c;
}

String getPace() { // Calculate pace by dividing elapsed time by total distance, this will return the average pace per kilometer for the run
  if (totalDistance <= 0) return "-:--";

  double paceSeconds = elapsedTime.inSeconds / totalDistance;

  int minutes = paceSeconds ~/ 60;
  int seconds = (paceSeconds % 60).toInt();

  return "$minutes:${seconds.toString().padLeft(2, '0')}";
}

String getFormattedTime() { // Format the time to show minutes and seconds in the statistics widget
  int minutes = elapsedTime.inMinutes;
  int seconds = elapsedTime.inSeconds % 60;

  return "$minutes:${seconds.toString().padLeft(2, '0')}";
}

int calculatePoints(double distance) { // This is for the points system, the user will earn points based on the distance of the run, this will be used in the challenge system to compare with other users
  int totalPoints = 0; // Base points for completing a run, this will be adjusted based on the distance of the run
  if (distance >= 1) totalPoints += 100;     // 1km milestone
  if (distance >= 2.5) totalPoints += 200;   // 2.5km milestone
  if (distance >= 5) totalPoints += 500;     // 5km milestone
  if (distance >= 10) totalPoints += 1000;   // 10km milestone

  if (streakManager.isStreakActive()) { // Bonus points for having a streak, this will encourage users to run consistently and maintain their streaks
    totalPoints *= 2;
  }
  return totalPoints;
}

void saveActivity() async { // Save activity and navigate user to back to homepage

  final userData = await UserService().getCurrentUserData();

  String locationName = "Unknown Location";

  if (_currentLocation != null) {
    locationName = await getLocationName(_currentLocation!);
  }

  Map<String, dynamic> newActivity = {
  "user": userData?["username"] ?? "User",
  "dateAndTime": DateTime.now(),
  "location": locationName,
  "title": _titleController.text,
  "bio": _bioController.text,
  "distance": totalDistance,
  "pace": getPace(),
  "timeSeconds": elapsedTime.inSeconds,
  "earnedPoints": pointsEarned,
  "path": trackedPath
      .map((e) => {"lat": e.latitude, "lng": e.longitude})
      .toList(),
};
  
  // Save to database
  await ActivityService().saveActivity(newActivity);

  if (challengeManager.hasCompletedChallenge) {
  challengeManager.advanceChallengeLoop(widget.currentUserTitle);
}

challengeManager.clearSelection();

   // Pop scrollable widget
   Navigator.of(context).pop(); 

   print("SAVING ACTIVITY:");
   print("streakDays: ${streakManager.streakDays}");
   print("isActive: ${streakManager.isStreakActive()}");

  // Pop RecordPage with data so HomePage receives it
   Navigator.of(context).pop({
     "activity": newActivity,
     "streakDays": streakManager.streakDays,
     "isActive": streakManager.isStreakActive(),
});
}

void discardActivity() async {
  Navigator.of(context).pop(); 
  Navigator.of(context).pop();
}

Future<String> getLocationName(LatLng position) async {
  try {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;

      return "${place.locality}, ${place.country}";
      // Example: "Dubai, UAE"
    }
  } catch (e) {
    print("Error getting location: $e");
  }

  return "Unknown Location";
}


  Future<void> cameraToPosition(LatLng position) async { // This is for the camera to move to the current location of the user
    if (!mounted) return; // ✅ prevents setState after dispose
    final GoogleMapController controller = await _mapController.future;
    if (!mounted) return; // ✅ prevents setState after dispose
    await controller.animateCamera(CameraUpdate.newLatLngZoom(position, 17)
        ); 
  }

  Future<void> getLocationUpdates() async { // Request permission for Location Tracking and find current location
  bool _serviceEnabled;
  loc.PermissionStatus _permissionGranted;

  _serviceEnabled = await _locationController.serviceEnabled(); // Check if User has enabled location services
  if (!_serviceEnabled) { 
    _serviceEnabled = await _locationController.requestService(); // Asks user to turn on service
    } if (!_serviceEnabled) {
      return;
    }

  _permissionGranted = await _locationController.hasPermission(); // Check if app has permission to access location
  if (_permissionGranted == loc.PermissionStatus.denied) {
    _permissionGranted = await _locationController.requestPermission(); // Asks user to grant permission for location access
    if (_permissionGranted != loc.PermissionStatus.granted) {
      return;
    }
  }
  
  _locationSubscription = _locationController.onLocationChanged.listen((loc.LocationData currentLocation) { // This takes the updated location of the user 
    if (!mounted) return; 
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      LatLng newLoc = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      setState(() {
        _currentLocation = newLoc;

        if (isTracking && !isPaused) { // Track and add path to history to create polyline 
        trackedPath.add(newLoc);
        
        if (trackedPath.length > 1) { // This adds a new points and takes the last 2 points to calculate the distance between them and add it to the total distance of the run, this will update the distance stat in the statistics widget
        totalDistance += calculateDistance(
        trackedPath[trackedPath.length - 2],
        trackedPath[trackedPath.length - 1], 
          );
        }
        generatePolylineFromPoints(trackedPath); // Update live polyline when tracking is active and not paused
        }

        print("Updated location: ${currentLocation.latitude}, ${currentLocation.longitude}");
      });
    }  cameraToPosition(_currentLocation!); // Move the camera to the current location of the user
  });
}

@override
void dispose() { // The dispose method allows the terminal to stop listening to location updates when the user navigates away from the RecordPage, which is important for conserving battery life and system resources. If we did not cancel the subscription, the app would continue to receive location updates even when the user is not on the RecordPage, which could lead to unnecessary battery drain and potential memory leaks.
   _timer?.cancel();
  _locationSubscription.cancel();
  _titleController.dispose();
  _bioController.dispose();
  super.dispose();
}

  Future<List<LatLng>> getPolylinePoints(LatLng? start, LatLng? end) async { // This is for the polyline to show the path of the run
    
    if (start == null || end == null) return [];

    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);
    
    PolylineRequest request = PolylineRequest(
    origin: PointLatLng(start.latitude, start.longitude),
    destination: PointLatLng(end.latitude, end.longitude),
    mode: TravelMode.walking, // now part of request
  );
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: request,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print("Error fetching polyline points: ${result.errorMessage}");
    }
    return polylineCoordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blueAccent,
      points: polylineCoordinates,
      width: 8,
    );
    setState(() {
      _polylines[id] = polyline;
    });
  }
}

class ActionBar extends StatefulWidget { // Create Action bar to display stats and buttons
  final bool isTracking;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final Future<void> Function() onStop;
  final VoidCallback onShowDetails;
  final LatLng? currentLocation;

  const ActionBar({
    super.key,
    required this.isTracking,
    required this.onStart,
    required this.onPause,
    required this.onStop,
    required this.onShowDetails,
    this.currentLocation,
  });

  @override
  _ActionBarState createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  
  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        height: 120,
        decoration: BoxDecoration( 
                color: const Color.fromARGB(255, 44, 46, 48),
                borderRadius: BorderRadius.circular(12),
              ),
        child: Row (
          mainAxisAlignment: MainAxisAlignment.center,
          children: [           
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  child: Icon(widget.isTracking ? Icons.pause : Icons.sports),
                  onPressed: () {
                  if (widget.isTracking) {
                    widget.onPause();
                    print("Pause Button has been pressed");
                  } else {
                    print("Menu Button Pressed");
                  }
                  }
                  ),
                  Text (
                widget.isTracking ? "Pause" : "Choose Activity",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              ],
            ),
            SizedBox(width: 10),
              Text (
                  widget.currentLocation != null ? "GPS Acquired" : "GPS Not Acquired",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              SizedBox(width: 20),
              Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                  child: Icon(widget.isTracking ? Icons.stop : Icons.play_arrow, color: Colors.white),
                  backgroundColor: Colors.blueAccent,
                  onPressed: () async {
                    if (widget.isTracking) {
                      await widget.onStop();
                      widget.onShowDetails(); // Show run details when stop button is pressed
                      print("Stop Button has been pressed");
                    } else {
                      widget.onStart();
                      print("Start Button has been pressed");
                    }
                  }, 
                  ),
                  Text (
                widget.isTracking ? "Stop" : "Start",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
                ],
              ),
          ],)
        
    );
  }
}

class StreakManager { // Create a streak manager class that takes current user streak from the database 
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  int streakDays = 0;
  DateTime? lastRunDate;

  Future<void> loadStreak() async { // Load streak from database
  final user = auth.currentUser;
  if (user == null) return;

  final doc = await firestore.collection('users').doc(user.uid).get();
  final data = doc.data();

  if (data != null) {
    streakDays = data["streakDays"] ?? 0;

    final rawDate = data["lastRunDate"];
    if (rawDate is Timestamp) {
      lastRunDate = rawDate.toDate();
    }

    if (lastRunDate != null) {
      final today = DateTime.now();
      final lastDate = DateTime(
        lastRunDate!.year,
        lastRunDate!.month,
        lastRunDate!.day,
      );

      if (today.difference(lastDate).inDays > 1) {
        streakDays = 0;

         await firestore.collection('users').doc(user.uid).update({
          "streakDays": 0,
       });
      }
    }
  }
}

  Future<void> updateStreak() async { // Update streak based on date and time of when the user has done an activity
    final user = auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastRunDate != null) {
      final lastDate =
          DateTime(lastRunDate!.year, lastRunDate!.month, lastRunDate!.day);

      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // same day → no change
      } else if (difference == 1) {
        streakDays++;
      } else {
        streakDays = 1;
      }
    } else {
      streakDays = 1;
    }

    lastRunDate = today;

    await firestore.collection('users').doc(user.uid).update({
      "streakDays": streakDays,
      "lastRunDate": lastRunDate,
    });
  }

  bool isStreakActive({int minDays = 3}) { // Return bool value to determine if streak is active
    if (streakDays < minDays) return false;
    if (lastRunDate == null) return false;

    final today = DateTime.now();
    final lastDate =
        DateTime(lastRunDate!.year, lastRunDate!.month, lastRunDate!.day);

    if (today.difference(lastDate).inDays > 1) return false;

    return true;
  }
}




