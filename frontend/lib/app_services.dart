import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/feed_api.dart';
import 'api/applications_api.dart';
import 'api/chat_api.dart';
import 'api/saves_api.dart';
import 'api/posts_api.dart';
import 'api/search_api.dart';

import 'api/media_api.dart';
import 'api/profiles_api.dart';
import 'utils/app_events.dart';
import 'package:flutter/foundation.dart';

class AppServices {
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;

    if (kIsWeb) return 'http://${Uri.base.host}:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static final ApiClient client = ApiClient(baseUrl: baseUrl);

  static final AuthApi auth = AuthApi(client);
  static final FeedApi feed = FeedApi(client);
  static final ApplicationsApi applications = ApplicationsApi(client);
  static final ChatApi chat = ChatApi(client);
  static final SavesApi saves = SavesApi(client);
  static final PostsApi posts = PostsApi(client);

  static final SearchApi search = SearchApi(client);
  static final MediaApi media = MediaApi(client);
  static final ProfilesApi profiles = ProfilesApi(client);

  static final AppEvents events = AppEvents();
}
