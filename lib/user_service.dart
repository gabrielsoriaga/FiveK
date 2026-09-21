import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getCurrentUserData() async { // Take user current data from database
    final user = auth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> updateBio(String bio) async {
    final user = auth.currentUser;
    if (user == null) return;

    await firestore.collection('users').doc(user.uid).update({
      'bio': bio,
    });
  }

  Future<void> addPoints(int points) async { // Add points to the user's total points in the database, this will be called when the user completes a challenge in the record page
    final user = auth.currentUser;
    if (user == null) return;

    await firestore.collection('users').doc(user.uid).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  DateTime? parseFirestoreDate(dynamic rawDate) { // This will take a date from Firestore and parse it into a DateTime object, this is needed because Firestore can store dates as either Timestamps or DateTime objects depending on how they were saved
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }
    if (rawDate is DateTime) {
      return rawDate;
    }
    return null;
  }

  bool isStreakCurrentlyActive({ // This will check if the user's streak is currently active based on the number of streak days and the last run date, this will be used to determine if the user has access to certain challenges and also to show the user their current streak status in the home page and profile page
    required int streakDays,
    required DateTime? lastRunDate,
    int minDays = 3,
  }) {
    if (streakDays < minDays) return false;
    if (lastRunDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastRunDate.year,
      lastRunDate.month,
      lastRunDate.day,
    );

    return today.difference(lastDate).inDays <= 1;
  }

  Future<bool> getCurrentUserStreakActive({int minDays = 3}) async { // This will get the user's current streak status by fetching the user's data from the database and then checking if the streak is active using the isStreakCurrentlyActive method, this will be used in the home page and profile page to show the user their current streak status and also to determine if they have access to certain challenges
    final data = await getCurrentUserData();
    if (data == null) return false;

    final int streakDays = data["streakDays"] ?? 0;
    final DateTime? lastRunDate = parseFirestoreDate(data["lastRunDate"]);

    return isStreakCurrentlyActive(
      streakDays: streakDays,
      lastRunDate: lastRunDate,
      minDays: minDays,
    );
  }
}