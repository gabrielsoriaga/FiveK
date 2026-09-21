import 'package:flutter/material.dart';
import 'weekly_progress_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

// Profile screen that shows user info, stats, and achievements
class ProfilePage extends StatefulWidget {

  // data passed into profile page
  final String userName;
  final int totalPoints;
  final List<Map<String, dynamic>> activities;
  
  const ProfilePage({
    super.key,
    required this.userName,
    required this.totalPoints,
    required this.activities,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // stores user bio
  String bio = "Add your bio here...";

  @override
  void initState() {
    super.initState();
    _loadBio(); // load bio when page opens
  }

  // fetch bio from database
  Future<void> _loadBio() async {
    final data = await UserService().getCurrentUserData();
    
    setState(() {
      bio = data?["bio"] ?? "Add your bio here...";
    });
  }

  // save updated bio to database
  Future<void> _saveBio(String newBio) async {
    await UserService().updateBio(newBio);

    setState(() {
      bio = newBio;
    });
  }

  // shows popup dialog to edit bio
  void _showEditBioDialog() {
    final controller = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Bio"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Write something about yourself...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            // cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            // save button
            ElevatedButton(
              onPressed: () {
                _saveBio(controller.text.trim().isEmpty
                    ? "Add your bio here..."
                    : controller.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // determine level based on total points
  int getLevelFromPoints(int points) {
    if (points < 1000) return 1;
    if (points < 2500) return 2;
    if (points < 5000) return 3;
    if (points < 8000) return 4;
    if (points < 12000) return 5;
    if (points < 17000) return 6;
    if (points < 23000) return 7;
    if (points < 30000) return 8;
    if (points < 38000) return 9;
    return 10;
  }

  // minimum points for current level
  int getPointsForCurrentLevel(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 1000;
      case 3: return 2500;
      case 4: return 5000;
      case 5: return 8000;
      case 6: return 12000;
      case 7: return 17000;
      case 8: return 23000;
      case 9: return 30000;
      case 10: return 38000;
      default: return 0;
    }
  }

  // points needed to reach next level
  int getPointsForNextLevel(int level) {
    switch (level) {
      case 1: return 1000;
      case 2: return 2500;
      case 3: return 5000;
      case 4: return 8000;
      case 5: return 12000;
      case 6: return 17000;
      case 7: return 23000;
      case 8: return 30000;
      case 9: return 38000;
      case 10: return 50000;
      default: return 50000;
    }
  }

  // gives user a title based on level
  String getTitleFromLevel(int level) {
    if (level >= 10) return "Elite Runner";
    if (level >= 8) return "Advanced Runner";
    if (level >= 6) return "Intermediate Runner";
    if (level >= 4) return "Active Runner";
    if (level >= 2) return "Beginner Runner";
    return "New Runner";
  }

  // list of achievements (locked/unlocked)
  List<Map<String, dynamic>> getAchievements(int level, int points) {
    return [
      {"title": "Reached Level 2", "icon": Icons.emoji_events, "unlocked": level >= 2},
      {"title": "Reached Level 4", "icon": Icons.workspace_premium, "unlocked": level >= 4},
      {"title": "Intermediate Title", "icon": Icons.military_tech, "unlocked": level >= 6},
      {"title": "Advanced Title", "icon": Icons.stars, "unlocked": level >= 8},
      {"title": "Elite Runner", "icon": Icons.local_fire_department, "unlocked": level >= 10},
      {"title": "10,000 Total Points", "icon": Icons.bolt, "unlocked": points >= 10000},
    ];
  }

  @override
  Widget build(BuildContext context) {

    // calculate level and progress
    final int level = getLevelFromPoints(widget.totalPoints);
    final String title = getTitleFromLevel(level);

    final int currentLevelPoints = getPointsForCurrentLevel(level);
    final int nextLevelPoints = getPointsForNextLevel(level);
    final int pointsNeeded = nextLevelPoints - widget.totalPoints;

    final double progress = ((widget.totalPoints - currentLevelPoints) /
            (nextLevelPoints - currentLevelPoints))
        .clamp(0.0, 1.0);

    final achievements = getAchievements(level, widget.totalPoints);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 44, 46, 48),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [

                  // top section (avatar + name + level)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 12),

                      // username + title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // level + progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Level $level",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 130,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$pointsNeeded points till Level ${level + 1}",
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // bio section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Bio",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      bio,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // edit bio button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: _showEditBioDialog,
                      child: const Text("Edit Profile"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // achievements section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Achievements",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // display achievement icons
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: achievements.map((achievement) {
                      final bool unlocked = achievement["unlocked"];

                      return SizedBox(
                        width: 90,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: unlocked
                                  ? Colors.amber
                                  : Colors.grey.shade700,
                              child: Icon(
                                achievement["icon"],
                                color: unlocked ? Colors.black : Colors.white54,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              achievement["title"],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: unlocked
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // weekly progress section
                  WeeklyProgressWidget(
                    activities: widget.activities,
                  ),

                  // logout button
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text("Logout"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}