enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionInfo {
  final ConnectionState state;
  final String? serverUrl;
  final String? errorMessage;
  final int reconnectAttempts;
  final DateTime? lastConnectedAt;

  const ConnectionInfo({
    this.state = ConnectionState.disconnected,
    this.serverUrl,
    this.errorMessage,
    this.reconnectAttempts = 0,
    this.lastConnectedAt,
  });

  ConnectionInfo copyWith({
    ConnectionState? state,
    String? serverUrl,
    String? errorMessage,
    int? reconnectAttempts,
    DateTime? lastConnectedAt,
  }) {
    return ConnectionInfo(
      state: state ?? this.state,
      serverUrl: serverUrl ?? this.serverUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  bool get isConnected => state == ConnectionState.connected;
  bool get isConnecting => state == ConnectionState.connecting;
  bool get isReconnecting => state == ConnectionState.reconnecting;
}
