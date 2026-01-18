import 'api_client.dart';

class SearchApi {
  final ApiClient client;
  SearchApi(this.client);

  // Search for profiles by name (students or companies)
  Future<List<dynamic>> searchProfiles(String query) async {
    final res = await client.get('/search/profiles?query=$query');
    return res.data as List<dynamic>;
  }

  // Search for posts by keyword
  Future<List<dynamic>> searchPosts(String query) async {
    final res = await client.get('/search/posts?query=$query');
    return res.data as List<dynamic>;
  }

  // Search for students by name (for company)
  Future<List<dynamic>> searchStudents(String query) async {
    final res = await client.get('/search/students?query=$query');
    return res.data as List<dynamic>;
  }
}
