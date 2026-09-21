import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  Future<void> saveActivity(Map<String, dynamic> activity) async { // This will save the activity to the database under the user's collection of activities, this will be called when the user records an activity in the record page
    final user = auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .add(activity);
  }

  Stream<List<Map<String, dynamic>>> activitiesStream() { // This will take the activites from the database and return a stream of the activities for the user, this will be used in the home page to show the user their recent activities and also in the profile page to show the user their activity history
    final user = auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .orderBy('dateAndTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }
}