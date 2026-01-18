import 'package:flutter/material.dart';
import '../app_services.dart';
import 'message_chat_screen.dart';
import '../utils/application_status.dart';
import '../utils/application_context.dart';
import 'dart:async';

class MessagesStudentScreen extends StatefulWidget {
  const MessagesStudentScreen({super.key});

  @override
  State<MessagesStudentScreen> createState() => _MessagesStudentScreenState();
}

class _MessagesStudentScreenState extends State<MessagesStudentScreen>
    with WidgetsBindingObserver {
  String _selectedFilter = 'All';

  bool _showFilter = false;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _applications = [];

  Timer? _pollTimer;

  // Local (best-effort) seen state: when a conversation is opened we record the
  // current preview token; dot shows again if preview changes later.
  final Map<int, String> _seenPreviewTokenByConversationId = {};

  // When backend updates system messages faster than /applications.status,
  // we infer resolved state from the conversation's last system message.
  final Map<int, String> _conversationLastSystemText = {};
  final Map<int, DateTime> _conversationLastFetchedAt = {};

  final List<String> filters = [
    'All',
    'ACCEPTED',
    'PENDING',
    'DECLINED',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppServices.events.addListener(_onApplicationsChanged);
    _loadApplications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppServices.events.removeListener(_onApplicationsChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onApplicationsChanged() {
    if (!mounted) return;
    _loadApplications();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadApplications();
    }
  }

  bool _shouldHideApplication(Map item) {
    final statusRaw = (item['status'] ?? '').toString();
    final status = normalizeApplicationStatus(statusRaw);
    final lastMessage = (item['lastMessage'] ?? '').toString().trim();

    // If the very first reaction was PASS, we should not create a Messages entry.
    // Client-side best effort: hide declined entries that don't have a conversation
    // and no lastMessage.
    if (status == 'DECLINED') {
      final cidRaw = item['conversationId'];
      final cid =
          cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
      if ((cid == null || cid == 0) && lastMessage.isEmpty) return true;
    }

    return false;
  }

  void _updatePolling() {
    final hasPending = _applications.any((a) {
      if (a is! Map) return false;
      final statusRaw = (a['status'] ?? '').toString();
      final lastMessage = (a['lastMessage'] ?? '').toString();
      final cidRaw = a['conversationId'];
      final cid =
          cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
      final derived = deriveApplicationStatus(
        applicationStatusRaw: statusRaw,
        lastMessage: lastMessage,
        lastSystemMessage:
            cid == null ? null : _conversationLastSystemText[cid],
      );
      return derived == 'PENDING';
    });

    if (!hasPending) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    _pollTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _loadApplications();
    });
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await AppServices.applications.listApplications();
      if (!mounted) return;

      final apps = _dedupByConversationId(data)
          .where((item) => item is Map ? !_shouldHideApplication(item) : true)
          .toList();

      setState(() {
        _applications = apps;
        _isLoading = false;
      });
      _updatePolling();

      // After showing the list, try to resolve pending items by looking at
      // conversation system messages (LIKE->PASS and LIKE->LIKE flows).
      await _refreshConversationStatusOverrides(apps);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshConversationStatusOverrides(List<dynamic> apps) async {
    final List<Future<void>> tasks = [];
    bool didUpdateAny = false;

    for (final a in apps) {
      if (a is! Map) continue;

      final cidRaw = a['conversationId'];
      final cid =
          cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
      if (cid == null || cid == 0) continue;

      final statusRaw = (a['status'] ?? '').toString();
      final lastMessage = (a['lastMessage'] ?? '').toString();

      final derived = deriveApplicationStatus(
        applicationStatusRaw: statusRaw,
        lastMessage: lastMessage,
        lastSystemMessage: _conversationLastSystemText[cid],
      );

      if (derived != 'PENDING') continue;

      final lastFetched = _conversationLastFetchedAt[cid];
      if (lastFetched != null &&
          DateTime.now().difference(lastFetched) <
              const Duration(seconds: 10)) {
        continue;
      }

      tasks.add(() async {
        _conversationLastFetchedAt[cid] = DateTime.now();
        try {
          final messages = await AppServices.chat.getMessages(cid);
          String? lastSystemText;
          for (var i = messages.length - 1; i >= 0; i--) {
            final m = messages[i];
            if (m is! Map) continue;
            final bool isSystem = (m['isSystem'] == true) ||
                (m['type']?.toString().toUpperCase() == 'SYSTEM');
            if (!isSystem) continue;
            final txt = (m['text'] ?? m['message'] ?? '').toString();
            if (txt.trim().isEmpty) continue;
            lastSystemText = txt;
            break;
          }

          if (lastSystemText != null && lastSystemText.trim().isNotEmpty) {
            if (_conversationLastSystemText[cid] != lastSystemText) {
              _conversationLastSystemText[cid] = lastSystemText;
              didUpdateAny = true;
            }
          }
        } catch (_) {
          // best effort
        }
      }());
    }

    if (tasks.isEmpty) return;
    await Future.wait(tasks);

    if (!mounted) return;
    if (didUpdateAny) {
      setState(() {
        // trigger rebuild so derived statuses update
      });
      _updatePolling();
    }
  }

  List<dynamic> _dedupByConversationId(List<dynamic> raw) {
    final Map<String, dynamic> byKey = {};
    for (final item in raw) {
      final cidRaw = item['conversationId'];
      final cid =
          cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
      // use conversationId if present, else fall back to otherPartyName to avoid duplicates
      final otherParty =
          (item['otherPartyName'] ?? item['company'] ?? '').toString();
      final adLabel = item is Map ? extractAdLabel(item) : '';
      final key =
          cid != null ? 'cid_$cid' : 'party_${otherParty}_ad_${adLabel.trim()}';
      if (key.trim().isEmpty) continue;
      byKey[key] = item; // keep last occurrence
    }
    return byKey.values.toList();
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
              //  SafeArea μόνο για το header (όπως Home/Search)
              SafeArea(
                bottom: false,
                child: _buildStickyHeader(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  //  χώρο για να μη “κάθονται” τα items κάτω από το navbar
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
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

          // Bottom navigation FULL WIDTH όπως στο Home (χωρίς SafeArea μέσα)
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
                'Messages',
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
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _showFilter = false; // προαιρετικό
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      filter,
                      style: TextStyle(
                        fontSize: 13,
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

  Widget _buildMessageItem(Map<String, dynamic> message) {
    return GestureDetector(
      onTap: () {
        final cid = message['conversationId'] is int
            ? message['conversationId'] as int
            : int.tryParse(message['conversationId']?.toString() ?? '') ?? 0;
        if (cid == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation not available yet'),
            ),
          );
          return;
        }

        final token = (message['previewToken'] ?? '').toString();
        setState(() {
          _seenPreviewTokenByConversationId[cid] = token;
        });

        final derived = deriveApplicationStatus(
          applicationStatusRaw: (message['status'] ?? '').toString(),
          lastMessage: (message['lastMessage'] ?? '').toString(),
          lastSystemMessage: _conversationLastSystemText[cid],
        );

        //  ΕΔΩ είναι το (1)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: cid,
              title: (message['company'] ?? '').toString(),
              contextLine: message['contextLine'] ?? '',
              subtitle: displayApplicationStatus(derived),
              canSend: derived == 'ACCEPTED',
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
          color: Colors.grey[100],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1B5E20),
                  width: 1.5,
                ),
              ),
              child: message['companyProfileImageUrl'] != null
                  ? ClipOval(
                      child: Image.network(
                        message['companyProfileImageUrl'],
                        fit: BoxFit.cover,
                        width: 38,
                        height: 38,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.business,
                          size: 20,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.business,
                        size: 20,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (message['displayTitle'] ?? message['company'] ?? '')
                        .toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    () {
                      final last = (message['lastMessage'] ?? '').trim();
                      final lastSystem =
                          (message['lastSystemMessage'] ?? '').trim();
                      final type = (message['type'] ?? '').toUpperCase();

                      // Avoid showing a stale pending placeholder when the
                      // actual application status has already moved on.
                      if (last.isNotEmpty &&
                          normalizeApplicationStatus(last) == 'PENDING' &&
                          type != 'PENDING') {
                        return message['status']!;
                      }

                      // Prefer an actual system message over a stale placeholder.
                      if ((last.isEmpty ||
                              normalizeApplicationStatus(last) == 'PENDING') &&
                          lastSystem.isNotEmpty) {
                        return lastSystem;
                      }

                      return last.isNotEmpty ? last : message['status']!;
                    }(),
                    style: TextStyle(
                      fontSize: 12,
                      color: (message['type'] ?? '').toUpperCase() == 'DECLINED'
                          ? Colors.red
                          : const Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (message['showUnseenDot'] == true)
              const Icon(
                Icons.circle,
                size: 8,
                color: Color(0xFF1B5E20),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Navbar ίδιο με Home (χωρίς SafeArea wrapper)
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
            // already on Messages screen
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Failed to load applications:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Trirong'),
            ),
          ),
          ElevatedButton(
              onPressed: _loadApplications, child: const Text('Retry')),
        ],
      );
    }

    final filtered = _selectedFilter == 'All'
        ? _applications
        : _applications.where((a) {
            if (a is! Map) return false;
            final statusRaw = (a['status'] ?? '').toString();
            final lastMessage = (a['lastMessage'] ?? '').toString();
            final cidRaw = a['conversationId'];
            final cid =
                cidRaw is int ? cidRaw : int.tryParse(cidRaw?.toString() ?? '');
            final derived = deriveApplicationStatus(
              applicationStatusRaw: statusRaw,
              lastMessage: lastMessage,
              lastSystemMessage:
                  cid == null ? null : _conversationLastSystemText[cid],
            );
            return derived == _selectedFilter;
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No messages',
            style: TextStyle(fontFamily: 'Trirong'),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index] as Map;
        final statusRaw = (item['status'] ?? '').toString();
        final lastMessage = (item['lastMessage'] ?? '').toString();
        final conversationId = (item['conversationId'] as int?) ?? 0;
        final derived = deriveApplicationStatus(
          applicationStatusRaw: statusRaw,
          lastMessage: lastMessage,
          lastSystemMessage: conversationId == 0
              ? null
              : _conversationLastSystemText[conversationId],
        );
        final statusText = displayApplicationStatus(derived);
        final company =
            (item['otherPartyName'] ?? item['company'] ?? 'Company') as String;
        final adLabel = extractAdLabel(item);
        final displayTitle = buildConversationListTitle(
          otherPartyName: company,
          adLabel: adLabel,
        );
        final lastMessageForUi = (item['lastMessage'] ?? '') as String;

        final unreadRaw =
            item['unreadCount'] ?? item['unread'] ?? item['isUnread'];
        int? unreadCount;
        if (unreadRaw is int) {
          unreadCount = unreadRaw;
        } else if (unreadRaw is bool) {
          unreadCount = unreadRaw ? 1 : 0;
        } else {
          unreadCount = int.tryParse(unreadRaw?.toString() ?? '');
        }

        final lastSystem = conversationId == 0
            ? ''
            : (_conversationLastSystemText[conversationId] ?? '');
        final previewToken = (lastSystem.trim().isNotEmpty
                ? lastSystem.trim()
                : (lastMessageForUi.trim().isNotEmpty
                    ? lastMessageForUi.trim()
                    : statusText.trim()))
            .trim();

        final seenToken = _seenPreviewTokenByConversationId[conversationId];
        final showUnseenDot = conversationId != 0
            ? (unreadCount != null
                ? unreadCount > 0
                : (seenToken != previewToken))
            : false;

        return _buildMessageItem({
          'company': company,
          'displayTitle': displayTitle,
          'contextLine': adLabel,
          'status': statusText,
          'type': derived,
          'conversationId': conversationId,
          'lastMessage': lastMessageForUi,
          'lastSystemMessage': conversationId == 0 ? '' : lastSystem,
          'previewToken': previewToken,
          'showUnseenDot': showUnseenDot,
        });
      },
    );
  }
}
