import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/models/message.dart';
import '../../domain/models/specialist.dart';
import '../../domain/models/user.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../providers/auth_provider.dart';

/// Chat screen for messaging handling both Client and Specialist perspectives
class ChatScreen extends StatefulWidget {
  final int specialistId;
  final int? clientId; // The target client's user_id. If null, assumes currentUser is the client.

  const ChatScreen({
    super.key, 
    required this.specialistId,
    this.clientId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageRepositoryImpl _messageRepository = MessageRepositoryImpl();
  final SpecialistRepositoryImpl _specialistRepository = SpecialistRepositoryImpl();
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Specialist? _specialist;
  User? _clientUser;
  List<Message> _messages = [];
  bool _isLoading = true;
  
  late bool _isCurrentUserClient;
  late int _effectiveClientId;
  late String _otherPartyName;
  late String _otherPartySubtitle;
  String? _otherPartyImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _messageRepository.initialize();
    await _specialistRepository.initialize();
    await _authRepository.initialize();

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;
    
    _isCurrentUserClient = currentUser.role == UserRole.client;
    
    // Determine the Client ID for this conversation strand
    _effectiveClientId = widget.clientId ?? currentUser.id!;

    // Load definitions
    final specialist = await _specialistRepository.getSpecialistById(widget.specialistId);
    final clientUser = await _authRepository.getUserById(_effectiveClientId);
    
    if (specialist == null) return;

    // Set UI labels
    if (_isCurrentUserClient) {
      _otherPartyName = specialist.name;
      _otherPartySubtitle = specialist.category;
      // Get the User for specialist to map avatar
      final specialistUser = await _authRepository.getUserById(specialist.id!);
      _otherPartyImageUrl = specialistUser?.profileImagePath;
    } else {
      _otherPartyName = clientUser?.name ?? 'Client';
      _otherPartySubtitle = 'Client';
      _otherPartyImageUrl = clientUser?.profileImagePath;
    }
    
    // Load messages
    final messages = await _messageRepository.getMessages(
      specialistId: widget.specialistId,
      userId: _effectiveClientId,
    );
    
    // Mark messages as read based on who is viewing
    await _messageRepository.markAsRead(
      specialistId: widget.specialistId, 
      userId: _effectiveClientId, 
      isReadingByClient: _isCurrentUserClient
    );

    if (!mounted) return;
    setState(() {
      _specialist = specialist;
      _clientUser = clientUser;
      _messages = messages;
      _isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final isFirstMessage = _messages.isEmpty;

    final message = Message(
      specialistId: widget.specialistId,
      userId: _effectiveClientId,
      senderName: currentUser.name,
      isFromClient: _isCurrentUserClient,
      content: text,
      createdAt: DateTime.now(),
    );

    await _messageRepository.insertMessage(message);
    _messageController.clear();

    // Reload messages
    final messages = await _messageRepository.getMessages(
      specialistId: widget.specialistId,
      userId: _effectiveClientId,
    );
    
    if (!mounted) return;
    setState(() {
      _messages = messages;
    });

    _scrollToBottom();

    // If client is sending their first message, simulate a specialist response for demo
    if (_isCurrentUserClient && isFirstMessage) {
      _simulateSpecialistResponse();
    }
  }

  Future<void> _simulateSpecialistResponse() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final responses = [
      'Thank you for your message! I will get back to you soon.',
      'I understand your request. Let me check my availability.',
      'Thanks for reaching out! I\'d be happy to help with that.',
      'I received your message. I\'ll respond with more details shortly.',
    ];
    final response = responses[DateTime.now().millisecond % responses.length];

    final message = Message(
      specialistId: widget.specialistId,
      userId: _effectiveClientId,
      senderName: _specialist?.name ?? 'Specialist',
      isFromClient: false,
      content: response,
      createdAt: DateTime.now(),
    );

    await _messageRepository.insertMessage(message);

    final messages = await _messageRepository.getMessages(
      specialistId: widget.specialistId,
      userId: _effectiveClientId,
    );
    
    if (mounted) {
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
            ),
          ),
          title: Text('Chat', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: _otherPartyImageUrl != null ? FileImage(File(_otherPartyImageUrl!)) : null,
              child: _otherPartyImageUrl == null ? Text(
                _otherPartyName.isNotEmpty ? _otherPartyName[0].toUpperCase() : '?',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _otherPartyName,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isCurrentUserClient && (_specialist?.isVerified ?? false)) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                  Text(
                    _otherPartySubtitle,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFE53935)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Send a message to $_otherPartyName',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    // If I'm the client and message is from client, it's me.
    // If I'm the specialist and message is NOT from client, it's me.
    final isMe = _isCurrentUserClient ? message.isFromClient : !message.isFromClient;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
              child: Text(
                _otherPartyName.isNotEmpty ? _otherPartyName[0].toUpperCase() : '?',
                style: const TextStyle(color: Color(0xFFE53935), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFFE53935)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(message.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF64748B).withValues(alpha: 0.15),
              child: Text(
                context.read<AuthProvider>().currentUser?.name[0].toUpperCase() ?? 'M',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
