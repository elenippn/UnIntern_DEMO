import 'package:flutter/material.dart';
import '../app_services.dart'; // άλλαξε path αν χρειάζεται
import '../models/internship_post_dto.dart';
import '../utils/api_error_message.dart';
import '../utils/api_url.dart';
import '../utils/internship_departments.dart';
import '../widgets/app_cached_image.dart';
import 'view_profile_company_screen.dart';

class HomeStudentScreen extends StatefulWidget {
  const HomeStudentScreen({super.key});

  @override
  State<HomeStudentScreen> createState() => _HomeStudentScreenState();
}

class _HomeStudentScreenState extends State<HomeStudentScreen> {
  Set<String> _selectedDepartments = {'All'};
  bool _showFilter = false;

  bool _isLoading = true;
  String? _error;

  // Θα γεμίσει από backend (/feed/student)
  List<InternshipPostDto> _internships = [];

  // Local "saved" state (για να αλλάζει το icon άμεσα)
  final Set<int> _savedPostIds = {};

  // Unread messages count for notification badge
  int _unreadMessagesCount = 0;

  final List<String> departments = internshipDepartments;

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

      print('┌─────────────────────────────────────────────────┐');
      print('│ 📱 HOME STUDENT SCREEN - FILTER DEBUG          │');
      print('├─────────────────────────────────────────────────┤');
      print('│ Selected Departments Set: $_selectedDepartments');
      print('│ Contains "All"? ${_selectedDepartments.contains('All')}');
      print('│ Is Empty? ${_selectedDepartments.isEmpty}');
      print(
          '│ First item: ${_selectedDepartments.isNotEmpty ? _selectedDepartments.first : 'N/A'}');
      print('├─────────────────────────────────────────────────┤');
      print('│ FINAL Department Filter: "$departmentFilter"');
      print('│ Filter Type: ${departmentFilter.runtimeType}');
      print('│ Filter Length: ${departmentFilter?.length ?? 'null'}');
      print('└─────────────────────────────────────────────────┘');

      final data =
          await AppServices.feed.getStudentFeed(department: departmentFilter);

      print('✅ RESPONSE RECEIVED');
      print('   Total posts: ${data.length}');
      print('   Posts by department:');
      final deptMap = <String, int>{};
      for (var post in data) {
        final dept = post.department ?? 'NO_DEPARTMENT';
        deptMap[dept] = (deptMap[dept] ?? 0) + 1;
      }
      deptMap.forEach((dept, count) {
        print('     - $dept: $count posts');
      });

      if (!mounted) return;

      print('\n📋 POSTS TO BE DISPLAYED:');
      for (var i = 0; i < data.length; i++) {
        print('   [$i] ${data[i].title}');
        print('       └─ department: "${data[i].department}"');
      }
      print('');

