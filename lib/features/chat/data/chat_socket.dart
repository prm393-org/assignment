import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:chuoi_xanh_viet/core/config/api_config.dart';

typedef ChatSocketMessageHandler = void Function(dynamic data);

class ChatSocket {
  io.Socket? _socket;
  ChatSocketMessageHandler? _messageHandler;
  String? _joinedConversationId;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String accessToken) {
    if (_socket != null && _socket!.connected && _token == accessToken) {
      return;
    }
    disconnect();
    _token = accessToken;
    _socket = io.io(
      ApiConfig.apiHost,
      io.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': accessToken})
          .enableReconnection()
          .build(),
    );
    if (_messageHandler != null) {
      _socket!.on('chat:message', _messageHandler!);
    }
    _socket!.onConnect((_) => _rejoinIfNeeded());
    _socket!.onReconnect((_) => _rejoinIfNeeded());
    _socket!.connect();
  }

  void _rejoinIfNeeded() {
    final id = _joinedConversationId;
    if (id == null || id.isEmpty) return;
    _emitJoin(id);
  }

  void _emitJoin(String conversationId) {
    _socket?.emit('chat:join', {
      'conversationId': conversationId,
      'conversation_id': conversationId,
    });
  }

  void disconnect() {
    final id = _joinedConversationId;
    if (id != null) {
      leave(id);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
  }

  void join(String conversationId) {
    _joinedConversationId = conversationId;
    if (_socket?.connected == true) {
      _emitJoin(conversationId);
    }
    // If not connected yet, onConnect / onReconnect will emit join.
  }

  void leave(String conversationId) {
    _socket?.emit('chat:leave', {
      'conversationId': conversationId,
      'conversation_id': conversationId,
    });
    if (_joinedConversationId == conversationId) {
      _joinedConversationId = null;
    }
  }

  void onMessage(ChatSocketMessageHandler handler) {
    _messageHandler = handler;
    _socket?.off('chat:message');
    _socket?.on('chat:message', handler);
  }

  void offMessage() {
    _socket?.off('chat:message');
    _messageHandler = null;
  }
}
