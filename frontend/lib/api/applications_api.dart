import 'api_client.dart';

class ApplicationsApi {
  final ApiClient client;
  ApplicationsApi(this.client);

  Future<List<dynamic>> listApplications() async {
    final res = await client.get('/applications');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getByConversationId(int conversationId) async {
    final list = await listApplications();
    for (final item in list) {
      if (item is! Map) continue;
      final cidRaw = item['conversationId'];
      final cid =
          cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
      if (cid == conversationId) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }
}
