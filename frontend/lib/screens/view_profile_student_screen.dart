import 'package:flutter/material.dart';
import '../app_services.dart';
import '../models/profile_post_dto.dart';
import '../models/student_profile_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../widgets/app_cached_image.dart';

class ViewProfileStudentScreen extends StatefulWidget {
  final Map student;

  const ViewProfileStudentScreen({super.key, required this.student});

  @override
  State<ViewProfileStudentScreen> createState() =>
      _ViewProfileStudentScreenState();
}

class _ViewProfileStudentScreenState extends State<ViewProfileStudentScreen> {
  StudentProfileDto? _profile;

  List<ProfilePostDto> _posts = const [];
  bool _loadingPosts = false;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _maybeLoadPosts();
  }

  Future<void> _loadProfile() async {
    final int? studentUserId = _extractStudentUserId(widget.student);
    if (studentUserId == null) return;

    try {
      final profile =
          await AppServices.profiles.getStudentProfile(studentUserId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _maybeLoadPosts() async {
    final int? studentUserId = _extractStudentUserId(widget.student);
    if (studentUserId == null) return;
    setState(() => _loadingPosts = true);
    try {
      final res =
          await AppServices.posts.listProfilePostsForStudent(studentUserId);
      if (!mounted) return;
      setState(() {
        _posts = res;
        _loadingPosts = false;
        _postsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _postsError = friendlyApiError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final profile = _profile;

    final String username = (profile?.username.trim().isNotEmpty ?? false)
        ? profile!.username
        : (student['username'] ?? '') as String;

    final String rawName = (student['name'] ??
        student['studentName'] ??
        student['fullName'] ??
        '') as String;
    final String firstName = (student['firstName'] ?? '') as String;
    final String lastName = (student['lastName'] ?? '') as String;
    final String fallbackDisplayName =
        rawName.isNotEmpty ? rawName : '$firstName $lastName'.trim();

    final String profileDisplayName = _joinNonEmpty(
      [
        (profile?.name ?? '').trim(),
        (profile?.surname ?? '').trim(),
      ],
      separator: ' ',
    );
    final String displayName = profileDisplayName != 'Not provided'
        ? profileDisplayName
        : fallbackDisplayName;

    final String university = (student['university'] ?? '') as String;
    final String department =
        (student['department'] ?? student['major'] ?? '') as String;

    final String bio = (profile?.bio ??
        student['bio'] ??
        student['description'] ??
        '') as String;
    final String studies =
        (profile?.studies ?? student['studies'] ?? '') as String;
    final String skills = (profile?.skills ??
        student['skills'] ??
        student['skillset'] ??
        '') as String;
    final String experience =
        (profile?.experience ?? student['experience'] ?? '') as String;

    final dynamic rawMapProfileImageUrl =
        student['studentProfileImageUrl'] ?? student['profileImageUrl'];
    final String? mapProfileImageUrl =
        rawMapProfileImageUrl is String ? rawMapProfileImageUrl : null;
    final String? profileImageUrl = resolveApiUrl(
      profile?.profileImageUrl ?? mapProfileImageUrl,
      baseUrl: AppServices.baseUrl,
    );
    final List<ProfilePostDto> posts = _posts;

    final String studiesText = studies.trim().isNotEmpty
        ? studies
        : _joinNonEmpty([
            university,
            department,
          ], separator: '\n');
    final String displayUsername =
        username.isNotEmpty ? '@$username' : '@username';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(bottom: false, child: _buildHeader(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      bottom: 32, left: 16, right: 16, top: 24),
                  child: Column(
                    children: [
                      _buildUserInfo(
                        displayName,
                        displayUsername,
                        profileImageUrl: profileImageUrl,
                      ),
                      const SizedBox(height: 24),
                      _buildAboutSection(bio),
                      const SizedBox(height: 16),
                      _buildStudiesSection(studiesText),
                      const SizedBox(height: 16),
                      _buildSkillsSection(skills),
                      const SizedBox(height: 16),
                      _buildExperienceSection(experience),
                      const SizedBox(height: 16),
                      if (_loadingPosts)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        )
                      else if (_postsError != null)
                        _buildCard('Posts', 'Could not load posts: $_postsError')
                      else
                        _buildPostsSection(posts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosts(List<ProfilePostDto> posts) {
    if (posts.isEmpty) {
      return _buildCard('Posts', 'No posts available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Posts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...posts.map(_buildPostCard).toList(),
      ],
    );
  }

  Widget _buildPostCard(ProfilePostDto post) {
    final String? imageUrl = resolveApiUrl(
      post.imageUrl,
      baseUrl: AppServices.baseUrl,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B5E20), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 6),
          AppCachedImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Text(
            post.description.isNotEmpty ? post.description : 'No description',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontFamily: 'Trirong',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFD9F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF1B5E20),
              size: 28,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'UnIntern',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Trirong',
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
    String name,
    String username, {
    required String? profileImageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1B5E20),
                width: 2,
              ),
            ),
            child: profileImageUrl != null
                ? AppProfileAvatar(
                    imageUrl: profileImageUrl,
                    size: 76,
                    fallbackIcon: Icons.person,
                  )
                : const Center(
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name.isNotEmpty ? name : 'Student',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, String body) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B5E20), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body.isNotEmpty ? body : 'Not provided',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String bio) {
    return _buildCard('About/Bio', bio.isNotEmpty ? bio : 'No bio provided');
  }

  Widget _buildStudiesSection(String studies) {
    return _buildCard('Studies', studies.isNotEmpty ? studies : 'No studies info');
  }

  Widget _buildSkillsSection(String skills) {
    return _buildCard('Skills', skills.isNotEmpty ? skills : 'No skills provided');
  }

  Widget _buildExperienceSection(String experience) {
    return _buildCard('Experience', experience.isNotEmpty ? experience : 'No experience provided');
  }

  Widget _buildPostsSection(List<ProfilePostDto> posts) {
    if (posts.isEmpty) {
      return _buildCard('Posts', 'No posts available');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Posts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...posts.map(_buildPostCard).toList(),
      ],
    );
  }

  String _joinNonEmpty(List<String> items, {String separator = ', '}) {
    final filtered = items.where((e) => e.isNotEmpty).toList();
    return filtered.isNotEmpty ? filtered.join(separator) : 'Not provided';
  }

  int? _extractStudentUserId(Map candidate) {
    final keys = ['studentUserId', 'userId', 'id'];
    for (final k in keys) {
      final v = candidate[k];
      if (v is int) return v;
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
