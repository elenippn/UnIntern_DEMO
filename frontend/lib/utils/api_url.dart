String? resolveApiUrl(String? url, {required String baseUrl}) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }

  return '$baseUrl/$trimmed';
}
