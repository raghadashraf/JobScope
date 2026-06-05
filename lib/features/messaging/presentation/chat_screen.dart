import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/direct_message_model.dart';
import '../../auth/data/auth_providers.dart';
import '../data/messaging_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ChatParams params;

  const ChatScreen({super.key, required this.params});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUid = ref.read(firebaseUserProvider).value?.uid;
      if (myUid != null) {
        ref
            .read(messagingNotifierProvider.notifier)
            .markRead(widget.params.convId, myUid);
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final me = ref.read(currentUserProvider).value;
    if (me == null) return;

    _inputCtrl.clear();
    setState(() => _isSending = true);

    try {
      await ref.read(messagingNotifierProvider.notifier).sendMessage(
            convId: widget.params.convId,
            senderId: me.uid,
            senderName: me.name,
            recipientId: widget.params.otherUid,
            text: text,
            participantNames: {
              me.uid: me.name,
              widget.params.otherUid: widget.params.otherName,
            },
            jobTitle: widget.params.jobTitle,
            applicationId: widget.params.applicationId,
          );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(firebaseUserProvider).value?.uid ?? '';
    final messagesAsync =
        ref.watch(messagesProvider(widget.params.convId));

    // Auto-scroll when new messages arrive
    ref.listen(messagesProvider(widget.params.convId), (_, next) {
      if (next.hasValue) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                widget.params.otherName.isNotEmpty
                    ? widget.params.otherName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.params.otherName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.params.jobTitle != null)
                    Text(
                      widget.params.jobTitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'Say hello!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == myUid;
                    final showDate = i == 0 ||
                        !_sameDay(
                            messages[i - 1].sentAt, msg.sentAt);
                    final showReadReceipt = isMe &&
                        i == messages.length - 1 &&
                        msg.isRead;
                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.sentAt),
                        _Bubble(
                          msg: msg,
                          isMe: isMe,
                          showReadReceipt: showReadReceipt,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.error)),
              ),
            ),
          ),

          // Input bar
          _InputBar(
            controller: _inputCtrl,
            isSending: _isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Bubble ────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final DirectMessageModel msg;
  final bool isMe;
  final bool showReadReceipt;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.showReadReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      AppColors.surfaceVariant,
                  child: Text(
                    msg.senderName.isNotEmpty
                        ? msg.senderName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isMe ? 18 : 4),
                      bottomRight:
                          Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color:
                          isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Text(
                  DateFormat('h:mm a').format(msg.sentAt),
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
          if (!isMe) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                DateFormat('h:mm a').format(msg.sentAt),
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textTertiary),
              ),
            ),
          ],
          if (showReadReceipt)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.done_all_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    'Seen',
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── Date divider ──────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    final label = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: isSending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSending
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
