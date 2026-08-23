import 'package:flutter/material.dart';

import '../../../model/chat_message.dart';
import '../../../theme/chat_colors.dart';
import '../../../theme/chat_theme.dart';
import '../chat_widget_action.dart';

/// Reference implementation of the SDK doc's "Date Invitation" card
/// (section 31). This is not part of the core rendering path — it's a
/// worked example showing how to consume [ChatMessage.metadata] and
/// [ChatWidgetActionGroup] to build your own custom message widgets.
/// Copy it into your app, or register it as-is via [ChatWidgetRegistry].
///
/// Expected `message.metadata` shape:
/// ```json
/// {
///   "customType": "date_invitation",
///   "title": "Date with GoldenHour",
///   "location": "Amber & Oak Cafe",
///   "time": "Tomorrow 4:00 PM",
///   "travelTime": "12 min"
/// }
/// ```
///
/// Registration:
/// ```dart
/// registry.register('date_invitation', (context, message, isMe) {
///   return DateInvitationCard(
///     message: message,
///     theme: myTheme,
///     onAccept: () => myController.respondToInvite(message.id, accepted: true),
///     onCancel: () => myController.respondToInvite(message.id, accepted: false),
///   );
/// });
/// ```
class DateInvitationCard extends StatelessWidget {
  final ChatMessage message;
  final ChatTheme theme;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const DateInvitationCard({
    super.key,
    required this.message,
    required this.theme,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    // metadata is untrusted remote data — never assume a field exists or
    // is the expected type (see doc section 15, message data validation).
    final data = message.metadata ?? const <String, dynamic>{};
    final title = data['title'] is String ? data['title'] as String : 'Invitation';
    final location = data['location'] is String ? data['location'] as String : null;
    final time = data['time'] is String ? data['time'] as String : null;
    final travelTime = data['travelTime'] is String ? data['travelTime'] as String : null;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.receiverBubble,
        borderRadius: BorderRadius.circular(theme.dimensions.messageBubbleRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.typography.messageText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.receiverText,
            ),
          ),
          const SizedBox(height: 12),
          if (location != null) _infoRow(Icons.place_outlined, 'Where', location, colors),
          if (time != null) _infoRow(Icons.calendar_today_outlined, 'When', time, colors),
          if (travelTime != null)
            _infoRow(Icons.directions_car_outlined, 'Getting There', '$travelTime · Directions available', colors),
          const SizedBox(height: 14),
          ChatWidgetActionGroup(
            theme: theme,
            actions: [
              ChatWidgetAction(
                id: 'accept',
                label: 'Accept Invitation',
                isPrimary: true,
                onPressed: onAccept,
              ),
              ChatWidgetAction(
                id: 'cancel',
                label: 'Cancel',
                onPressed: onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ChatColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.timestamp.copyWith(color: colors.hintText)),
                Text(value, style: theme.typography.messageText.copyWith(color: colors.receiverText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
