import 'challenge.dart';

class ChallengeManager { // Create Challenge Logic
  Challenge? selectedChallenge;
  Challenge? completedChallenge;
  bool hasSelectedChallenge = false;
  bool hasCompletedChallenge = false;

  static int bronzeIndex = 0;
  static int silverIndex = 0;
  static int goldIndex = 0;

  final List<Challenge> challenges = const [ // Create list of challenges for the user to choose from, this will be shown in the challenge sheet
    Challenge(
      id: "bronze_2.5k",
      title: "Reach 2.5km",
      description: "Complete a 2.5km run",
      tier: ChallengeTier.bronze,
      bonusPoints: 500,
      targetDistanceKm: 2.5,
    ),
    Challenge(
      id: "bronze_1.5k_10",
      title: "Reach 1.5km under 10 minutes",
      description: "Complete a 1.5km run under 10 minutes",
      tier: ChallengeTier.bronze,
      bonusPoints: 500,
      targetDistanceKm: 1.5,
      maxTime: Duration(minutes: 10),
    ),
    Challenge(
      id: "bronze_3k_30",
      title: "Reach 3km under 30 minutes",
      description: "Complete a 3km run within 30 minutes",
      tier: ChallengeTier.bronze,
      bonusPoints: 500,
      targetDistanceKm: 3.0,
      maxTime: Duration(minutes: 30),
    ),
    Challenge(
      id: "silver_5k_30",
      title: "Reach 5km in under 30 minutes",
      description: "Run 5km within 30 minutes",
      tier: ChallengeTier.silver,
      bonusPoints: 1000,
      targetDistanceKm: 5.0,
      maxTime: Duration(minutes: 30),
    ),
    Challenge(
      id: "silver_7k",
      title: "Reach 7km",
      description: "Run 7km",
      tier: ChallengeTier.silver,
      bonusPoints: 1000,
      targetDistanceKm: 7.0,
    ),
    Challenge(
      id: "silver_3k_10",
      title: "Reach 3km in under 10 minutes",
      description: "Run 3km within 10 minutes",
      tier: ChallengeTier.silver,
      bonusPoints: 1000,
      targetDistanceKm: 3.0,
      maxTime: Duration(minutes: 10),
    ),
    Challenge(
      id: "gold_7k_40",
      title: "Reach 7km in under 40 minutes",
      description: "Gold tier challenge",
      tier: ChallengeTier.gold,
      bonusPoints: 1500,
      targetDistanceKm: 7.0,
      maxTime: Duration(minutes: 40),
      requiredTitle: "Advanced Runner",
    ),
  ];

  bool isUnlocked(Challenge challenge, String currentTitle) { // Check if challenge has been unlocked based on user title
    if (challenge.tier != ChallengeTier.gold) return true;

    const allowedTitles = [
      "Advanced Runner",
      "Elite Runner",
    ];

    return allowedTitles.contains(currentTitle);
  }

  List<Challenge> getChallengesByTier(ChallengeTier tier) { // Get challenges for a specific tier
    return challenges.where((c) => c.tier == tier).toList();
  }

  int _getTierIndex(ChallengeTier tier) { // Get the index for the current challenge in a tier
    switch (tier) {
      case ChallengeTier.bronze:
        return bronzeIndex;
      case ChallengeTier.silver:
        return silverIndex;
      case ChallengeTier.gold:
        return goldIndex;
    }
  }

  void _setTierIndex(ChallengeTier tier, int newIndex) { // Set the index for the current challenge in a tier, this will be used to keep track of which challenge is currently selected for each tier and to advance to the next challenge in the tier when the user completes a challenge
    switch (tier) {
      case ChallengeTier.bronze:
        bronzeIndex = newIndex;
        break;
      case ChallengeTier.silver:
        silverIndex = newIndex;
        break;
      case ChallengeTier.gold:
        goldIndex = newIndex;
        break;
    }
  }

  Challenge? getCurrentChallengeForTier(ChallengeTier tier, String currentTitle) { // Get the current challenge for a specific tier based on the user's title, this will be used to show the current challenge in the challenge sheet and also to determine which challenge is currently selected for the user
    final tierChallenges = getChallengesByTier(tier);

    if (tierChallenges.isEmpty) return null;

    final index = _getTierIndex(tier) % tierChallenges.length;
    return tierChallenges[index];
  }

  List<Challenge> getVisibleChallenges(String currentTitle) { // Get list of challenges that should be visible to the user based on their title, this will be used to show the challenges in the challenge sheet and also to determine which challenges the user can select from
    final List<Challenge> visibleChallenges = [];

    for (final tier in ChallengeTier.values) {
      final challenge = getCurrentChallengeForTier(tier, currentTitle);
      if (challenge != null) {
        visibleChallenges.add(challenge);
      }
    }

    return visibleChallenges;
  }

  bool selectChallenge(Challenge challenge, String currentTitle) { // Select a challenge for the user, this will be called when the user selects a challenge from the challenge sheet, it will check if the challenge is unlocked and if it is, it will set it as the selected challenge
  if (!isUnlocked(challenge, currentTitle)) {
    return false;
  }

  selectedChallenge = challenge;
  completedChallenge = null;
  hasSelectedChallenge = true;
  hasCompletedChallenge = false;
  return true;
}

  bool evaluateChallenge({ // Evaluate if user has completed the selected challenge based on their activity data, this will be called after the user finishes an activity and the system will check if the activity meets the requirements of the selected challenge
  required double totalDistance,
  required Duration elapsedTime,
}) {
  if (selectedChallenge == null) {
    hasCompletedChallenge = false;
    completedChallenge = null;
    return false;
  }

  final challenge = selectedChallenge!;
  final distancePassed = totalDistance >= challenge.targetDistanceKm;
  final timePassed =
      challenge.maxTime == null || elapsedTime <= challenge.maxTime!;

  hasCompletedChallenge = distancePassed && timePassed;
  completedChallenge = hasCompletedChallenge ? challenge : null;

  return hasCompletedChallenge;
}

  void advanceChallengeLoop(String currentTitle) { // If user has completed the challenge, advance to the next one in the same tier, this method does not work
    if (selectedChallenge == null) return;
    if (!hasCompletedChallenge) return;

    final tier = selectedChallenge!.tier;
    final tierChallenges = getChallengesByTier(tier)
        .where((c) => isUnlocked(c, currentTitle))
        .toList();

    if (tierChallenges.isEmpty) return;

    final currentIndex = _getTierIndex(tier);
    final nextIndex = (currentIndex + 1) % tierChallenges.length;

    _setTierIndex(tier, nextIndex);
  }

  int getChallengeBonusPoints() { // Get bonus points if challenge completed
    if (hasCompletedChallenge && completedChallenge != null) {
      return completedChallenge!.bonusPoints;
    }
    return 0;
  }

  void clearSelection() {
    selectedChallenge = null;
    completedChallenge = null;
    hasSelectedChallenge = false;
    hasCompletedChallenge = false;
  }
}