import 'api_client.dart';

class ChatApi {
  final ApiClient client;
  ChatApi(this.client);

  Future<List<dynamic>> getMessages(int conversationId) async {
    final res = await client.get('/conversations/$conversationId/messages');
    return res.data as List<dynamic>;
  }

  Future<void> sendMessage(int conversationId, String text) async {
    await client.post('/conversations/$conversationId/messages',
        data: {"text": text});
  }

  Future<void> markConversationRead(
    int conversationId, {
    int? lastReadMessageId,
  }) async {
    final data = lastReadMessageId == null
        ? null
        : {
            'lastReadMessageId': lastReadMessageId,
          };
    await client.post(
      '/conversations/$conversationId/read',
      data: data,
    );
  }
}
