import 'package:flutter/material.dart';

class MessageTick extends StatelessWidget {
  final bool read;
  final bool delivered;

  const MessageTick({
    super.key,
    required this.read,
    required this.delivered,
  });

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // READ
    // Double blue tick
    // ============================================================

    if (read) {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.blue,
      );
    }

    // ============================================================
    // DELIVERED
    // Double grey tick
    // ============================================================

    if (delivered) {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.grey,
      );
    }

    // ============================================================
    // SENT
    // Single grey tick
    // ============================================================

    return const Icon(
      Icons.done,
      size: 15,
      color: Colors.grey,
    );
  }
}