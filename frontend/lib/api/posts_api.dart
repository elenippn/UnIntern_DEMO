import 'api_client.dart';
import '../models/internship_post_dto.dart';
import '../models/profile_post_dto.dart';
import 'package:dio/dio.dart';

class PostsApi {
  final ApiClient client;
  PostsApi(this.client);

  Future<InternshipPostDto> createCompanyPost({
    required String title,
    required String description,
    String? location,
    String? department,
  }) async {
    final res = await client.post('/posts', data: {
      'title': title,
      'description': description,
      'location': location,
      'department': department,
    });
    return InternshipPostDto.fromJson(
        Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<InternshipPostDto>> listMyCompanyPosts() async {
    final res = await client.get('/posts/me');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) =>
            InternshipPostDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<InternshipPostDto>> listCompanyPostsForUser(
      int companyUserId) async {
    final res = await client.get('/posts/company/$companyUserId');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) =>
            InternshipPostDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<InternshipPostDto> updateCompanyPost({
    required int postId,
    required String title,
    required String description,
    String? location,
    String? department,
  }) async {
    final res = await client.put('/posts/$postId', data: {
      'title': title,
      'description': description,
      'location': location,
      'department': department,
    });
    return InternshipPostDto.fromJson(
        Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteCompanyPost(int postId) async {
    try {
      await client.delete('/posts/$postId');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Some backends expose deletion via POST instead of DELETE.
      if (status == 405) {
        try {
          await client.post('/posts/$postId/delete');
          return;
        } on DioException {
          // Fallback variant
          await client.post('/posts/delete/$postId');
          return;
        }
      }
      rethrow;
    }
  }

  Future<ProfilePostDto> createProfilePost({
    required String title,
    required String description,
    String? category,
  }) async {
    final res = await client.post('/profile-posts', data: {
      'title': title,
      'description': description,
      'category': category,
    });
    return ProfilePostDto.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<List<ProfilePostDto>> listMyProfilePosts() async {
    final res = await client.get('/profile-posts/me');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map(
            (e) => ProfilePostDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<ProfilePostDto>> listProfilePostsForStudent(
      int studentUserId) async {
    final res = await client.get('/profile-posts/$studentUserId');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map(
            (e) => ProfilePostDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ProfilePostDto> updateProfilePost({
    required int postId,
    required String title,
    required String description,
    String? category,
  }) async {
    final res = await client.put('/profile-posts/$postId', data: {
      'title': title,
      'description': description,
      'category': category,
    });
    return ProfilePostDto.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteProfilePost(int postId) async {
    await client.delete('/profile-posts/$postId');
  }
}
