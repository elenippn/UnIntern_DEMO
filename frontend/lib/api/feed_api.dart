import 'api_client.dart';
import '../models/company_candidate_dto.dart';
import '../models/internship_post_dto.dart';

class FeedApi {
  final ApiClient client;
  FeedApi(this.client);

  Future<List<InternshipPostDto>> getStudentFeed({String? department}) async {
    print('\n🔍 FEED API - getStudentFeed()');
    print('   Input department param: "$department"');
    print('   Param type: ${department.runtimeType}');
    print('   Is null: ${department == null}');
    print('   Is empty: ${department?.isEmpty}');
    
    final params = <String, dynamic>{};
    if (department != null && department.isNotEmpty && department != 'All') {
      params['department'] = department;
      print('   ✅ Adding to query params: department=$department');
    } else {
      print('   ❌ NOT adding to query params (null, empty, or "All")');
    }
    
    print('   Final query params map: $params');
    print('   Will pass to dio.get: ${params.isNotEmpty ? params : 'null'}\n');
    
    final res = await client.get('/feed/student', queryParameters: params.isNotEmpty ? params : null);
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) =>
            InternshipPostDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> decideOnPost(int postId, String decision) async {
    await client.post('/decisions/student/post', data: {
      "postId": postId,
      "decision": decision, // "LIKE" or "PASS"
    });
  }

  Future<void> savePost(int postId, bool saved) async {
    await client.post('/saves/student/post', data: {
      "postId": postId,
      "saved": saved,
    });
  }

  Future<List<CompanyCandidateDto>> getCompanyFeed({String? department}) async {
    final params = <String, dynamic>{};
    if (department != null && department.isNotEmpty && department != 'All') {
      params['department'] = department;
    }
    
    print('DEBUG: FeedApi.getCompanyFeed() called with params: $params');
    
    final res = await client.get('/feed/company', queryParameters: params.isNotEmpty ? params : null);
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) =>
            CompanyCandidateDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> decideOnStudent(int studentUserId, String decision) async {
    await client.post('/decisions/company/student', data: {
      "studentUserId": studentUserId,
      "decision": decision,
    });
  }

  Future<void> decideOnStudentPost(int studentPostId, String decision) async {
    await client.post('/decisions/company/student-post', data: {
      "studentPostId": studentPostId,
      "decision": decision,
    });
  }

  Future<void> saveStudent(int studentUserId, bool saved) async {
    await client.post('/saves/company/student', data: {
      "studentUserId": studentUserId,
      "saved": saved,
    });
  }
}
