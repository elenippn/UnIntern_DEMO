import 'package:flutter/material.dart';
import '../app_services.dart';
import 'profile_edit_company_screen.dart';
import '../models/auth_me_dto.dart';
import '../models/internship_post_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../widgets/app_cached_image.dart';

class ProfileCompanyScreen extends StatefulWidget {
  const ProfileCompanyScreen({super.key});

  @override
  State<ProfileCompanyScreen> createState() => _ProfileCompanyScreenState();
}

class _ProfileCompanyScreenState extends State<ProfileCompanyScreen> {
  bool _isLoading = true;
  String? _error;
  AuthMeDto? _profile;
  List<InternshipPostDto> _companyPosts = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final me = await AppServices.auth.getMe();
      final posts = await AppServices.posts.listMyCompanyPosts();
      if (!mounted) return;
      setState(() {
        _profile = me;
        _companyPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyApiError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(bottom: false, child: _buildHeader()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildContent(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFAFD9F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
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
              GestureDetector(
                onTap: () {
                  AppServices.auth.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signin',
                    (route) => false,
                  );
                },
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load profile:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Trirong'),
            ),
          ),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
      );
    }

    return Column(
      children: [
        _buildUserInfo(),
        const SizedBox(height: 24),
        _buildAboutSection(),
        const SizedBox(height: 16),
        _buildAvailableInternshipsSection(),
      ],
    );
  }

  Widget _buildUserInfo() {
    final username = _profile?.username ?? '';
    final companyName = (_profile?.companyName ?? _profile?.name ?? '');
    final displayUsername = username.isNotEmpty ? '@$username' : '@username';
    final String? profileImageUrl = resolveApiUrl(
      _profile?.profileImageUrl,
      baseUrl: AppServices.baseUrl,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: AppProfileAvatar(
              imageUrl: profileImageUrl,
              size: 80,
              fallbackIcon: Icons.business,
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
          GestureDetector(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileEditCompanyScreen(),
                ),
              );
              if (updated == true) {
                _loadProfile();
              }
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final bio = _profile?.companyBio ?? _profile?.bio ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
      ),
    );
  }

  Widget _buildAvailableInternshipsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_companyPosts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(
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
            ),
            const SizedBox(height: 16),
            _buildCreatePostButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ..._companyPosts.map((p) => _buildCompanyPostCard(p)).toList(),
          const SizedBox(height: 16),
          _buildCreatePostButton(),
        ],
      ),
    );
  }

  Widget _buildCompanyPostCard(InternshipPostDto p) {
    final title = p.title;
    final description = p.description;
    final location = p.location ?? '';
    final createdAt = '';
    final String? imageUrl = resolveApiUrl(
      p.imageUrl,
      baseUrl: AppServices.baseUrl,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1B5E20), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
              ),
            ),
          ],
          const SizedBox(height: 8),
          AppCachedImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          if (createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              createdAt,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontFamily: 'Trirong',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'New Internship Ad',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Trirong',
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () async {
              final created =
                  await Navigator.pushNamed(context, '/newpost_company');
              if (created == true) {
                _loadProfile();
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.favorite, color: Colors.white),
            label: const Text(
              'Saved Candidates',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Trirong',
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/saved_listings_company');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[400]!,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(Icons.home, () {
            Navigator.pushNamed(context, '/home_company');
          }),
          _buildNavIcon(Icons.search, () {
            Navigator.pushNamed(context, '/search_company');
          }),
          _buildNavIcon(Icons.add, () {
            Navigator.pushNamed(context, '/newpost_company');
          }),
          _buildNavIcon(Icons.mail_outline, () {
            Navigator.pushNamed(context, '/messages_company');
          }),
          _buildNavIcon(Icons.person_outline, () {
            // Already on Profile screen
          }),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: const Color(0xFF1B5E20),
        size: 24,
      ),
    );
  }
}
