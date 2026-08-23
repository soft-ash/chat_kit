/// The kind of conversation a [ChatController] is driving.
enum ChatType {
  single,
  group,
  ai,
}

/// The type of a single message's payload.
///
/// [custom] is the escape hatch: any application-specific message
/// (date invitation cards, product cards, payment cards, polls, etc.)
/// is represented as `custom` with a `customType` string + metadata map,
/// and rendered by the host app's `customMessageBuilder`. The package
/// never needs to know what a custom type means — see SDK doc section 16
/// (remote data stays declarative, never executable).
enum ChatMessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  contact,
  system,
  custom,
}

/// Delivery lifecycle of an outgoing/incoming message.
enum ChatMessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Where a [ChatLayer] widget is mounted relative to the core chat screen.
enum ChatLayerPosition {
  aboveHeader,
  belowHeader,
  aboveMessages,
  belowMessages,
  aboveInput,
  belowInput,
  overlay,
}

/// Type of an outgoing/incoming call action requested from the chat UI.
/// The package only surfaces the *intent*; the host app owns WebRTC/Agora/etc.
enum ChatCallType {
  audio,
  video,
}

/// Connectivity/sending state surfaced by the host app into the controller.
enum ChatConnectionState {
  online,
  connecting,
  offline,
}
