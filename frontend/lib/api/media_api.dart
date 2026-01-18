import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class MediaApi {
  final ApiClient client;
  MediaApi(this.client);

  Future<String?> uploadMyProfileImage(File file) async {
    print('📸 Starting uploadMyProfileImage');
    print('📁 File path: ${file.path}');
    print('📊 File exists: ${await file.exists()}');
    print('📏 File size: ${await file.length()} bytes');
    
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    
    print('📤 Sending multipart request to /media/me/profile-image');
    final res = await client.postMultipart('/media/me/profile-image', data: form);
    
    print('✅ Response received');
    print('📦 Response data: ${res.data}');
    
    final data = Map<String, dynamic>.from(res.data as Map);
    final profileImageUrl = data['profileImageUrl'] as String?;
    
    print('🖼️  Profile image URL: $profileImageUrl');
    
    return profileImageUrl;
  }

  Future<String?> uploadInternshipPostImage(int postId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res = await client.postMultipart('/media/internship-posts/$postId/image', data: form);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['imageUrl'] as String?;
  }

  Future<String?> uploadStudentProfilePostImage(int studentPostId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res =
        await client.postMultipart('/media/profile-posts/$studentPostId/image', data: form);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['imageUrl'] as String?;
  }

  Future<String?> uploadProfilePostImage(int postId, File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res = await client.postMultipart('/media/profile-posts/$postId/image', data: form);
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['imageUrl'] as String?;
  }
}
