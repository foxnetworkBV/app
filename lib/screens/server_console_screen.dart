import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
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
      final channel = IOWebSocketChannel.connect(
        Uri.parse(credentials.socket),
        headers: const {
          'Origin': ApiConfig.baseUrl,
          'User-Agent': 'FoxNetwork-Mobile-App',
        },
      );
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
                        return SelectableText.rich(
                          _ansiTextSpan(
                            _lines[index],
                            const TextStyle(
                            color: Color(0xFFE7ECEF),
                            fontFamily: 'monospace',
                            fontSize: 13,
                            ),
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

  TextSpan _ansiTextSpan(String value, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\x1B\[([0-9;]*)m');
    var currentStyle = baseStyle;
    var cursor = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start), style: currentStyle));
      }
      currentStyle = _applyAnsiCodes(currentStyle, baseStyle, match.group(1) ?? '0');
      cursor = match.end;
    }

    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor), style: currentStyle));
    }

    return TextSpan(style: baseStyle, children: spans.isEmpty ? [TextSpan(text: value, style: baseStyle)] : spans);
  }

  TextStyle _applyAnsiCodes(TextStyle currentStyle, TextStyle baseStyle, String value) {
    final codes = value.isEmpty ? <int>[0] : value.split(';').map((part) => int.tryParse(part) ?? 0).toList();
    var style = currentStyle;

    for (final code in codes) {
      if (code == 0) {
        style = baseStyle;
      } else if (code == 1) {
        style = style.copyWith(fontWeight: FontWeight.w700);
      } else if (code == 22) {
        style = style.copyWith(fontWeight: baseStyle.fontWeight);
      } else if (code == 39) {
        style = style.copyWith(color: baseStyle.color);
      } else if (code >= 30 && code <= 37) {
        style = style.copyWith(color: _ansiColor(code - 30, bright: false));
      } else if (code >= 90 && code <= 97) {
        style = style.copyWith(color: _ansiColor(code - 90, bright: true));
      }
    }

    return style;
  }

  Color _ansiColor(int value, {required bool bright}) {
    const normal = <Color>[
      Color(0xFF1F2328),
      Color(0xFFDC3545),
      Color(0xFF2EA043),
      Color(0xFFD29922),
      Color(0xFF58A6FF),
      Color(0xFFBC8CFF),
      Color(0xFF39C5CF),
      Color(0xFFE7ECEF),
    ];
    const brightColors = <Color>[
      Color(0xFF6E7681),
      Color(0xFFFF7B72),
      Color(0xFF7EE787),
      Color(0xFFFFD33D),
      Color(0xFF79C0FF),
      Color(0xFFD2A8FF),
      Color(0xFF56D4DD),
      Color(0xFFFFFFFF),
    ];
    return bright ? brightColors[value] : normal[value];
  }
}
