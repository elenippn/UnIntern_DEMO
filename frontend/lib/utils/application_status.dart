String normalizeApplicationStatus(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return 'OTHER';

  final upper = value.toUpperCase();

  // Common codes
  if (upper == 'PENDING') return 'PENDING';
  if (upper == 'ACCEPTED') return 'ACCEPTED';
  if (upper == 'DECLINED') return 'DECLINED';
  if (upper == 'PASSED' || upper == 'PASS') return 'DECLINED';

  // Common phrases / variants returned by backend
  if (upper.contains('PENDING')) return 'PENDING';
  if (upper.contains('WAIT')) return 'PENDING';

  // “ready to connect”, “match”, etc.
  if (upper.contains('ACCEPT')) return 'ACCEPTED';
  if (upper.contains('READY')) return 'ACCEPTED';
  if (upper.contains('MATCH')) return 'ACCEPTED';

  // Common declined system copy
  if (upper.contains('UNFORTUN')) return 'DECLINED';
  if (upper.contains('NOT A MATCH')) return 'DECLINED';
  if (upper.contains('NO MATCH')) return 'DECLINED';

  if (upper.contains('DECLIN')) return 'DECLINED';
  if (upper.contains('REJECT')) return 'DECLINED';
  if (upper.contains('PASS')) return 'DECLINED';

  return 'OTHER';
}

String? inferStatusFromSystemText(String? text) {
  final normalized = normalizeApplicationStatus(text);
  if (normalized == 'OTHER') return null;
  return normalized;
}

/// Robust UI status derivation for list screens.
///
/// Some backends update `Conversation` system messages faster than
/// `Application.status`. This merges both so the UI doesn't get stuck in PENDING.
String deriveApplicationStatus({
  required String? applicationStatusRaw,
  String? lastMessage,
  String? lastSystemMessage,
}) {
  final fromStatus = normalizeApplicationStatus(applicationStatusRaw);
  final fromLastMessage = inferStatusFromSystemText(lastMessage);
  final fromSystem = inferStatusFromSystemText(lastSystemMessage);

  // Prefer non-pending evidence over pending.
  const resolved = {'ACCEPTED', 'DECLINED'};
  if (fromSystem != null && resolved.contains(fromSystem)) return fromSystem;
  if (fromLastMessage != null && resolved.contains(fromLastMessage)) {
    return fromLastMessage;
  }
  if (resolved.contains(fromStatus)) return fromStatus;

  // If any source indicates pending, keep it pending.
  if (fromSystem == 'PENDING' || fromLastMessage == 'PENDING') return 'PENDING';
  if (fromStatus == 'PENDING') return 'PENDING';

  return 'OTHER';
}

bool canSendForApplicationStatus(String? raw) {
  return normalizeApplicationStatus(raw) == 'ACCEPTED';
}

String displayApplicationStatus(String? raw) {
  switch (normalizeApplicationStatus(raw)) {
    case 'PENDING':
      return 'Message still pending';
    case 'ACCEPTED':
      return 'Ready to connect';
    case 'DECLINED':
      return 'Unfortunately this was not a match, keep searching';
    default:
      return (raw ?? '').toString();
  }
}
