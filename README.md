# Flutterclaw

**OpenClaw-native Flutter chat client for Android**

A modern, Material 3 chat interface for connecting to your OpenClaw AI assistant via WebSocket.

## Features

- Real-time WebSocket communication with OpenClaw
- Material 3 design with dynamic theming
- Auto-reconnect with exponential backoff
- Message history with timestamps
- Connection status indicators
- Send/receive status tracking
- Dark/light mode support

## Architecture

```
lib/
├── models/              # Data models
│   ├── message.dart     # Chat message model
│   └── connection_state.dart  # Connection state model
├── services/            # Business logic
│   └── websocket_service.dart # WebSocket connection management
├── providers/           # State management
│   └── chat_provider.dart     # Chat state management
├── screens/             # UI screens
│   └── chat_screen.dart       # Main chat interface
├── widgets/             # Reusable widgets
│   ├── message_list.dart      # Scrollable message list
│   ├── message_bubble.dart    # Individual message bubble
│   ├── message_input.dart     # Text input field
│   └── connection_status_bar.dart  # Connection status indicator
├── utils/               # Utilities
└── main.dart            # App entry point
```

## Quick Start

1. Ensure OpenClaw gateway is running with WebSocket enabled
2. Update server URL in `lib/services/websocket_service.dart` if needed
3. Run `flutter pub get`
4. Build and install on Android device

## Configuration

Edit `lib/services/websocket_service.dart`:

```dart
static const String _defaultServerUrl = 'ws://YOUR_OPENCLAW_IP:8765';
```

## Dependencies

- `web_socket_channel` - WebSocket communication
- `provider` - State management
- `shared_preferences` - Local storage
- `uuid` - Message ID generation
- `intl` - Date/time formatting
- `flutter_markdown` - Message rendering
- `http` - HTTP requests
- `connectivity_plus` - Network monitoring

## License

MIT
