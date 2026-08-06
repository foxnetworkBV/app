import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';
import '../services/session_service.dart';

class ServerConsoleScreen extends StatefulWidget {
  final CustomerService service;
  final SessionService session;

  const ServerConsoleScreen({
    super.key,
    required this.service,
    required this.session,
  });

  @override
  State<ServerConsoleScreen> createState() => _ServerConsoleScreenState();
}

class _ServerConsoleScreenState extends State<ServerConsoleScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _lines = <String>[];
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _connecting = true;
  bool _authenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _authenticated = false;
      _error = null;
      _lines.clear();
    });

    try {
      final credentials = await widget.session.getConsoleCredentials(widget.service.id);
      final channel = WebSocketChannel.connect(Uri.parse(credentials.socket));
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (Object error) => _showError(error.toString()),
        onDone: () {
          if (mounted && _error == null) {
            setState(() => _error = 'Console connection closed.');
          }
        },
      );
      _sendEvent('auth', <String>[credentials.token]);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message.toString());
    if (decoded is! Map<String, dynamic>) return;
    final event = (decoded['event'] ?? '').toString();
    final args = decoded['args'] is List<dynamic> ? decoded['args'] as List<dynamic> : <dynamic>[];

    if (event == 'auth success') {
      setState(() => _authenticated = true);
      _sendEvent('send logs', const <String>[]);
      return;
    }

    if (event == 'console output' && args.isNotEmpty) {
      _append(args.first.toString());
    } else if (event == 'status' && args.isNotEmpty) {
      _append('[status] ${args.first}');
    } else if (event == 'daemon message' && args.isNotEmpty) {
      _append('[daemon] ${args.first}');
    } else if (event == 'token expiring' || event == 'token expired') {
      _append('[console] Reconnecting...');
      _subscription?.cancel();
      _channel?.sink.close();
      _connect();
    }
  }

  void _append(String value) {
    setState(() => _lines.add(value));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _sendCommand() {
    final command = _commandController.text.trim();
    if (command.isEmpty || !_authenticated) return;
    _sendEvent('send command', <String>[command]);
    _append('> $command');
    _commandController.clear();
  }

  void _sendEvent(String event, List<String> args) {
    _channel?.sink.add(jsonEncode(<String, dynamic>{'event': event, 'args': args}));
  }

  void _showError(String value) {
    if (!mounted) return;
    setState(() {
      _error = value;
      _connecting = false;
      _authenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Console'),
        actions: [
          IconButton(
            onPressed: _connecting ? null : _connect,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF101214),
              padding: const EdgeInsets.all(14),
              child: _connecting && _lines.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _lines.length + (_error == null ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (_error != null && index == _lines.length) {
                          return Text(
                            _error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          );
                        }
                        return SelectableText(
                          _lines[index],
                          style: const TextStyle(
                            color: Color(0xFFE7ECEF),
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commandController,
                      enabled: _authenticated,
                      decoration: const InputDecoration(
                        hintText: 'Command',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendCommand(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _authenticated ? _sendCommand : null,
                    icon: const Icon(Icons.keyboard_return_rounded),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
