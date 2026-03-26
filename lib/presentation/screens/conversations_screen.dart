import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/specialist_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/specialist.dart';
import '../../domain/models/user.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

/// Conversations list screen showing all active chat threads
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessageRepositoryImpl _messageRepository = MessageRepositoryImpl();
  final SpecialistRepositoryImpl _specialistRepository = SpecialistRepositoryImpl();
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl();

  List<_ConversationItem> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    await _messageRepository.initialize();
    await _specialistRepository.initialize();
    await _authRepository.initialize();

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final isSpecialist = currentUser.role == UserRole.specialist;
    final items = <_ConversationItem>[];

    if (!isSpecialist) {
      // CURRENT USER IS A CLIENT
      // Load conversations where user_id = currentUser.id
      final rawConversations = await _messageRepository.getConversationsForUser(currentUser.id!);

      for (final conv in rawConversations) {
        final specialistId = conv['specialist_id'] as int;
        final specialist = await _specialistRepository.getSpecialistById(specialistId);
        if (specialist == null) continue;

        // Get the last message for preview
        final messages = await _messageRepository.getMessages(
          specialistId: specialistId, 
          userId: currentUser.id!,
        );
        final lastMessage = messages.isNotEmpty ? messages.last : null;

        final specialistUser = await _authRepository.getUserById(specialistId);

        items.add(_ConversationItem(
          contactName: specialist.name,
          contactRole: specialist.category,
          contactId: specialistId,
          isVerified: specialist.isVerified,
          targetUserId: currentUser.id!, // From client's perspective, the chat's userId is their own
          lastMessage: lastMessage?.content ?? '',
          lastMessageTime: lastMessage?.createdAt,
          unreadCount: (conv['unread_count'] as int?) ?? 0,
          isLastFromMe: lastMessage?.isFromClient ?? false,
          contactImageUrl: specialistUser?.profileImagePath,
        ));
      }
    } else {
      // CURRENT USER IS A SPECIALIST
      // 1. Get their specialistId
      final specialistId = await _specialistRepository.getSpecialistIdByUserId(currentUser.id!);
      
      if (specialistId != null) {
        // 2. Load conversations where specialist_id = this specialistId
        final rawConversations = await _messageRepository.getConversationsForSpecialist(specialistId);

        for (final conv in rawConversations) {
          final clientId = conv['user_id'] as int;
          final clientUser = await _authRepository.getUserById(clientId);
          if (clientUser == null) continue;

          // Get the last message for preview
          final messages = await _messageRepository.getMessages(
            specialistId: specialistId, 
            userId: clientId,
          );
          final lastMessage = messages.isNotEmpty ? messages.last : null;

          items.add(_ConversationItem(
            contactName: clientUser.name,
            contactRole: 'Client',
            contactId: specialistId,
            isVerified: false,
            targetUserId: clientId, // the actual user_id of the client they are chatting with
            lastMessage: lastMessage?.content ?? '',
            lastMessageTime: lastMessage?.createdAt,
            unreadCount: (conv['unread_count'] as int?) ?? 0,
            isLastFromMe: !(lastMessage?.isFromClient ?? true), // Specialist is NOT client
            contactImageUrl: clientUser.profileImagePath,
          ));
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _conversations = items;
      _isLoading = false;
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'now';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6B6B)]),
          ),
        ),
        title: Text('Messages', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
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
                        child: const Icon(Icons.forum_outlined, size: 48, color: Color(0xFFE53935)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.read<AuthProvider>().isSpecialist 
                            ? 'Your chats with clients will appear here'
                            : 'Open a specialist profile and tap Chat to start',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 76, color: Colors.grey.withValues(alpha: 0.2)),
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];

                    return Dismissible(
                      key: Key('conv_${conv.contactId}_${conv.targetUserId}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await _messageRepository.deleteConversation(
                          specialistId: conv.contactId,
                          userId: conv.targetUserId,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Conversation deleted')),
                          );
                          _loadConversations();
                        }
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                              backgroundImage: conv.contactImageUrl != null ? FileImage(File(conv.contactImageUrl!)) : null,
                              child: conv.contactImageUrl == null ? Text(
                                conv.contactName.isNotEmpty ? conv.contactName[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFE53935)),
                              ) : null,
                            ),
                            if (conv.isVerified)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.contactName,
                                style: GoogleFonts.inter(
                                  fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTime(conv.lastMessageTime),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: conv.unreadCount > 0 ? const Color(0xFFE53935) : Colors.grey[500],
                                fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            if (conv.isLastFromMe)
                              Icon(Icons.done_all, size: 16, color: Colors.grey[400]),
                            if (conv.isLastFromMe)
                              const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                conv.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: conv.unreadCount > 0
                                      ? (isDark ? Colors.white70 : const Color(0xFF475569))
                                      : Colors.grey[500],
                                  fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (conv.unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                specialistId: conv.contactId,
                                clientId: conv.targetUserId,
                              ),
                            ),
                          );
                          // Reload to update unread counts
                          _loadConversations();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class _ConversationItem {
  final String contactName;
  final String contactRole;
  final int contactId; // specialistId
  final int targetUserId; // clientId
  final bool isVerified;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isLastFromMe;
  final String? contactImageUrl;

  _ConversationItem({
    required this.contactName,
    required this.contactRole,
    required this.contactId,
    required this.targetUserId,
    required this.isVerified,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isLastFromMe,
    this.contactImageUrl,
  });
}
