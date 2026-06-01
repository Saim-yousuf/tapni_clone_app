class Activity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
}

enum ActivityType {
  view,
  scan,
  lead,
  share,
  system,
}
