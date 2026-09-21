import 'package:flutter/material.dart';
import 'home.dart';
import 'record.dart';
import 'profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'user_service.dart';
import 'activity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // This line removes the debug banner that appears in the top right corner of the app when running in debug mode. The debug banner is a small label that says "DEBUG" and is meant to indicate that the app is running in debug mode. By setting debugShowCheckedModeBanner to false, you can hide this banner and have a cleaner look while developing your app.
      title: 'FiveK',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed( // See here, the seed color and brightness widget are both inside the colorScheme widget, which means that they are arguments of the colorScheme widget. This means that they are used to customize the color scheme of the app. The seedColor argument is used to generate a color scheme based on a single color, while the brightness argument is used to specify whether the color scheme should be light or dark. By changing these arguments, you can easily customize the look and feel of your app.
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class MainNavigation extends StatefulWidget { // Class for Appbar and Navigation menu
  const MainNavigation({super.key,});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> { // This is a stateful widget because it has a state that can change over time. The state is represented by the _MyHomePageState class, which extends the State class. The build method of the _MyHomePageState class is called whenever the state changes, and it returns a widget tree that describes how to display the UI based on the current state. In this case, we have a variable called myIndex that keeps track of which item is currently selected in the bottom navigation bar. When the user taps on an item in the bottom navigation bar, we update the myIndex variable and call setState to trigger a rebuild of the UI with the new state.
  
  String userName = "Loading...";
  
  int myIndex = 0;
  
  final List<String> pageTitles = ["Home", "Record", "Profile"];
  
  bool showScaffold = true;

  late List<Widget> pages;

  final ActivityService activityService = ActivityService();

  int streakDays = 0;

  bool isStreakActive = false;

  int totalPoints = 0;

  @override
void initState() {
  super.initState();
  loadUserData();
}

  void onTabTapped(int index) async { // Create method for navigation between pages including to load the data from other pages
  if (index == 1) {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordPage(
          onBack: () => Navigator.pop(context),
          currentUserTitle: getUserTitle(),
        ),
      ),
    );

    setState(() {
      if (result != null) {
        streakDays = result["streakDays"];
        isStreakActive = result["isActive"] ?? false;
      }
      myIndex = 0; // always return to Home after leaving Record
      showScaffold = true;
    });
    await loadUserData();
    return;
  }
  setState(() {
    myIndex = index;
    showScaffold = true;
  });
}

Future<void> loadUserData() async {
  final userService = UserService();
  final data = await UserService().getCurrentUserData();

  if (data != null) {
    final streakActive = await userService.getCurrentUserStreakActive();
    setState(() {
      userName = data["username"] ?? "User";
      totalPoints = data["totalPoints"] ?? 0;
      streakDays = data["streakDays"] ?? 0;
      isStreakActive = streakActive;
    });
  }
}

String getUserTitle() {
  if (totalPoints >= 30000) return "Elite Runner";
  if (totalPoints >= 20000) return "Advanced Runner";
  if (totalPoints >= 10000) return "Intermediate Runner";
  if (totalPoints >= 3000) return "Active Runner";
  if (totalPoints >= 1000) return "Beginner Runner";
  return "New Runner";
}

  @override
Widget build(BuildContext context) { // Build the UI for the main navigation, with passing the data 
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: activityService.activitiesStream(),
    builder: (context, snapshot) {
      final activities = snapshot.data ?? [];

      pages = [
        HomePage(
          userName: userName,
          streakDays: streakDays,
          activities: activities,
          isStreakActive: isStreakActive,
        ),
        const SizedBox(),
        ProfilePage(
          userName: userName,
          totalPoints: totalPoints,
          activities: activities,
        ),
      ];

      return Scaffold(
        appBar: showScaffold
            ? AppBar( // Create app bar with title based on page
                centerTitle: true,
                backgroundColor: const Color.fromARGB(255, 44, 46, 48),
                title: Text(pageTitles[myIndex]),
              )
            : null,
        body: snapshot.connectionState == ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            : pages[myIndex],
        bottomNavigationBar: showScaffold // Create bottom navigation menu
            ? BottomNavigationBar(
                onTap: onTabTapped,
                currentIndex: myIndex,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fiber_manual_record),
                    label: "Record",
                    backgroundColor: Colors.lightBlue,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: "Profile",
                  )
                ],
              )
            : null,
      );
    },
  );
}
}