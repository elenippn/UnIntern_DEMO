import 'package:flutter/material.dart';
import '../app_services.dart';
import '../models/auth_me_dto.dart';
import '../models/internship_post_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../widgets/app_cached_image.dart';

class ViewProfileCompanyScreen extends StatefulWidget {
  final Map company;

  const ViewProfileCompanyScreen({super.key, required this.company});

  @override
  State<ViewProfileCompanyScreen> createState() =>
      _ViewProfileCompanyScreenState();
}

class _ViewProfileCompanyScreenState extends State<ViewProfileCompanyScreen> {
  AuthMeDto? _profile;

  List<InternshipPostDto> _posts = const [];
  bool _loadingPosts = false;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _maybeLoadPosts();
  }

  Future<void> _loadProfile() async {
    final int? companyUserId = _extractCompanyUserId(widget.company);
    if (companyUserId == null) return;

    try {
      // Use the new company profile endpoint
      final profile =
          await AppServices.profiles.getCompanyProfile(companyUserId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
      });
    } catch (e) {
      if (!mounted) return;
      // If we can't load the profile, continue with the map data
    }
  }

  Future<void> _maybeLoadPosts() async {
    final int? companyUserId = _extractCompanyUserId(widget.company);
    if (companyUserId == null) return;
    setState(() => _loadingPosts = true);
    try {
      final res =
          await AppServices.posts.listCompanyPostsForUser(companyUserId);
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
    final company = widget.company;
    final profile = _profile;

    // Use profile data when available, fallback to company map data
    final String username = (profile?.username.trim().isNotEmpty ?? false)
        ? profile!.username
        : (company['username'] ?? '') as String;

    final String companyName =
        (profile?.companyName?.trim().isNotEmpty ?? false)
            ? profile!.companyName!
            : (profile?.name?.trim().isNotEmpty ?? false)
                ? profile!.name
                : (company['companyName'] ?? company['name'] ?? '') as String;

    final String bio = (profile?.companyBio?.trim().isNotEmpty ?? false)
        ? profile!.companyBio!
        : (profile?.bio?.trim().isNotEmpty ?? false)
            ? profile!.bio!
            : (company['bio'] ??
                company['companyBio'] ??
                company['description'] ??
                '') as String;

    final dynamic rawMapProfileImageUrl =
        company['profileImageUrl'] ?? company['companyProfileImageUrl'];
    final String? mapProfileImageUrl =
        rawMapProfileImageUrl is String ? rawMapProfileImageUrl : null;
    final String? profileImageUrl = resolveApiUrl(
      profile?.profileImageUrl ?? mapProfileImageUrl,
      baseUrl: AppServices.baseUrl,
    );

    final List<InternshipPostDto> posts = _posts;
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
                          companyName, displayUsername, profileImageUrl),
                      const SizedBox(height: 20),
                      _buildAboutSection(bio),
                      const SizedBox(height: 16),
                      if (_loadingPosts)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        )
                      else if (_postsError != null)
                        _buildCard('Available Internship ads',
                            'Could not load: $_postsError')
                      else
                        _buildAvailableInternshipsSection(posts),
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
      String companyName, String displayUsername, String? profileImageUrl) {
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
                    size: 80,
                    fallbackIcon: Icons.business,
                  )
                : const Center(
                    child: Icon(
                      Icons.business,
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
                  displayUsername,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  companyName.isNotEmpty ? companyName : 'Company Name',
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
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'Trirong',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String bio) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF1B5E20),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'About/Bio',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio.isNotEmpty ? bio : 'No bio yet',
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

  Widget _buildAvailableInternshipsSection(List<InternshipPostDto> posts) {
    if (posts.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 150,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1B5E20),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Internship ads',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
            fontFamily: 'Trirong',
          ),
        ),
        const SizedBox(height: 12),
        ...posts.map(_buildPostCard).toList(),
      ],
    );
  }

  Widget _buildPostCard(InternshipPostDto post) {
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

  int? _extractCompanyUserId(Map company) {
    final keys = ['companyUserId', 'userId', 'ownerId', 'companyId'];
    for (final k in keys) {
      final v = company[k];
      if (v is int) return v;
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
