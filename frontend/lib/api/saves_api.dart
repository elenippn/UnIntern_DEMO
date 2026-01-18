import 'api_client.dart';

class SavesApi {
  final ApiClient client;
  SavesApi(this.client);

  // Student saved internship posts
  Future<List<dynamic>> listStudentSavedPosts() async {
    final res = await client.get('/saves/student/posts');
    return res.data as List<dynamic>;
  }

  // Toggle save (student saves a post)
  Future<void> setStudentSave(int postId, bool saved) async {
    await client.post('/saves/student/post', data: {
      "postId": postId,
      "saved": saved,
    });
  }

  // (Future) Company saved students (will work when backend is ready)
  Future<List<dynamic>> listCompanySavedStudents() async {
    final res = await client.get('/saves/company/students');
    return res.data as List<dynamic>;
  }

  Future<void> setCompanySaveStudent(
    int studentUserId,
    bool saved, {
    int? studentPostId,
  }) async {
    final payload = {
      "studentUserId": studentUserId,
      "studentPostId": studentPostId,
      "saved": saved,
    }..removeWhere((k, v) => v == null);

    await client.post('/saves/company/student', data: payload);
  }
}
