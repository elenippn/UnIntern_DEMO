import 'package:flutter/material.dart';
import '../app_services.dart';
import '../models/company_candidate_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../utils/internship_departments.dart';
import '../widgets/app_cached_image.dart';
import 'view_profile_student_screen.dart';

class HomeCompanyScreen extends StatefulWidget {
  const HomeCompanyScreen({super.key});

  @override
  State<HomeCompanyScreen> createState() => _HomeCompanyScreenState();
}

class _HomeCompanyScreenState extends State<HomeCompanyScreen> {
  Set<String> _selectedDepartments = {'All'};
  bool _showFilter = false;

  bool _isLoading = true;
  String? _error;
  List<CompanyCandidateDto> _candidates = [];
  final Set<int> _savedCandidateIds = {};

  // Unread messages count for notification badge
  int _unreadMessagesCount = 0;

  final List<String> departments = internshipDepartments;

  int _extractStudentId(CompanyCandidateDto candidate) =>
      candidate.studentUserId;

  int? _extractStudentPostId(CompanyCandidateDto candidate) =>
      candidate.studentPostId;

  List<CompanyCandidateDto> get _filteredCandidates {
    // Το backend κάνει το φιλτράρισμα, οπότε απλώς δείχνουμε τα δεδομένα που λήφθησαν
    return _candidates;
  }

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadUnreadCount();
    AppServices.events.addListener(_onApplicationsChanged);
  }

  @override
  void dispose() {
    AppServices.events.removeListener(_onApplicationsChanged);
    super.dispose();
  }

  void _onApplicationsChanged() {
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final apps = await AppServices.applications.listApplications();
      int total = 0;
      for (final app in apps) {
        if (app is Map) {
          final unread = app['unreadCount'] ?? 0;
          total +=
              (unread is int ? unread : int.tryParse(unread.toString()) ?? 0);
        }
      }
      if (mounted) {
        setState(() {
          _unreadMessagesCount = total;
        });
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the selected department filter (if any)
      String? departmentFilter;
      if (_selectedDepartments.isNotEmpty &&
          !_selectedDepartments.contains('All')) {
        // If a specific department is selected, use the first one
        departmentFilter = _selectedDepartments.first;
      }

      final data =
          await AppServices.feed.getCompanyFeed(department: departmentFilter);
      if (!mounted) return;
      _savedCandidateIds
        ..clear()
        ..addAll(data.where((c) => c.saved).map<int>(_extractStudentId));
      setState(() {
        _candidates = data;
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

  Future<void> _toggleSave(int studentUserId, {int? studentPostId}) async {
    final wasSaved = _savedCandidateIds.contains(studentUserId);
    setState(() {
      if (wasSaved) {
        _savedCandidateIds.remove(studentUserId);
      } else {
        _savedCandidateIds.add(studentUserId);
      }
    });

    try {
      await AppServices.saves.setCompanySaveStudent(
        studentUserId,
        !wasSaved,
        studentPostId: studentPostId,
      );
    } catch (e) {
      setState(() {
        if (wasSaved) {
          _savedCandidateIds.add(studentUserId);
        } else {
          _savedCandidateIds.remove(studentUserId);
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update save. Please retry.')),
      );
    }
  }

  Future<void> _decide(
    int studentUserId,
    String decision, {
    int? studentPostId,
  }) async {
    final index = _candidates.indexWhere(
      (c) => _extractStudentId(c) == studentUserId,
    );
    dynamic removed;
    if (index != -1) {
      removed = _candidates[index];
      setState(() {
        _candidates.removeAt(index);
      });
    }

    try {
      if (studentPostId != null && studentPostId != 0) {
        await AppServices.feed.decideOnStudentPost(studentPostId, decision);
      } else {
        await AppServices.feed.decideOnStudent(studentUserId, decision);
      }

      // Spec: after company LIKE/PASS, refresh /applications so pending/accepted/
      // declined reflect immediately in Messages/Chat.
      AppServices.events.applicationsChanged();

      // Show confirmation message for LIKE
      if (decision.toUpperCase() == 'LIKE') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Candidate liked! Check your messages."),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      if (removed != null) {
        setState(() {
          _candidates.insert(index, removed);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send decision. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // SafeArea μόνο για το header
              SafeArea(
                bottom: false,
                child: _buildStickyHeader(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildBody(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Filter overlay
          if (_showFilter)
            Positioned(
              top: 85,
              right: 16,
              width: 200,
              child: _buildFilterDropdown(),
            ),

          // Bottom navigation FULL WIDTH
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

  Widget _buildStickyHeader() {
    return Container(
      color: const Color(0xFFFAFD9F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  setState(() {
                    _showFilter = !_showFilter;
                  });
                },
                child: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF1B5E20),
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'Applications',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Trirong',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          final isSelected = _selectedDepartments.contains(dept);
          return GestureDetector(
            onTap: () {
              // Single selection: Αλλάζουμε απευθείας την επιλογή
              _selectedDepartments.clear();
              _selectedDepartments.add(dept);

              // Κλείνουμε το filter dropdown
              setState(() {
                _showFilter = false;
              });

              // Φορτώνουμε τα δεδομένα με το νέο φίλτρο
              _loadFeed();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dept,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Trirong',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Text(
              'Failed to load feed:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = _filteredCandidates;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'No candidates available',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildCandidateCard(items[index]);
      },
    );
  }

  Widget _buildCandidateCard(CompanyCandidateDto candidate) {
    final int studentUserId = _extractStudentId(candidate);
    final int? studentPostId = _extractStudentPostId(candidate);
    final String name = candidate.name;
    final String bio = candidate.bio ?? '';
    final String studies = candidate.studies ?? '';
    final String skills = candidate.skills ?? '';
    final String experience = candidate.experience ?? '';

    final String studiesTitle = () {
      final lines = studies
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) return lines.first;
      final fallback = (candidate.department ?? '').trim();
      return fallback;
    }();

    final String? profileImageUrl = resolveApiUrl(
      candidate.studentProfileImageUrl,
      baseUrl: AppServices.baseUrl,
    );
    final bool isSaved = _savedCandidateIds.contains(studentUserId);

    return Dismissible(
      key: Key('candidate_$studentUserId'),
      direction:
          DismissDirection.startToEnd, // Swipe right (από αριστερά προς δεξιά)
      confirmDismiss: (direction) async {
        // Swipe right = LIKE (ταυτίζεται με το done plugin)
        await _decide(studentUserId, 'LIKE', studentPostId: studentPostId);
        return true;
      },
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50), // Πράσινο για LIKE
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () =>
            _toggleSave(studentUserId, studentPostId: studentPostId),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF0D3B1A),
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1B5E20),
                        width: 1.5,
                      ),
                    ),
                    child: AppProfileAvatar(
                      imageUrl: profileImageUrl,
                      size: 32,
                      fallbackIcon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Candidate',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfileStudentScreen(
                            student: {
                              'studentUserId': studentUserId,
                              'id': studentUserId,
                              'name': name,
                            },
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF1B5E20),
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (studiesTitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    studiesTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                  ),
                ),
              if (bio.isNotEmpty)
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                )
              else
                const Text(
                  'No bio provided',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                ),
              if (skills.isNotEmpty ||
                  studies.isNotEmpty ||
                  experience.isNotEmpty)
                const SizedBox(height: 12),
              if (skills.isNotEmpty) ...[
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                    children: [
                      const TextSpan(
                        text: 'Skills: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: skills),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (studies.isNotEmpty) ...[
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                    children: [
                      const TextSpan(
                        text: 'Studies: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: studies),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (experience.isNotEmpty) ...[
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                    children: [
                      const TextSpan(
                        text: 'Experience: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: experience),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Pass',
                    icon: const Icon(Icons.close, color: Color(0xFF1B5E20)),
                    onPressed: () => _decide(
                      studentUserId,
                      'PASS',
                      studentPostId: studentPostId,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Like',
                    icon: const Icon(Icons.check, color: Color(0xFF1B5E20)),
                    onPressed: () => _decide(
                      studentUserId,
                      'LIKE',
                      studentPostId: studentPostId,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Save',
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_outline,
                      color: const Color(0xFF1B5E20),
                    ),
                    onPressed: () => _toggleSave(studentUserId,
                        studentPostId: studentPostId),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            // Already on Home screen
          }),
          _buildNavIcon(Icons.search, () {
            Navigator.pushNamed(context, '/search_company');
          }),
          _buildNavIcon(Icons.add, () {
            Navigator.pushNamed(context, '/newpost_company');
          }),
          _buildNavIcon(Icons.mail_outline, () {
            Navigator.pushNamed(context, '/messages_company');
          }, badgeCount: _unreadMessagesCount),
          _buildNavIcon(Icons.person_outline, () {
            Navigator.pushNamed(context, '/profile_company');
          }),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, VoidCallback onTap, {int? badgeCount}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1B5E20),
            size: 24,
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20), // κυπαρισσί
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
