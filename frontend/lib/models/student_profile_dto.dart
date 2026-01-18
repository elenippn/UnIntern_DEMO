class StudentProfileDto {
  final int id;
  final String username;
  final String name;
  final String surname;
  final String? bio;
  final String? studies;
  final String? skills;
  final String? experience;
  final String? profileImageUrl;

  const StudentProfileDto({
    required this.id,
    required this.username,
    required this.name,
    required this.surname,
    required this.bio,
    required this.studies,
    required this.skills,
    required this.experience,
    required this.profileImageUrl,
  });

  factory StudentProfileDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['userId'] ?? json['studentUserId'];
    final int id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return StudentProfileDto(
      id: id,
      username: (json['username'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      surname: (json['surname'] ?? '') as String,
      bio: json['bio'] as String?,
      studies: json['studies'] as String?,
      skills: (json['skills'] ?? json['skillset']) as String?,
      experience: json['experience'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
