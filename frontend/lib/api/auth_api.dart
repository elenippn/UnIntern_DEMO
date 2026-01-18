import 'api_client.dart';
import '../models/auth_me_dto.dart';

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> login(String usernameOrEmail, String password) async {
    final res = await client.post('/auth/login', data: {
      "username_or_email": usernameOrEmail,
      "password": password,
    });
    final token = (res.data as dynamic)['access_token'] as String;
    await client.setToken(token);
  }

  Future<void> register({
    required String name,
    required String surname,
    required String username,
    required String email,
    required String password,
    required String role, // "STUDENT" or "COMPANY"
  }) async {
    final res = await client.post('/auth/register', data: {
      "name": name,
      "surname": surname,
      "username": username,
      "email": email,
      "password": password,
      "role": role,
    });
    final token = (res.data as dynamic)['access_token'] as String;
    await client.setToken(token);
  }

  Future<AuthMeDto> getMe() async {
    final res = await client.get('/auth/me');
    return AuthMeDto.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Map<String, dynamic>> updateMe({
    String? name,
    String? surname,
    String? bio,
    String? studies,
    String? skills,
    String? experience,
    String? companyName,
    String? companyBio,
  }) async {
    final payload = <String, dynamic>{
      "name": _normalizeOptional(name),
      "surname": _normalizeOptional(surname),
      "bio": _normalizeOptional(bio),
      "studies": _normalizeOptional(studies),
      "skills": _normalizeOptional(skills),
      "experience": _normalizeOptional(experience),
      "companyName": _normalizeOptional(companyName),
      "companyBio": _normalizeOptional(companyBio),
    }..removeWhere((key, value) => value == null);

    final res = await client.put('/auth/me', data: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout() async {
    await client.clearToken();
  }
}
