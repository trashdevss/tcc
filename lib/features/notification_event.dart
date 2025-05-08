class NotificationEvent {
  final String package;
  final String title;
  final String text;

  NotificationEvent({
    required this.package,
    required this.title,
    required this.text,
  });

  factory NotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    return NotificationEvent(
      package: map['package'] ?? '',
      title: map['title'] ?? '',
      text: map['text'] ?? '',
    );
  }
}
