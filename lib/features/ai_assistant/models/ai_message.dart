enum AiSender { user, assistant, system }

class AiActionLink {
  final String label;
  final int targetTabIndex;
  final String? actionType;

  const AiActionLink({
    required this.label,
    required this.targetTabIndex,
    this.actionType,
  });
}

class AiMessage {
  final String id;
  final String text;
  final AiSender sender;
  final DateTime timestamp;
  final List<AiActionLink>? actionLinks;
  final List<String>? bulletPoints;
  final String? contextualBadge;

  const AiMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.actionLinks,
    this.bulletPoints,
    this.contextualBadge,
  });
}
