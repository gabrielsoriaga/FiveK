
// Declare Challenge Tiers
enum ChallengeTier { bronze, silver, gold }

// Declare parent class with variables for manager and sheet
class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeTier tier;
  final int bonusPoints;
  final double targetDistanceKm;
  final Duration? maxTime;
  final String requiredTitle;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.bonusPoints,
    required this.targetDistanceKm,
    this.maxTime,
    this.requiredTitle = "",
  });

  bool get isTimed => maxTime != null;
}