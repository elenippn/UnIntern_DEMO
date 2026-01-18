import 'package:flutter/material.dart';
import 'dart:async';
import '../app_services.dart';
import '../models/company_candidate_dto.dart';
import '../utils/api_error_message.dart';
import 'view_profile_student_screen.dart';

class SearchCompanyScreen extends StatefulWidget {
  const SearchCompanyScreen({super.key});

  @override
  State<SearchCompanyScreen> createState() => _SearchCompanyScreenState();
}

class _SearchCompanyScreenState extends State<SearchCompanyScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  List<CompanyCandidateDto> _allCandidates = [];
  List<CompanyCandidateDto> _filteredCandidates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllCandidates();
  }

  Future<void> _loadAllCandidates() async {
    setState(() {
      _error = null;
    });

    try {
      final candidates = await AppServices.feed.getCompanyFeed();
      print('🔍 Search Company: Loaded ${candidates.length} candidates');
      if (!mounted) return;
      setState(() {
        _allCandidates = candidates;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyApiError(e);
      });
      print('❌ Search Company Error: $_error');
    }
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredCandidates = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final lowerQuery = query.toLowerCase();
      print('\n🔎 SEARCHING for: "$query"');
      print('   Total candidates to search: ${_allCandidates.length}');
      
      final results = _allCandidates.where((candidate) {
        // Ψάχνουμε σε όλα τα σημαντικά fields
        final name = candidate.name.toLowerCase();
        final bio = (candidate.bio ?? '').toLowerCase();
        final university = (candidate.university ?? '').toLowerCase();
        final department = (candidate.department ?? '').toLowerCase();
        final studies = (candidate.studies ?? '').toLowerCase();
        final skills = (candidate.skills ?? '').toLowerCase();
        final experience = (candidate.experience ?? '').toLowerCase();
        
        // Check if query matches any field
        final matches = name.contains(lowerQuery) ||
            bio.contains(lowerQuery) ||
            university.contains(lowerQuery) ||
            department.contains(lowerQuery) ||
            studies.contains(lowerQuery) ||
            skills.contains(lowerQuery) ||
            experience.contains(lowerQuery);
        
        if (matches) {
          print('   ✅ MATCH: "${candidate.name}"');
          final matchedIn = <String>[];
          if (name.contains(lowerQuery)) matchedIn.add('name');
          if (bio.contains(lowerQuery)) matchedIn.add('bio');
          if (university.contains(lowerQuery)) matchedIn.add('university');
          if (department.contains(lowerQuery)) matchedIn.add('department');
          if (studies.contains(lowerQuery)) matchedIn.add('studies');
          if (skills.contains(lowerQuery)) matchedIn.add('skills');
          if (experience.contains(lowerQuery)) matchedIn.add('experience');
          print('      └─ Matched in: ${matchedIn.join(", ")}');
        }
        
        return matches;
      }).toList();
      
      print('   Results found: ${results.length}\n');
      
      setState(() {
        _filteredCandidates = results;
      });
    });
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
              SafeArea(bottom: false, child: _buildStickyHeader()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildSearchResults(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Navbar
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

  Widget _buildSearchResults() {
    if (!_isSearching) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Search for students',
            style: TextStyle(
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_error != null && _allCandidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'Error loading data',
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'Trirong',
            ),
          ),
        ),
      );
    }

    if (_filteredCandidates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'No students found',
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
      itemCount: _filteredCandidates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildSearchResultCard(_filteredCandidates[index]);
      },
    );
  }

  Widget _buildSearchResultCard(CompanyCandidateDto result) {
    final String name = result.name;
    final String? bio = result.bio;
    final String? university = result.university;
    final String? department = result.department;
    final String? studies = result.studies;
    final String? skills = result.skills;

    return GestureDetector(
      onTap: () {
        // View student profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfileStudentScreen(
              student: {
                'studentUserId': result.studentUserId,
                'id': result.studentUserId,
                'name': name,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF1B5E20),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1B5E20),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 28,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFF1B5E20),
                      ),
                    ],
                  ),
                  // University
                  if (university != null && university.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      university,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Department
                  if (department != null && department.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Department: $department',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Skills
                  if (skills != null && skills.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Skills: $skills',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Studies
                  if (studies != null && studies.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Studies: $studies',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _isSearching = value.isNotEmpty);
                      _performSearch(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Trirong',
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF1B5E20),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                      FocusScope.of(context).unfocus();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1B5E20),
                        fontFamily: 'Trirong',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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
            Navigator.pushNamed(context, '/home_company');
          }),
          _buildNavIcon(Icons.search, () {
            // Already on Search screen
          }),
          _buildNavIcon(Icons.add, () {
            Navigator.pushNamed(context, '/newpost_company');
          }),
          _buildNavIcon(Icons.mail_outline, () {
            Navigator.pushNamed(context, '/messages_company');
          }),
          _buildNavIcon(Icons.person_outline, () {
            Navigator.pushNamed(context, '/profile_company');
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
