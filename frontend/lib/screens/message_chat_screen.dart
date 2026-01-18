import 'package:flutter/material.dart';
import '../app_services.dart';
import 'camera_screen.dart';
import 'add_file_screen.dart';
import '../utils/application_status.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String title;
  final String contextLine;
  final String subtitle;
  final bool canSend;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.contextLine = '',
    required this.subtitle,
    required this.canSend,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _showAttachmentMenu = false;
  bool _loadingMessages = true;
  String? _error;
  List<dynamic> _messages = [];

  int? _myUserId;
  String? _myRole;
  String? _myDisplayName;
  String? _myAvatarUrl;
  Future<void>? _meFuture;

  late String _subtitle;
  late bool _canSend;
  Timer? _statusPollTimer;
  bool _didRefreshAfterResolve = false;

  @override
  void initState() {
    super.initState();
    _subtitle = widget.subtitle;
    _canSend = widget.canSend;
    AppServices.events.addListener(_onApplicationsChanged);
    _markReadAndRefresh();
    _loadMessages();
    _startStatusPollingIfNeeded();
  }

  Future<void> _ensureMeLoaded() {
    return _meFuture ??= () async {
      try {
        final me = await AppServices.auth.getMe();
        _myUserId = me.id;
        _myRole = me.role;
        final role = (me.role ?? '').toUpperCase();
        if (role == 'COMPANY' && (me.companyName ?? '').trim().isNotEmpty) {
          _myDisplayName = me.companyName;
        } else {
          final full = '${me.name} ${me.surname}'.trim();
          _myDisplayName = full.isNotEmpty ? full : me.username;
        }
        _myAvatarUrl = me.profileImageUrl;
      } catch (_) {
        // best effort
      }
    }();
  }

  int? _tryParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String? _normalizeRole(dynamic value) {
    final v = value?.toString().trim();
    if (v == null || v.isEmpty) return null;
    return v.toUpperCase();
  }

  String? _extractSenderName(Map m) {
    final sender = m['sender'];
    if (sender is Map) {
      final name = sender['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    for (final key in const [
      'senderName',
      'sender_name',
      'name',
      'username',
    ]) {
      final v = m[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  String? _extractSenderAvatarUrl(Map m) {
    final sender = m['sender'];
    if (sender is Map) {
      final url = sender['avatarUrl']?.toString().trim();
      if (url != null && url.isNotEmpty) return url;
    }

    for (final key in const [
      'senderProfileImageUrl',
      'sender_profile_image_url',
      'profileImageUrl',
      'profile_image_url',
      'avatarUrl',
      'avatar_url',
    ]) {
      final v = m[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Map<String, dynamic> _normalizeMessage(Map m) {
    final normalized = Map<String, dynamic>.from(m);

    normalized['senderId'] = _tryParseInt(normalized['senderId']);

    final rawType = normalized['type'];
    String? type = rawType?.toString().trim().toUpperCase();

    final legacyIsSystem = (normalized['isSystem'] == true) ||
        (normalized['messageType']?.toString().toUpperCase() == 'SYSTEM');
    if (type == null || type.isEmpty) {
      type = legacyIsSystem ? 'SYSTEM' : 'USER';
    }
    if (normalized['senderId'] == null) {
      type = 'SYSTEM';
    }
    normalized['type'] = type;

    normalized['text'] = (normalized['text'] ?? normalized['message'] ?? '').toString();
    normalized['createdAt'] = (normalized['createdAt'] ??
            normalized['created_at'] ??
            normalized['timestamp'] ??
            normalized['time'])
        ?.toString();

    final sender = normalized['sender'];
    if (sender is Map) {
      final senderMap = Map<String, dynamic>.from(sender);
      senderMap['id'] = _tryParseInt(senderMap['id'] ?? senderMap['userId']);
      senderMap['role'] = _normalizeRole(senderMap['role'] ?? senderMap['type']);
      senderMap['name'] = senderMap['name']?.toString();
      senderMap['avatarUrl'] = senderMap['avatarUrl']?.toString();
      normalized['sender'] = senderMap;
    }

    normalized['senderRole'] =
        _normalizeRole(normalized['senderRole'] ?? normalized['sender_role']);

    final isMine = normalized['isMine'];
    if (isMine is bool) {
      normalized['isMine'] = isMine;
    } else {
      normalized['isMine'] = null;
    }

    return normalized;
  }

  List<dynamic> _normalizeMessages(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map((m) => _normalizeMessage(m))
      .toList(growable: true);
  }

  int? _extractSenderUserId(Map m) {
    final direct = _tryParseInt(m['senderId']);
    if (direct != null) return direct;

    final sender = m['sender'];
    if (sender is Map) {
      final id = _tryParseInt(sender['id'] ?? sender['userId'] ?? sender['user_id']);
      if (id != null) return id;
    }

    return null;
  }

  String? _extractSenderRole(Map m) {
    for (final key in const [
      'senderRole',
      'sender_role',
      'senderType',
      'sender_type',
      'role',
      'fromRole',
      'from_role',
    ]) {
      final role = _normalizeRole(m[key]);
      if (role != null) return role;
    }

    for (final key in const [
      'sender',
      'fromUser',
      'from',
      'user',
      'author',
      'owner',
    ]) {
      final v = m[key];
      if (v is Map) {
        final role = _normalizeRole(v['role'] ?? v['type']);
        if (role != null) return role;
      }
    }

    return null;
  }

  bool _computeIsMe(Map m) {
    final isMine = m['isMine'];
    if (isMine is bool) return isMine;

    final type = m['type']?.toString().toUpperCase();
    if (type == 'SYSTEM' || m['senderId'] == null) return false;

    final legacy = (m['isMine'] == true) || (m['fromMe'] == true) || (m['isMe'] == true);
    if (legacy) return true;

    final senderId = _extractSenderUserId(m);
    if (senderId != null && _myUserId != null) {
      return senderId == _myUserId;
    }

    final senderRole = _extractSenderRole(m);
    final myRole = _normalizeRole(_myRole);
    if (senderRole != null && myRole != null) {
      return senderRole == myRole;
    }

    return false;
  }

  Future<void> _markReadAndRefresh() async {
    if (widget.conversationId == 0) return;
    try {
      await AppServices.chat.markConversationRead(widget.conversationId);
    } catch (_) {
      // best effort
    }

    // Ensure lists refresh unreadCount immediately.
    AppServices.events.applicationsChanged();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    AppServices.events.removeListener(_onApplicationsChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onApplicationsChanged() {
    if (!mounted) return;
    // Force a quick refresh so the latest system message appears.
    _loadMessages();
    _startStatusPollingIfNeeded();
  }

  void _startStatusPollingIfNeeded() {
    if (_canSend) return;
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (!mounted) return;
      final app = await AppServices.applications.getByConversationId(
        widget.conversationId,
      );
      if (!mounted || app == null) return;

      final statusRaw = (app['status'] ?? '').toString();
      final normalized = normalizeApplicationStatus(statusRaw);
      final display = displayApplicationStatus(statusRaw);

      final nextCanSend = normalized == 'ACCEPTED';
      final nextSubtitle = display.isNotEmpty ? display : _subtitle;

      if (nextCanSend != _canSend || nextSubtitle != _subtitle) {
        setState(() {
          _canSend = nextCanSend;
          _subtitle = nextSubtitle;
        });
      }

      // Stop polling once resolved.
      if (normalized != 'PENDING') {
        if (!_didRefreshAfterResolve) {
          _didRefreshAfterResolve = true;
          _loadMessages();
        }
        _statusPollTimer?.cancel();
        _statusPollTimer = null;
      } else {
        // Fallback: backend may update conversation system message before
        // applications status (LIKE->PASS). Try to infer resolved state.
        await _tryResolveFromConversationMessages();
      }
    });
  }

  Future<void> _tryResolveFromConversationMessages() async {
    try {
      final messages =
          await AppServices.chat.getMessages(widget.conversationId);
      final normalized = _normalizeMessages(messages);
      String? lastSystemText;
      for (var i = normalized.length - 1; i >= 0; i--) {
        final m = normalized[i];
        final bool isSystem =
            (m['type']?.toString().toUpperCase() == 'SYSTEM') ||
                (m['senderId'] == null);
        if (!isSystem) continue;
        final txt = (m['text'] ?? '').toString();
        if (txt.trim().isEmpty) continue;
        lastSystemText = txt;
        break;
      }

      final inferred = inferStatusFromSystemText(lastSystemText);
      if (inferred == null || inferred == 'PENDING') return;

      if (!mounted) return;
      setState(() {
        _canSend = inferred == 'ACCEPTED';
        _subtitle = displayApplicationStatus(inferred);
      });

      if (!_didRefreshAfterResolve) {
        _didRefreshAfterResolve = true;
        _messages = normalized;
        _loadingMessages = false;
      }

      _statusPollTimer?.cancel();
      _statusPollTimer = null;
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _error = null;
    });
    try {
      await _ensureMeLoaded();
      final data = await AppServices.chat.getMessages(widget.conversationId);
      final normalized = _normalizeMessages(data);
      if (!mounted) return;
      setState(() {
        _messages = normalized;
        _loadingMessages = false;
      });

      // Also update status from latest system message if present.
      await _tryResolveFromConversationMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingMessages = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Tap detector για να κλείσει το menu
          if (_showAttachmentMenu)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAttachmentMenu = false;
                });
              },
              child: Container(color: Colors.transparent),
            ),

          Column(
            children: [
              SafeArea(bottom: false, child: _buildHeader()),
              Expanded(child: _buildMessagesList()),
            ],
          ),

          // Input bar pinned κάτω (όπως Home/Search navbar logic)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInputBar(),
          ),

          // Attachment menu overlay
          if (_showAttachmentMenu)
            Positioned(
              bottom: 110,
              left: 16,
              child: _buildAttachmentMenu(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final headerTitle =
        widget.title.trim().isNotEmpty ? widget.title : 'UnIntern';
    final contextLine = widget.contextLine.trim();
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
                child: const Icon(Icons.arrow_back,
                    color: Color(0xFF1B5E20), size: 28),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    headerTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
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
          if (contextLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              contextLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1B5E20),
              fontFamily: 'Trirong',
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final canActuallySend = _canSend && widget.conversationId != 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Row(
        children: [
          // plus
          GestureDetector(
            onTap: () {
              setState(() {
                _showAttachmentMenu = !_showAttachmentMenu;
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                color: const Color(0xFFFAFD9F),
              ),
              child: const Icon(Icons.add, color: Color(0xFF1B5E20)),
            ),
          ),
          const SizedBox(width: 10),

          // text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFD9F),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF1B5E20), width: 2),
              ),
              child: Center(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Write here...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // send
          GestureDetector(
            onTap: canActuallySend
                ? _send
                : () {
                    final msg = widget.conversationId == 0
                        ? 'Conversation not available yet'
                        : 'Conversation not accepted yet';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        behavior: SnackBarBehavior.floating,
                        margin:
                            const EdgeInsets.fromLTRB(16, 0, 16, 110 + 16),
                      ),
                    );
                  },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                color:
                    canActuallySend ? const Color(0xFFFAFD9F) : Colors.grey[300],
              ),
              child: Icon(
                Icons.send,
                color: canActuallySend
                    ? const Color(0xFF1B5E20)
                    : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFD9F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B5E20), width: 2),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Camera option
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
              setState(() {
                _showAttachmentMenu = false;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B5E20), width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Color(0xFF1B5E20),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // File/Document option
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFileScreen()),
              );
              setState(() {
                _showAttachmentMenu = false;
              });
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B5E20), width: 2),
              ),
              child: const Icon(
                Icons.description,
                color: Color(0xFF1B5E20),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Failed to load messages:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Trirong', color: Color(0xFF1B5E20)),
              ),
            ),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(fontFamily: 'Trirong', color: Color(0xFF1B5E20)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 110, top: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index] as Map;
        final String text = (m['text'] ?? '').toString();
        final bool isSystem =
          (m['type']?.toString().toUpperCase() == 'SYSTEM') ||
            (m['senderId'] == null);
        final bool isMe = _computeIsMe(m);

        final String? senderName =
            isMe ? (_myDisplayName ?? _extractSenderName(m)) : _extractSenderName(m);
        final String? senderAvatarUrl = isMe
            ? (_myAvatarUrl ?? _extractSenderAvatarUrl(m))
            : _extractSenderAvatarUrl(m);
        final String? senderRole =
            isMe ? _myRole : (m['senderRole']?.toString());

        return _ChatBubble(
          text: text,
          isMe: isMe,
          isSystem: isSystem,
          senderName: senderName,
          senderAvatarUrl: senderAvatarUrl,
          senderRole: senderRole,
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_canSend || widget.conversationId == 0) return;

    await _ensureMeLoaded();

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'type': 'USER',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'senderId': _myUserId,
        'senderRole': _myRole,
        'isMine': true,
      });
    });
    _controller.clear();

    try {
      await AppServices.chat.sendMessage(widget.conversationId, text);
      if (mounted) {
        await _loadMessages();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110 + 16),
        ),
      );
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool isSystem;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? senderRole;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    this.isSystem = false,
    this.senderName,
    this.senderAvatarUrl,
    this.senderRole,
  });

  Widget _buildAvatar() {
    final url = senderAvatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final role = senderRole?.toString().trim().toUpperCase();
    final fallbackIcon = role == 'COMPANY' ? Icons.business : Icons.person;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFC9D3C9),
        border: Border.all(color: const Color(0xFF1B5E20), width: 1),
      ),
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    fallbackIcon,
                    size: 16,
                    color: const Color(0xFF1B5E20),
                  );
                },
              )
            : Icon(
                fallbackIcon,
                size: 16,
                color: const Color(0xFF1B5E20),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1B5E20), width: 1.5),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1B5E20),
                fontFamily: 'Trirong',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final bubbleColor =
        isMe ? const Color(0xFFFAFD9F) : const Color(0xFFC9D3C9);
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final name = senderName?.trim();
    final hasName = name != null && name.isNotEmpty;

    return Column(
      crossAxisAlignment: align,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
                if (hasName)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ] else ...[
                if (hasName)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1B5E20),
                      fontFamily: 'Trirong',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (hasName) const SizedBox(width: 8),
                _buildAvatar(),
              ]
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 260),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  border: Border.all(color: const Color(0xFF1B5E20), width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                    fontFamily: 'Trirong',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
