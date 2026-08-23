import '../../model/chat_message.dart';

/// Whether a message sits at the start/end of a visual run of consecutive
/// messages from the same sender — used to decide which bubble corners
/// stay rounded vs. go "tight", and whether to show avatar/sender name.
class MessageGroupInfo {
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const MessageGroupInfo({
    required this.isFirstInGroup,
    required this.isLastInGroup,
  });
}

/// [messagesOldestFirst] must be ordered oldest → newest (this is exactly
/// how [ChatState.messages] is maintained by [ChatController]). A group
/// breaks when the sender changes, or when the gap between two messages
/// from the same sender exceeds [groupingWindow].
MessageGroupInfo resolveGroupInfo(
  List<ChatMessage> messagesOldestFirst,
  int index, {
  Duration groupingWindow = const Duration(minutes: 3),
}) {
  final current = messagesOldestFirst[index];
  final prev = index > 0 ? messagesOldestFirst[index - 1] : null;
  final next = index < messagesOldestFirst.length - 1 ? messagesOldestFirst[index + 1] : null;

  final isFirst = prev == null ||
      prev.senderId != current.senderId ||
      current.createdAt.difference(prev.createdAt) > groupingWindow;

  final isLast = next == null ||
      next.senderId != current.senderId ||
      next.createdAt.difference(current.createdAt) > groupingWindow;

  return MessageGroupInfo(isFirstInGroup: isFirst, isLastInGroup: isLast);
}
