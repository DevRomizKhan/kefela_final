import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  File? _selectedFile;
  String _currentUserName = 'User';
  String _currentUserId = '';
  bool _isFileSelected = false;
  String _fileType = '';
  bool _isSending = false;
  bool _showScrollToBottom = false;
  int _memberCount = 0;

  // Cache for user data to avoid repeated Firestore calls
  final Map<String, String> _userNameCache = {};

  // Optimistic message queue
  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
    _scrollController.addListener(_scrollListener);

    // Load member count once
    _loadMemberCount();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;

      if (_showScrollToBottom != !isAtBottom) {
        setState(() {
          _showScrollToBottom = !isAtBottom;
        });
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _loadMemberCount() async {
    try {
      final members = await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .get();

      if (mounted) {
        setState(() {
          _memberCount = members.docs.length;
        });
      }
    } catch (e) {
      print('Error loading member count: $e');
    }
  }

  Future<void> _fetchCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _currentUserName = userDoc['name'] ?? 'Unknown User';
          });
          _userNameCache[user.uid] = _currentUserName;
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<String> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.exists ? userDoc['name'] ?? 'Unknown User' : 'Unknown User';
      _userNameCache[userId] = userName;
      return userName;
    } catch (e) {
      return 'Unknown User';
    }
  }

  Future<void> _pickFile() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _isFileSelected = true;
          _fileType = 'image';
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        _showSnackBar('Error picking file', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _selectedFile == null) || _isSending) {
      return;
    }

    final messageText = _messageController.text.trim();
    final file = _selectedFile;
    final fileType = _fileType;

    // Clear inputs immediately for better UX
    _messageController.clear();
    setState(() {
      _selectedFile = null;
      _isFileSelected = false;
      _fileType = '';
      _isSending = true;
    });

    // Scroll to bottom immediately
    Future.delayed(const Duration(milliseconds: 50), () {
      _scrollToBottom(animate: false);
    });

    String? fileUrl;
    String? fileName;

    // Upload file if selected
    if (file != null) {
      try {
        fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref().child('group_chats/${widget.groupId}/$fileName');

        await ref.putFile(file);
        fileUrl = await ref.getDownloadURL();
      } catch (e) {
        print('Error uploading file: $e');
        if (mounted) {
          _showSnackBar('Failed to upload image', isError: true);
          setState(() {
            _isSending = false;
          });
        }
        return;
      }
    }

    // Send message
    try {
      await _firestore.collection('groups/${widget.groupId}/messages').add({
        'text': messageText,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'reactions': {},
        'isDeleted': false,
      });

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        _showSnackBar('Failed to send message', isError: true);
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Message?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text('This message will be deleted for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('groups/${widget.groupId}/messages')
            .doc(messageId)
            .update({
          'isDeleted': true,
          'text': 'This message was deleted',
          'fileUrl': null,
          'fileName': null,
          'fileType': null,
        });
      } catch (e) {
        print('Error deleting message: $e');
        if (mounted) {
          _showSnackBar('Failed to delete message', isError: true);
        }
      }
    }
  }

  Future<void> _addReaction(String messageId, String reaction) async {
    try {
      final messageRef = _firestore
          .collection('groups/${widget.groupId}/messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final messageDoc = await transaction.get(messageRef);

        if (!messageDoc.exists) return;

        final currentReactions = Map<String, dynamic>.from(
            messageDoc['reactions'] as Map<String, dynamic>? ?? {});

        if (currentReactions.containsKey(_currentUserId) &&
            currentReactions[_currentUserId] == reaction) {
          currentReactions.remove(_currentUserId);
        } else {
          currentReactions[_currentUserId] = reaction;
        }

        transaction.update(messageRef, {'reactions': currentReactions});
      });
    } catch (e) {
      print('Error adding reaction: $e');
    }
  }

  void _showReactionDialog(String messageId, Map<String, dynamic> currentReactions) {
    final userReaction = currentReactions[_currentUserId];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                if (userReaction != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Your reaction: $userReaction',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildReactionOption(messageId, '👍', 'Like', currentReactions),
                    _buildReactionOption(messageId, '❤️', 'Love', currentReactions),
                    _buildReactionOption(messageId, '😂', 'Haha', currentReactions),
                    _buildReactionOption(messageId, '😮', 'Wow', currentReactions),
                    _buildReactionOption(messageId, '😢', 'Sad', currentReactions),
                    _buildReactionOption(messageId, '😡', 'Angry', currentReactions),
                  ],
                ),

                const SizedBox(height: 16),

                if (userReaction != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _addReaction(messageId, userReaction);
                        Navigator.pop(context);
                      },
                      child: const Text('Remove Reaction'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionOption(String messageId, String emoji, String label,
      Map<String, dynamic> currentReactions) {
    final isSelected = currentReactions[_currentUserId] == emoji;

    return GestureDetector(
      onTap: () {
        _addReaction(messageId, emoji);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.green : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionSummary(Map<String, dynamic> reactions) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final reactionCounts = <String, int>{};
    reactions.forEach((userId, reaction) {
      reactionCounts[reaction] = (reactionCounts[reaction] ?? 0) + 1;
    });

    final sortedReactions = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 6,
        children: sortedReactions.take(3).map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key, style: const TextStyle(fontSize: 14)),
              if (entry.value > 1) ...[
                const SizedBox(width: 2),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : 'G',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_memberCount > 0)
                    Text(
                      '$_memberCount members',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isFileSelected)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 22),
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                  _isFileSelected = false;
                  _fileType = '';
                });
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFECE5DD),
      body: Column(
        children: [
          // Selected file preview
          if (_isFileSelected)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedFile!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.path.split('/').last,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ready to send',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedFile = null;
                        _isFileSelected = false;
                        _fileType = '';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('groups/${widget.groupId}/messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send a message to start the conversation',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!.docs;

                    // Auto-scroll to bottom for new messages
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_showScrollToBottom && _scrollController.hasClients) {
                        _scrollToBottom(animate: false);
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageDoc = messages[index];
                        final message = messageDoc.data() as Map<String, dynamic>;

                        // Group messages by date
                        bool showDateHeader = false;
                        if (index == 0 || _shouldShowDateHeader(messages, index)) {
                          showDateHeader = true;
                        }

                        return Column(
                          children: [
                            if (showDateHeader) _buildDateHeader(message['timestamp']),
                            _buildMessageBubble(messageDoc.id, message),
                          ],
                        );
                      },
                    );
                  },
                ),

                // Scroll to bottom button
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () => _scrollToBottom(),
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(List<DocumentSnapshot> messages, int index) {
    if (index == 0) return true;

    final currentMsg = messages[index].data() as Map<String, dynamic>;
    final previousMsg = messages[index - 1].data() as Map<String, dynamic>;

    final currentTimestamp = currentMsg['timestamp'] as Timestamp?;
    final previousTimestamp = previousMsg['timestamp'] as Timestamp?;

    if (currentTimestamp == null || previousTimestamp == null) return false;

    final currentDate = currentTimestamp.toDate();
    final previousDate = previousTimestamp.toDate();

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }

  Widget _buildDateHeader(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    String dateText;
    if (difference.inDays == 0) {
      dateText = 'Today';
    } else if (difference.inDays == 1) {
      dateText = 'Yesterday';
    } else if (difference.inDays < 7) {
      dateText = DateFormat('EEEE').format(date);
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String messageId, Map<String, dynamic> message) {
    final isCurrentUser = message['senderId'] == _currentUserId;
    final isDeleted = message['isDeleted'] == true;
    final senderName = message['senderName'] ?? 'Unknown User';
    final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});
    final hasText = message['text'] != null && message['text'].toString().isNotEmpty;
    final hasFile = message['fileUrl'] != null && !isDeleted;

    return GestureDetector(
      onLongPress: () {
        if (isCurrentUser && !isDeleted) {
          _showMessageOptions(messageId, reactions);
        } else {
          _showReactionDialog(messageId, reactions);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Other user's avatar
            if (!isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green,
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name (for other users)
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 12),
                      child: Text(
                        senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? const Color(0xFFDCF8C6) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isCurrentUser ? 12 : 2),
                        bottomRight: Radius.circular(isCurrentUser ? 2 : 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File content
                        if (hasFile)
                          _buildFileContent(message),

                        // Text content
                        if (hasText || isDeleted)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              hasFile ? 8 : 8,
                              12,
                              8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDeleted ? 'This message was deleted' : message['text'],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Only timestamp for images
                        if (hasFile && !hasText)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTimestamp(message['timestamp']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Reactions
                  if (reactions.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showReactionDialog(messageId, reactions),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: _buildReactionSummary(reactions),
                      ),
                    ),
                ],
              ),
            ),

            // Spacing for current user
            if (isCurrentUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(Map<String, dynamic> message) {
    final fileUrl = message['fileUrl'];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: CachedNetworkImage(
        imageUrl: fileUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(String messageId, Map<String, dynamic> reactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_emotions, color: Colors.orange, size: 20),
                ),
                title: const Text('React to message'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionDialog(messageId, reactions);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 20),
                ),
                title: const Text('Delete message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(messageId);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final hasContent = _messageController.text.isNotEmpty || _selectedFile != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach file button
          IconButton(
            icon: Icon(
              Icons.add_circle,
              color: Colors.green,
              size: 28,
            ),
            onPressed: _isSending ? null : _pickFile,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          const SizedBox(width: 8),

          // Message input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  enabled: !_isSending,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (hasContent && !_isSending) {
                    _sendMessage();
                  }
                },
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          _isSending
              ? Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.green,
            ),
          )
              : IconButton(
            icon: Icon(
              hasContent ? Icons.send : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
            onPressed: hasContent && !_isSending ? _sendMessage : null,
            style: IconButton.styleFrom(
              backgroundColor: hasContent ? Colors.green : Colors.grey,
              padding: const EdgeInsets.all(10),
              minimumSize: const Size(40, 40),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(date);
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }
}