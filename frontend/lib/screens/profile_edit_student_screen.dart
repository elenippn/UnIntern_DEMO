import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../app_services.dart';
import '../models/profile_post_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../widgets/app_cached_image.dart';

class ProfileEditStudentScreen extends StatefulWidget {
  const ProfileEditStudentScreen({super.key});

  @override
  State<ProfileEditStudentScreen> createState() =>
      _ProfileEditStudentScreenState();
}

class _ProfileEditStudentScreenState extends State<ProfileEditStudentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _studiesController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Track which fields are being edited
  bool _showBioInput = false;
  bool _showStudiesInput = false;
  bool _showSkillsInput = false;
  bool _showExperienceInput = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _username;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isPostsLoading = true;
  String? _postsError;
  List<ProfilePostDto> _myPosts = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMyPosts();
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
                  padding: const EdgeInsets.only(bottom: 120),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSaveButton(),
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
              const SizedBox(width: 28),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Edit Profile',
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
        child: Center(child: CircularProgressIndicator()),
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
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _buildUserEditInfo(),
        const SizedBox(height: 24),
        _buildAboutEditSection(),
        const SizedBox(height: 16),
        _buildPostsEditSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserEditInfo() {
    final displayUsername =
        (_username?.isNotEmpty ?? false) ? '@$_username' : '@username';

    final String? resolvedProfileImageUrl = resolveApiUrl(
      _profileImageUrl,
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
              color: const Color(0xFFC9D3C9),
              border: Border.all(
                color: const Color(0xFF1B5E20),
                width: 2,
              ),
            ),
            child: Center(
              child: GestureDetector(
                onTap: _pickAndUploadProfileImage,
                child: (resolvedProfileImageUrl != null &&
                        resolvedProfileImageUrl.trim().isNotEmpty)
                    ? AppProfileAvatar(
                        imageUrl: resolvedProfileImageUrl,
                        size: 76,
                        fallbackIcon: Icons.person,
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: Color(0xFF1B5E20),
                      ),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D3C9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Trirong',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9D3C9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      hintText: 'Surname',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Trirong',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutEditSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1B5E20),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildEditableItem(
                  'Bio description', _bioController, _showBioInput, () {
                setState(() {
                  _showBioInput = !_showBioInput;
                });
              }),
              const SizedBox(height: 16),
              _buildEditableItem(
                  'Studies', _studiesController, _showStudiesInput, () {
                setState(() {
                  _showStudiesInput = !_showStudiesInput;
                });
              }),
              const SizedBox(height: 16),
              _buildEditableItem('Skills', _skillsController, _showSkillsInput,
                  () {
                setState(() {
                  _showSkillsInput = !_showSkillsInput;
                });
              }),
              const SizedBox(height: 16),
              _buildEditableItem(
                  'Experience', _experienceController, _showExperienceInput,
                  () {
                setState(() {
                  _showExperienceInput = !_showExperienceInput;
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableItem(String label, TextEditingController controller,
      bool isExpanded, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Icon(Icons.add, color: const Color(0xFF1B5E20), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Trirong',
                ),
              ),
            ],
          ),
        ),
        if (isExpanded)
          Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9D3C9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Trirong',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPostsEditSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 280,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1B5E20),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Posts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Trirong',
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildMyPostsBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPostsBody() {
    if (_isPostsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_postsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load posts',
              style: TextStyle(
                fontFamily: 'Trirong',
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadMyPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_myPosts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet',
          style: TextStyle(
            fontFamily: 'Trirong',
            color: Color(0xFF1B5E20),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _myPosts.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _myPosts[index];
        final String? imageUrl = resolveApiUrl(
          p.imageUrl,
          baseUrl: AppServices.baseUrl,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC9D3C9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AppCachedImage(
                imageUrl: imageUrl,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (p.title.isNotEmpty ? p.title : 'Untitled'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                    ),
                    if ((p.category ?? '').trim().isNotEmpty)
                      Text(
                        p.category!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B5E20),
                          fontFamily: 'Trirong',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, color: Color(0xFF1B5E20)),
                onPressed: _isSaving ? null : () => _editPost(p),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete, color: Color(0xFF1B5E20)),
                onPressed: _isSaving ? null : () => _confirmDeletePost(p),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadMyPosts() async {
    setState(() {
      _isPostsLoading = true;
      _postsError = null;
    });

    try {
      final posts = await AppServices.posts.listMyProfilePosts();
      if (!mounted) return;
      setState(() {
        _myPosts = posts;
        _isPostsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = friendlyApiError(e);
        _isPostsLoading = false;
      });
    }
  }

  Future<void> _confirmDeletePost(ProfilePostDto post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await AppServices.posts.deleteProfilePost(post.id);
      if (!mounted) return;
      setState(() {
        _myPosts = _myPosts.where((p) => p.id != post.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyApiError(e))),
      );
    }
  }

  Future<void> _editPost(ProfilePostDto post) async {
    final titleController = TextEditingController(text: post.title);
    final descController = TextEditingController(text: post.description);
    final categoryController = TextEditingController(text: post.category ?? '');
    File? selectedImage;
    final imageNotifier = ValueNotifier<File?>(null);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Post', style: TextStyle(fontFamily: 'Trirong')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<File?>(
                  valueListenable: imageNotifier,
                  builder: (context, image, _) {
                    return GestureDetector(
                      onTap: () async {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: context,
                          builder: (ctx) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Gallery'),
                                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera),
                                    title: const Text('Camera'),
                                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (source == null) return;
                        final picked = await _picker.pickImage(
                          source: source,
                          imageQuality: 85,
                          maxWidth: 1600,
                        );
                        if (picked != null) {
                          selectedImage = File(picked.path);
                          imageNotifier.value = selectedImage;
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF1B5E20)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(image, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Color(0xFF1B5E20)),
                                  SizedBox(height: 8),
                                  Text('Tap to change image', style: TextStyle(fontFamily: 'Trirong')),
                                ],
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'Trirong'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Trirong'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'Trirong'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      // Upload new image if selected
      final imgFile = selectedImage;
      if (imgFile != null) {
        await AppServices.media.uploadStudentProfilePostImage(post.id, imgFile);
      }
      
      // Update post text fields
      await AppServices.posts.updateProfilePost(
        postId: post.id,
        title: titleController.text,
        description: descController.text,
        category: categoryController.text.isEmpty ? null : categoryController.text,
      );
      await _loadMyPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyApiError(e))),
      );
    }
  }

  Widget _buildSaveButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: (_isSaving || _isLoading) ? null : _saveProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Trirong',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final me = await AppServices.auth.getMe();
      if (!mounted) return;
      setState(() {
        _username = me.username;
        _profileImageUrl = me.profileImageUrl;
        _nameController.text = me.name;
        _surnameController.text = me.surname;
        _bioController.text = me.bio ?? '';
        _studiesController.text = me.studies ?? '';
        _skillsController.text = me.skills ?? '';
        _experienceController.text = me.experience ?? '';
        _showBioInput = true;
        _showStudiesInput = true;
        _showSkillsInput = true;
        _showExperienceInput = true;
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

  Future<void> _pickAndUploadProfileImage() async {
    if (_isLoading || _isSaving) return;

    print('📸 Opening image picker dialog...');
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      print('❌ User cancelled image source selection');
      return;
    }

    print('✅ User selected: ${source == ImageSource.gallery ? 'Gallery' : 'Camera'}');

    try {
      print('📱 Requesting image from picker...');
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      
      if (picked == null) {
        print('❌ User cancelled image selection');
        return;
      }

      print('✅ Image picked: ${picked.path}');
      
      final file = File(picked.path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      
      print('📁 File exists: $exists');
      print('📏 File size: $size bytes');
      
      print('📤 Uploading to server...');
      await AppServices.media.uploadMyProfileImage(file);
      
      print('♻️  Reloading profile...');
      await _loadProfile();

      if (!mounted) return;
      print('✅ Profile image updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated')),
      );
    } catch (e) {
      print('❌ Error during image upload: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyApiError(e))),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await AppServices.auth.updateMe(
        name: _nameController.text,
        surname: _surnameController.text,
        bio: _bioController.text,
        studies: _studiesController.text,
        skills: _skillsController.text,
        experience: _experienceController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('updateMe(student) failed: $e');
        try {
          // ignore: avoid_print
          print((e as dynamic).response?.data);
        } catch (_) {
          // ignore
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyApiError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _bioController.dispose();
    _studiesController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}
