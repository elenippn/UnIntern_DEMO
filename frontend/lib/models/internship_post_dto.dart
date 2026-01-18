class InternshipPostDto {
  final int id;
  final String? companyName;
  final String? profileImageUrl;
  final String title;
  final String description;
  final String? department;
  final String? location;
  final bool saved;
  final String? imageUrl;
  final int? companyUserId;

  const InternshipPostDto({
    required this.id,
    required this.companyName,
    this.profileImageUrl,
    required this.title,
    required this.description,
    this.department,
    required this.location,
    required this.saved,
    required this.imageUrl,
    this.companyUserId,
  });

  factory InternshipPostDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['postId'];
    final id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final profileImageUrl = (json['profileImageUrl'] as String?) ??
        (json['companyProfileImageUrl'] as String?) ??
        (json['companyImageUrl'] as String?);

    final rawCompanyUserId = json['companyUserId'] ?? json['userId'] ?? json['ownerId'] ?? json['companyId'];
    final int? companyUserId = rawCompanyUserId is int ? rawCompanyUserId : int.tryParse(rawCompanyUserId?.toString() ?? '');

    return InternshipPostDto(
      id: id,
      companyName: json['companyName'] as String?,
      profileImageUrl: profileImageUrl,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      department: (json['department'] as String?) ?? (json['dept'] as String?),
      location: json['location'] as String?,
      saved: (json['saved'] ?? false) == true,
      imageUrl: json['imageUrl'] as String?,
      companyUserId: companyUserId,
    );
  }
}
