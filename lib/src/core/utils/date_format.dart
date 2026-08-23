/// Minimal, dependency-free time formatter for message timestamps.
/// Deliberately avoids the `intl` package — one fewer dependency for
/// something this small (see SDK dependency policy).
String formatMessageTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour24 = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  var hour12 = hour24 % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:$minute $period';
}

/// `Today`, `Yesterday`, or a short date — used by date separators in the
/// message list.
String formatMessageDate(DateTime dateTime) {
  final now = DateTime.now();
  final local = dateTime.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(local.year, local.month, local.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
