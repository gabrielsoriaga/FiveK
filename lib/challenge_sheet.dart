import 'package:flutter/material.dart';
import 'challenge.dart';

class ChallengeSheet extends StatelessWidget { // Create UI for the challenge sheet that will show the user the challenges they can choose from, this will be shown when the user clicks on the "Choose Challenge" button in the record page, this will also show the user which challenge they have currently selected and which challenges are locked and unlocked based on their current streak
  final List<Challenge> challenges;
  final Challenge? selectedChallenge;
  final String currentTitle;
  final bool Function(Challenge) isUnlocked;
  final void Function(Challenge) onChoose;

  const ChallengeSheet({
    super.key,
    required this.challenges,
    required this.selectedChallenge,
    required this.currentTitle,
    required this.isUnlocked,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C30),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Challenges",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          ...challenges.map((challenge) {
            final unlocked = isUnlocked(challenge);
            final selected = selectedChallenge?.id == challenge.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChallengeTile(
                challenge: challenge,
                unlocked: unlocked,
                selected: selected,
                onChoose: unlocked ? () => onChoose(challenge) : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class ChallengeTile extends StatelessWidget { // Create UI for the challenge tile which will update its color and system will take it as selected challenge
  final Challenge challenge;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onChoose;

  const ChallengeTile({
    super.key,
    required this.challenge,
    required this.unlocked,
    required this.selected,
    required this.onChoose,
  });

  Color getTierColor() {
    switch (challenge.tier) {
      case ChallengeTier.bronze:
        return const Color(0xFFCD7F32);
      case ChallengeTier.silver:
        return const Color(0xFFC0C0C0);
      case ChallengeTier.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? Colors.lightBlue
            : unlocked
                ? const Color(0xFF7A7A7A)
                : const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: getTierColor(),
            child: const Icon(Icons.emoji_events, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unlocked
                  ? challenge.title
                  : "You have yet to unlock ${challenge.tier.name[0].toUpperCase()}${challenge.tier.name.substring(1)} Tier challenges. Level up to unlock ${challenge.tier.name[0].toUpperCase()}${challenge.tier.name.substring(1)}",
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onChoose,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              disabledBackgroundColor: Colors.grey,
            ),
            child: const Text("Choose"),
          ),
        ],
      ),
    );
  }
}