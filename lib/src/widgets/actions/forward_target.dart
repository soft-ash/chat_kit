/// A destination the person can forward a message to — a contact, a
/// group, a "saved messages" shortcut, whatever the host app's data
/// model looks like. The package never fetches this list itself (contacts
/// and conversations are the host app's data — see doc section 3); you
/// supply it to [showForwardPickerSheet].
class ChatForwardTarget {
  final String id;
  final String name;
  final String? avatarUrl;

  const ChatForwardTarget({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}
