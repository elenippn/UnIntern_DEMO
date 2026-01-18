import 'package:flutter/material.dart';
import '../app_services.dart';
import 'view_profile_company_screen.dart';

class SavedListingsStudentScreen extends StatefulWidget {
  const SavedListingsStudentScreen({super.key});

  @override
  State<SavedListingsStudentScreen> createState() =>
      _SavedListingsStudentScreenState();
}

class _SavedListingsStudentScreenState
    extends State<SavedListingsStudentScreen> {
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
      final data = await AppServices.saves.listStudentSavedPosts();
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

  Future<void> _removeFromSaved(int postId) async {
    // optimistic remove
    final idx =
        _saved.indexWhere((x) => ((x['postId'] ?? x['id']) as int) == postId);
    if (idx == -1) return;
    final removed = _saved[idx];

    setState(() => _saved.removeAt(idx));

    try {
      await AppServices.saves.setStudentSave(postId, false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from saved')),
      );
    } catch (e) {
      // revert
      setState(() => _saved.insert(idx, removed));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove: $e')),
      );
    }
  }

  Future<void> _decideOnSaved(int postId, String decision) async {
    // optimistic: remove card from UI
    final idx =
        _saved.indexWhere((x) => ((x['postId'] ?? x['id']) as int) == postId);
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
      await AppServices.feed.decideOnPost(postId, decision);

      // After LIKE, refresh /applications so Messages/Chat can show
      if (decision.toUpperCase() == 'LIKE') {
        AppServices.events.applicationsChanged();

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
          'Saved Listings',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Trirong',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load saved:\n$_error',
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

    if (_saved.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadSaved,
      child: ListView.builder(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        itemCount: _saved.length,
        itemBuilder: (context, index) {
          final item = _saved[index];

          // backend returns:
          // postId, companyName, title, location, description, savedAt
          final company = (item['companyName'] ?? 'Company') as String;
          final title = (item['title'] ?? '') as String;
          final location = (item['location'] ?? '') as String;
          final description = (item['description'] ?? '') as String;
          final postId = (item['postId'] ?? item['id']) as int;

          return _buildListingCard(
            listing: item,
            company: company,
            position: title,
            location: location,
            description: description,
            postId: postId,
            onUnsave: () => _removeFromSaved(postId),
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
            'No Saved Listings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add listings to your favorites to see them here',
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

  Widget _buildListingCard({
    required Map listing,
    required String company,
    required String position,
    required String location,
    required String description,
    required int postId,
    required VoidCallback onUnsave,
  }) {
    return Dismissible(
      key: Key('saved_$postId'),
      direction: DismissDirection.startToEnd, // Swipe right
      confirmDismiss: (direction) async {
        // Swipe right = LIKE
        await _decideOnSaved(postId, "LIKE");
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
                          company,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                            fontFamily: 'Trirong',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          position,
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
                  const Icon(Icons.location_on,
                      size: 16, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
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
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontFamily: 'Trirong',
                ),
                maxLines: 2,
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ViewProfileCompanyScreen(company: listing),
                    ),
                  );
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Trirong',
                  ),
                ),
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
            Navigator.pushNamed(context, '/home_student');
          }),
          _buildNavIcon(Icons.search, () {
            Navigator.pushNamed(context, '/search_student');
          }),
          _buildNavIcon(Icons.add, () {
            Navigator.pushNamed(context, '/newpost_student');
          }),
          _buildNavIcon(Icons.mail_outline, () {
            Navigator.pushNamed(context, '/messages_student');
          }),
          _buildNavIcon(Icons.person_outline, () {
            Navigator.pushNamed(context, '/profile_student');
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
