// Chat detail page (not ChatListPage)
import 'dart:ui';

import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<_Msg> _messages = <_Msg>[
    _Msg(text: 'Halo! 👋', isMe: false, time: const TimeOfDay(hour: 9, minute: 12)),
    _Msg(text: 'Selamat datang di chat.', isMe: false, time: const TimeOfDay(hour: 9, minute: 12)),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final txt = _textCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: txt, isMe: true, time: TimeOfDay.now()));
      _textCtrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
    // Tunda unfocus agar tidak flicker saat layout berubah
    Future.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leadingWidth: 24,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('lib/app/assets/images/cvm.png'),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CVM Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.videocam, color: Colors.white)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.call, color: Colors.white)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.more_vert, color: Colors.white)),
          SizedBox(width: 4),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.25), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final prevIsMe = index > 0 ? _messages[index - 1].isMe : null;
                      final nextIsMe = index < _messages.length - 1 ? _messages[index + 1].isMe : null;
                      return _Bubble(
                        msg: m,
                        startGroup: prevIsMe == null || prevIsMe != m.isMe,
                        endGroup: nextIsMe == null || nextIsMe != m.isMe,
                      );
                    },
                  ),
                ),
                _Composer(controller: _textCtrl, onSend: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Ketik pesan',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              if (controller.text.trim().isNotEmpty) {
                                onSend();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasText = value.text.trim().isNotEmpty;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: IconButton(
                              icon: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white),
                              onPressed: hasText
                                  ? () {
                                      onSend(); // unfocus ditangani di _send()
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, this.startGroup = true, this.endGroup = true});
  final _Msg msg;
  final bool startGroup;
  final bool endGroup;

  @override
  Widget build(BuildContext context) {
    final align = msg.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = msg.isMe ? Colors.white.withOpacity(0.85) : Colors.white.withOpacity(0.92);

    final br = BorderRadius.only(
      topLeft: Radius.circular(msg.isMe ? 16 : (startGroup ? 16 : 6)),
      topRight: Radius.circular(msg.isMe ? (startGroup ? 16 : 6) : 16),
      bottomLeft: Radius.circular(msg.isMe ? 16 : (endGroup ? 2 : 6)),
      bottomRight: Radius.circular(msg.isMe ? (endGroup ? 2 : 6) : 16),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: EdgeInsets.only(
            left: msg.isMe ? 64 : 8,
            right: msg.isMe ? 8 : 64,
            top: startGroup ? 6 : 2,
            bottom: endGroup ? 6 : 2,
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: br,
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  msg.text,
                  style: const TextStyle(fontSize: 15, height: 1.25),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _fmtTime(msg.time),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (msg.isMe) ...[
                const SizedBox(width: 2),
                const Icon(Icons.done_all, size: 16, color: Color(0xFF34B7F1)), // read ticks
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Msg {
  final String text;
  final bool isMe;
  final TimeOfDay time;
  _Msg({required this.text, required this.isMe, required this.time});
}