import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' as getx;

import 'no_socket/local_preview_screen.dart';
import 'state_bindings/bloc_binding_example.dart';
import 'state_bindings/getx_binding_example.dart';
import 'state_bindings/riverpod_binding_example.dart';
import 'with_socket/socket_chat_screen.dart';

void main() {
  // ProviderScope wraps the whole app so `RiverpodChatScreen` works
  // wherever it's pushed from — harmless to have present even for the
  // GetX/Bloc/local/socket examples, which don't use it at all.
  runApp(const ProviderScope(child: ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Using GetX's MaterialApp only so `GetxChatScreen` (which calls
    // `Get.put`) works when picked from the menu below — if you're not
    // using GetX in your own app, use a plain `MaterialApp` instead, as
    // the other three examples do without any issue.
    return getx.GetMaterialApp(
      title: 'advanced_chat_kit examples',
      home: const _ExamplePicker(),
    );
  }
}

class _ExamplePicker extends StatelessWidget {
  const _ExamplePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('advanced_chat_kit — examples')),
      body: ListView(
        children: [
          _tile(
            context,
            title: 'Local preview (no socket)',
            subtitle: 'Fully in-memory — good for quickly trying a theme or layout',
            builder: (_) => const LocalPreviewScreen(),
          ),
          _tile(
            context,
            title: 'With socket.io',
            subtitle: 'Real transport: connect, join room, send/receive/typing',
            builder: (_) => const SocketChatScreen(serverUrl: 'http://localhost:3000'),
          ),
          const Divider(),
          _tile(
            context,
            title: 'GetX binding',
            subtitle: 'ChatController.stream → .obs → Obx',
            builder: (_) => const GetxChatScreen(),
          ),
          _tile(
            context,
            title: 'Riverpod binding',
            subtitle: 'ChatController.stream → StreamProvider',
            builder: (_) => const RiverpodChatScreen(),
          ),
          _tile(
            context,
            title: 'Bloc / Cubit binding',
            subtitle: 'ChatController.stream → Cubit.emit',
            builder: (_) => const BlocChatScreen(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
    );
  }
}
