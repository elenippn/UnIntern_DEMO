class AuthMeDto {
  final int? id;
  final String? role;
  final String username;
  final String name;
  final String surname;
  final String? companyName;
  final String? companyBio;
  final String? bio;
  final String? studies;
  final String? skills;
  final String? experience;
  final String? profileImageUrl;

  const AuthMeDto({
    required this.id,
    required this.role,
    required this.username,
    required this.name,
    required this.surname,
    required this.companyName,
    required this.companyBio,
    required this.bio,
    required this.studies,
    required this.skills,
    required this.experience,
    required this.profileImageUrl,
  });

  factory AuthMeDto.fromJson(Map<String, dynamic> json) {
    return AuthMeDto(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      role: json['role'] as String?,
      username: (json['username'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      surname: (json['surname'] ?? '') as String,
      companyName: json['companyName'] as String?,
      companyBio: json['companyBio'] as String?,
      bio: json['bio'] as String?,
      studies: json['studies'] as String?,
      skills: (json['skills'] ?? json['skillset']) as String?,
      experience: json['experience'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
