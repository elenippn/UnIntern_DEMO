class ProfilePostDto {
  final int id;
  final String title;
  final String description;
  final String? category;
  final String? imageUrl;

  const ProfilePostDto({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  factory ProfilePostDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['postId'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return ProfilePostDto(
      id: id,
      title: (json['title'] ?? json['name'] ?? 'Post') as String,
      description: (json['description'] ?? '') as String,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
