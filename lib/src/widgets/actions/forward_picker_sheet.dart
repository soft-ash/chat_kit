import 'package:flutter/material.dart';

import '../../theme/chat_theme.dart';
import 'forward_target.dart';

/// Opens a searchable, multi-select bottom sheet of [targets] and
/// resolves with the ids the person picked — an empty list if they
/// cancel without selecting anyone.
///
/// This only handles the *picking UI*. Actually forwarding — building a
/// [ForwardedMessage] reference and persisting it against each selected
/// conversation — stays entirely in the host app's hands (see doc
/// section 3: "the backend can then decide how the forwarded message is
/// persisted").
///
/// ```dart
/// final ids = await showForwardPickerSheet(context, targets: myContacts, theme: theme);
/// for (final id in ids) {
///   myApi.forwardMessage(message.id, toConversationId: id);
/// }
/// ```
Future<List<String>> showForwardPickerSheet(
  BuildContext context, {
  required List<ChatForwardTarget> targets,
  required ChatTheme theme,
}) async {
  final result = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.colors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => _ForwardPickerContent(targets: targets, theme: theme),
  );
  return result ?? const [];
}

class _ForwardPickerContent extends StatefulWidget {
  final List<ChatForwardTarget> targets;
  final ChatTheme theme;

  const _ForwardPickerContent({required this.targets, required this.theme});

  @override
  State<_ForwardPickerContent> createState() => _ForwardPickerContentState();
}

class _ForwardPickerContentState extends State<_ForwardPickerContent> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    final filtered = widget.targets.where((t) => t.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Forward to',
                      style: widget.theme.typography.senderName.copyWith(fontSize: 16, color: colors.receiverText),
                    ),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final target = filtered[index];
                  final isSelected = _selected.contains(target.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => setState(() {
                      isSelected ? _selected.remove(target.id) : _selected.add(target.id);
                    }),
                    secondary: CircleAvatar(
                      backgroundImage: target.avatarUrl != null ? NetworkImage(target.avatarUrl!) : null,
                      child: target.avatarUrl == null
                          ? Text(target.name.isNotEmpty ? target.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(target.name),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