      setState(() {
        _internships = data;
        _savedPostIds
          ..clear()
          ..addAll(data.where((p) => p.saved).map<int>((p) => p.id));
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

  Future<void> _toggleSave(int postId) async {
    final wasSaved = _savedPostIds.contains(postId);

    // optimistic update
    setState(() {
      if (wasSaved) {
        _savedPostIds.remove(postId);
      } else {
        _savedPostIds.add(postId);
      }
    });

    try {
      await AppServices.saves.setStudentSave(postId, !wasSaved);
    } catch (e) {
      // revert on error
      setState(() {
        if (wasSaved) {
          _savedPostIds.add(postId);
        } else {
          _savedPostIds.remove(postId);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not save: $e")),
      );
    }
  }

  // (προαιρετικό) like/pass με κουμπιά ή swipe later
  Future<void> _decide(int postId, String decision) async {
    // optimistic: remove card from UI
    final index = _internships.indexWhere((p) => p.id == postId);
    int? removedIndex;
    InternshipPostDto? removed;
    if (index != -1) {
      removedIndex = index;
      removed = _internships[index];
      setState(() {
        _internships.removeAt(index);
      });
    }

    try {
      await AppServices.feed.decideOnPost(postId, decision);

      // Spec: after LIKE, refresh /applications so Messages/Chat can show
      // pending/declined immediately. For PASS we do nothing (no chat created).
      if (decision.toUpperCase() == 'LIKE') {
        AppServices.events.applicationsChanged();

        // Show confirmation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Internship liked! Check your messages."),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      // revert if failed
      final restored = removed;
      final restoredIndex = removedIndex;
      if (restored != null && restoredIndex != null) {
        final safeIndex = restoredIndex.clamp(0, _internships.length);
        setState(() {
          _internships.insert(safeIndex, restored);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not send decision: $e")),
      );
    }
  }

  List<InternshipPostDto> get _filteredInternships {
    // Το backend κάνει το φιλτράρισμα, οπότε απλώς δείχνουμε τα δεδομένα που λήφθησαν
    return _internships;
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
                child: RefreshIndicator(
                  onRefresh: _loadFeed,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
              "Failed to load feed:\n$_error",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final items = _filteredInternships;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "No internships available",
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
        return _buildInternshipCard(items[index]);
      },
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
                'Internship Ads',
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
              print('\n🖱️  FILTER CLICKED!');
              print('   Clicked department: "$dept"');

              // Single selection: Αλλάζουμε απευθείας την επιλογή
              _selectedDepartments.clear();
              _selectedDepartments.add(dept);
              print('   Action: Selected only "$dept"');
              print('   Updated _selectedDepartments: $_selectedDepartments');

              // Κλείνουμε το filter dropdown
              setState(() {
                _showFilter = false;
              });

              print('   Calling _loadFeed()...');
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

  Widget _buildInternshipCard(InternshipPostDto internship) {
    final int postId = internship.id;
    final String companyName = internship.companyName?.isNotEmpty == true
        ? internship.companyName!
        : 'Company';
    final String title = internship.title;
    final String description = internship.description;
    final String location = internship.location ?? '';
    final String? imageUrl = resolveApiUrl(
      internship.imageUrl,
      baseUrl: AppServices.baseUrl,
    );

    final String? companyProfileImageUrl = resolveApiUrl(
      internship.profileImageUrl,
      baseUrl: AppServices.baseUrl,
    );

    final bool isSaved = _savedPostIds.contains(postId);

    return Dismissible(
      key: Key('internship_$postId'),
      direction:
          DismissDirection.startToEnd, // Swipe right (από αριστερά προς δεξιά)
      confirmDismiss: (direction) async {
        // Swipe right = LIKE
        await _decide(postId, "LIKE");
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
        onDoubleTap: () => _toggleSave(postId),
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
                      imageUrl: companyProfileImageUrl,
                      size: 32,
                      fallbackIcon: Icons.business,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProfileCompanyScreen(
                            company: {
                              'companyName': companyName,
                              'userId': internship.companyUserId,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCachedImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20),
                                fontFamily: 'Trirong',
                              ),
                            ),
                          ),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 14, color: Color(0xFF1B5E20)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1B5E20),
                                    fontFamily: 'Trirong',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            3,
                            (i) => Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions row (προσωρινό like/pass + save)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: "Pass",
                    icon: const Icon(Icons.close, color: Color(0xFF1B5E20)),
                    onPressed: () => _decide(postId, "PASS"),
                  ),
                  IconButton(
                    tooltip: "Like",
                    icon: const Icon(Icons.check, color: Color(0xFF1B5E20)),
                    onPressed: () => _decide(postId, "LIKE"),
                  ),
                  IconButton(
                    tooltip: "Save",
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_outline,
                      color: const Color(0xFF1B5E20),
                    ),
                    onPressed: () => _toggleSave(postId),
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
          _buildNavIcon(Icons.home, () {}),
          _buildNavIcon(Icons.search, () {
            Navigator.pushNamed(context, '/search_student');
          }),
          _buildNavIcon(Icons.add, () {
            Navigator.pushNamed(context, '/newpost_student');
          }),
          _buildNavIcon(Icons.mail_outline, () {
            Navigator.pushNamed(context, '/messages_student');
          }, badgeCount: _unreadMessagesCount),
          _buildNavIcon(Icons.person_outline, () {
            Navigator.pushNamed(context, '/profile_student');
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
