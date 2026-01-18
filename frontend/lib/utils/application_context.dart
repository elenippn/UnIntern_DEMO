String _firstNonEmptyString(dynamic v) {
  if (v is String) {
    final t = v.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

String _stringFromMap(Map m, List<String> keys) {
  for (final k in keys) {
    final s = _firstNonEmptyString(m[k]);
    if (s.isNotEmpty) return s;
  }
  return '';
}

int? _intFromMap(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is int) return v;
    final parsed = int.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

/// Best-effort extraction of the internship/ad title from an item returned
/// by `GET /applications`.
///
/// Backend payloads vary, so this checks a list of common keys and nested
/// objects (post/internship/listing/job).
String extractAdLabel(Map item) {
  const titleKeys = <String>[
    'internshipTitle',
    'internship_post_title',
    'postTitle',
    'listingTitle',
    'adTitle',
    'jobTitle',
    'position',
    'role',
    'title',
    'name',
  ];

  // 1) Direct fields on the application
  final direct = _stringFromMap(item, titleKeys);
  if (direct.isNotEmpty) return direct;

  // 2) Common nested objects
  const nestedKeys = <String>[
    'post',
    'internshipPost',
    'internship',
    'listing',
    'job',
    'offer',
  ];

  for (final nk in nestedKeys) {
    final nested = item[nk];
    if (nested is Map) {
      final fromNested = _stringFromMap(nested, titleKeys);
      if (fromNested.isNotEmpty) return fromNested;
    }
  }

  // 3) Fallback: show an id if present so the user can distinguish ads.
  final id = _intFromMap(item, const [
    'postId',
    'internshipPostId',
    'internship_id',
    'listingId',
    'jobId',
    'studentPostId',
    'companyPostId',
    'adId',
  ]);

  return id == null ? '' : 'Ad #$id';
}

String buildConversationListTitle({
  required String otherPartyName,
  required String adLabel,
}) {
  final party = otherPartyName.trim();
  final ad = adLabel.trim();
  if (party.isEmpty) return ad;
  if (ad.isEmpty) return party;
  return '$party — $ad';
}
