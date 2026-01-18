import 'package:flutter/material.dart';
import '../app_services.dart';
import 'view_profile_student_screen.dart';

class SavedListingsCompanyScreen extends StatefulWidget {
  const SavedListingsCompanyScreen({super.key});

  @override
  State<SavedListingsCompanyScreen> createState() =>
      _SavedListingsCompanyScreenState();
}

class _SavedListingsCompanyScreenState
    extends State<SavedListingsCompanyScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _saved = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AppServices.saves.listCompanySavedStudents();
      if (!mounted) return;
      setState(() {
        _saved = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromSaved(int studentUserId, {int? studentPostId}) async {
    final idx = _saved.indexWhere(
        (x) => ((x['studentUserId'] ?? x['id']) as int) == studentUserId);
    if (idx == -1) return;
    final removed = _saved[idx];

    setState(() => _saved.removeAt(idx));

    try {
      await AppServices.saves.setCompanySaveStudent(
        studentUserId,
        false,
        studentPostId: studentPostId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved')),
      );
    } catch (e) {
      setState(() => _saved.insert(idx, removed));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove: $e')),
      );
    }
  }

  Future<void> _decideOnSaved(int studentUserId, String decision,
      {int? studentPostId}) async {
    // optimistic: remove card from UI
    final idx = _saved.indexWhere(
        (x) => ((x['studentUserId'] ?? x['id']) as int) == studentUserId);
    dynamic removed;
    int? removedIndex;
    if (idx != -1) {
      removedIndex = idx;
      removed = _saved[idx];
      setState(() {
        _saved.removeAt(idx);
      });
    }

    try {
      if (studentPostId != null && studentPostId != 0) {
        await AppServices.feed.decideOnStudentPost(studentPostId, decision);
      } else {
        await AppServices.feed.decideOnStudent(studentUserId, decision);
      }

      // After LIKE, refresh /applications so Messages/Chat can show
      AppServices.events.applicationsChanged();

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
      // revert if failed
      if (removed != null && removedIndex != null) {
        final safeIndex = removedIndex.clamp(0, _saved.length);
        setState(() {
          _saved.insert(safeIndex, removed);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not send decision: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFD9F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B5E20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Candidates',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Trirong',
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load saved candidates:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Trirong'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSaved,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_saved.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadSaved,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
        itemCount: _saved.length,
        itemBuilder: (context, index) {
          final c = _saved[index];

          final int studentUserId = (c['studentUserId'] ?? c['id']) as int;
          final int? studentPostId =
              (c['studentPostId'] ?? c['postId']) as int?;
          final String rawName =
              (c['name'] ?? c['studentName'] ?? c['fullName'] ?? '') as String;
          final String firstName = (c['firstName'] ?? '') as String;
          final String lastName = (c['lastName'] ?? '') as String;
          final String name =
              rawName.isNotEmpty ? rawName : '$firstName $lastName'.trim();
          final String university = (c['university'] ?? '') as String;
          final String major = (c['major'] ?? c['department'] ?? '') as String;
          final String description =
              (c['description'] ?? c['bio'] ?? '') as String;

          return _buildCandidateCard(
            studentUserId: studentUserId,
            studentPostId: studentPostId,
            name: name,
            university: university,
            major: major,
            description: description,
            onUnsave: () =>
                _removeFromSaved(studentUserId, studentPostId: studentPostId),
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewProfileStudentScreen(student: c),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Saved Candidates',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add candidates to your favorites to see them here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontFamily: 'Trirong',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard({
    required int studentUserId,
    required int? studentPostId,
    required String name,
    required String university,
    required String major,
    required String description,
    required VoidCallback onUnsave,
    required VoidCallback onViewDetails,
  }) {
    return Dismissible(
      key: Key('saved_candidate_$studentUserId'),
      direction: DismissDirection.startToEnd, // Swipe right
      confirmDismiss: (direction) async {
        // Swipe right = LIKE
        await _decideOnSaved(studentUserId, "LIKE",
            studentPostId: studentPostId);
        return true;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Student',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          major.isNotEmpty ? major : 'Department',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Color(0xFF1B5E20)),
                    onPressed: onUnsave,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.school, size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      university.isNotEmpty ? university : 'University',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Trirong',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description.isNotEmpty ? description : 'No bio yet',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontFamily: 'Trirong',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onViewDetails,
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Trirong',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
