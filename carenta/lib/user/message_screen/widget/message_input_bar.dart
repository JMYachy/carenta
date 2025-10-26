import 'package:flutter/material.dart';

class MessageInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {
      _canSend = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: widget.controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_canSend) widget.onSend();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _canSend ? widget.onSend : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _canSend ? const Color(0xFFFF5722) : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
