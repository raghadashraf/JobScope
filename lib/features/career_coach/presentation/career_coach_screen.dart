import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../data/career_coach_providers.dart';

class CareerCoachScreen extends ConsumerStatefulWidget {
  const CareerCoachScreen({super.key});

  @override
  ConsumerState<CareerCoachScreen> createState() => _CareerCoachScreenState();
}

class _CareerCoachScreenState extends ConsumerState<CareerCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.clear();
    await ref.read(coachChatNotifierProvider.notifier).send(trimmed);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachChatStreamProvider);
    final isLoading = ref.watch(coachChatNotifierProvider);

    ref.listen(coachChatStreamProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Error loading chat',
                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              data: (messages) => messages.isEmpty
                  ? _EmptyState(onStarter: _send)
                  : _MessageList(
                      messages: messages,
                      isLoading: isLoading,
                      scrollController: _scrollController,
                      onStarter: _send,
                    ),
            ),
          ),
          _InputBar(
            controller: _controller,
            isLoading: isLoading,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Career Coach',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Powered by Gemini',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              color: AppColors.textTertiary, size: 20),
          tooltip: 'Clear history',
          onPressed: () => _showClearDialog(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear conversation?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete your chat history with the coach.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(coachChatNotifierProvider.notifier).clearHistory();
            },
            child: Text('Clear',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state with starter questions ───────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Future<void> Function(String) onStarter;
  const _EmptyState({required this.onStarter});

  static const _starters = [
    'Why am I not getting callbacks?',
    'How do I improve my CV?',
    'What salary should I ask for?',
    'Why is my match score low?',
    'What skills should I learn next?',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      children: [
        Container(
          width: 72,
          height: 72,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 32),
        ),
        Text(
          'Your AI Career Coach',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask anything about your job search. I have full context of your CV, skills, and applications.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Try asking',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._starters.map((q) => _StarterChip(question: q, onTap: onStarter)),
      ],
    );
  }
}

class _StarterChip extends StatelessWidget {
  final String question;
  final Future<void> Function(String) onTap;
  const _StarterChip({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => onTap(question),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final ScrollController scrollController;
  final Future<void> Function(String) onStarter;

  const _MessageList({
    required this.messages,
    required this.isLoading,
    required this.scrollController,
    required this.onStarter,
  });

  static const _starters = [
    'Why am I not getting callbacks?',
    'What skills should I learn next?',
    'How can I improve my profile?',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length + (isLoading ? 1 : 0) + 1,
      itemBuilder: (_, i) {
        // First item: collapsed starter chips
        if (i == 0) {
          return _CollapsedStarters(starters: _starters, onTap: onStarter);
        }
        final msgIndex = i - 1;
        if (isLoading && msgIndex == messages.length) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: messages[msgIndex]);
      },
    );
  }
}

class _CollapsedStarters extends StatelessWidget {
  final List<String> starters;
  final Future<void> Function(String) onTap;
  const _CollapsedStarters({required this.starters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: starters
            .map((q) => ActionChip(
                  label: Text(q,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.primary)),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                  onPressed: () => onTap(q),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _CoachAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.primaryGradient : null,
                    color: isUser ? null : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isUser
                          ? Colors.white
                          : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 14),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CoachAvatar(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(ctrl: _ctrl, index: i)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController ctrl;
  final int index;
  const _Dot({required this.ctrl, required this.index});

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.2;
    final anim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeInOut),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3 + anim.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask your career coach…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              onSubmitted: isLoading ? null : onSend,
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(isLoading: isLoading, onTap: () => onSend(controller.text)),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _SendButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: isLoading ? null : AppColors.primaryGradient,
          color: isLoading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(13),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
