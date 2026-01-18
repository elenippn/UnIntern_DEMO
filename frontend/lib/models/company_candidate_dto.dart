class CompanyCandidateDto {
  final int studentUserId;
  final int? studentPostId;
  final String name;
  final String? university;
  final String? department;
  final String? bio;
  final String? studies;
  final String? skills;
  final String? experience;
  final bool saved;

  // imageUrl: student profile post image (card)
  final String? imageUrl;

  // studentProfileImageUrl: student's user profile avatar image
  final String? studentProfileImageUrl;

  const CompanyCandidateDto({
    required this.studentUserId,
    required this.studentPostId,
    required this.name,
    required this.university,
    required this.department,
    required this.bio,
    required this.studies,
    required this.skills,
    required this.experience,
    required this.saved,
    required this.imageUrl,
    required this.studentProfileImageUrl,
  });

  static String? _emptyToNull(String? value) {
    if (value == null) return null;
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  static ({String? bio, String? skills, String? studies, String? experience})
      _parseLegacyBio(String? raw) {
    final text = _emptyToNull(raw);
    if (text == null) {
      return (bio: null, skills: null, studies: null, experience: null);
    }

    final RegExp taggedLine = RegExp(
      r'^(skills|skillset|studies|experience|university)\s*:\s*(.*)$',
      caseSensitive: false,
    );

    String? skills;
    String? studies;
    String? experience;
    final keptLines = <String>[];

    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      final m = taggedLine.firstMatch(trimmed);
      if (m == null) {
        keptLines.add(line);
        continue;
      }

      final key = m.group(1)!.toLowerCase();
      final value = _emptyToNull(m.group(2));
      if (value == null) {
        continue;
      }

      switch (key) {
        case 'skills':
        case 'skillset':
          skills ??= value;
          break;
        case 'studies':
          studies ??= value;
          break;
        case 'experience':
          experience ??= value;
          break;
        case 'university':
          // Intentionally drop this from the bio to avoid showing stale/incorrect
          // universities in the feed card. We rely on canonical `studies`.
          break;
      }
    }

    final cleanedBio = _emptyToNull(keptLines.join('\n'));
    return (
      bio: cleanedBio,
      skills: skills,
      studies: studies,
      experience: experience
    );
  }

  factory CompanyCandidateDto.fromJson(Map<String, dynamic> json) {
    final rawStudentUserId =
        json['studentUserId'] ?? json['id'] ?? json['userId'];
    final studentUserId = rawStudentUserId is int
        ? rawStudentUserId
        : int.tryParse(rawStudentUserId?.toString() ?? '') ?? 0;

    final rawStudentPostId = json['studentPostId'] ?? json['postId'];
    final studentPostId = rawStudentPostId is int
        ? rawStudentPostId
        : int.tryParse(rawStudentPostId?.toString() ?? '');

    final rawName = (json['name'] ??
        json['studentName'] ??
        json['fullName'] ??
        '') as String;

    final String? jsonBio = (json['bio'] ?? json['description']) as String?;
    final parsed = _parseLegacyBio(jsonBio);

    final String? studies =
        _emptyToNull(json['studies'] as String?) ?? parsed.studies;
    final String? skills =
        _emptyToNull((json['skills'] ?? json['skillset']) as String?) ??
            parsed.skills;
    final String? experience =
        _emptyToNull(json['experience'] as String?) ?? parsed.experience;

    String? department = (json['department'] ?? json['major']) as String?;
    if ((department == null || department.trim().isEmpty) && studies != null) {
      final firstLine = studies.split('\n').map((e) => e.trim()).firstWhere(
            (e) => e.isNotEmpty,
            orElse: () => '',
          );
      if (firstLine.isNotEmpty) department = firstLine;
    }

    return CompanyCandidateDto(
      studentUserId: studentUserId,
      studentPostId: studentPostId,
      name: rawName,
      university: json['university'] as String?,
      department: department,
      bio: parsed.bio,
      studies: studies,
      skills: skills,
      experience: experience,
      saved: (json['saved'] ?? false) == true,
      imageUrl: json['imageUrl'] as String?,
      studentProfileImageUrl: json['studentProfileImageUrl'] as String?,
    );
  }
}
